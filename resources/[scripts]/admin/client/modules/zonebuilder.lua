local mode = 'off'
local points = {}
local attackHeld = false
local aimHeld = false
local lastUndo = 0
local WALL_HEIGHT = 9.0

local center = nil
local radius = 50.0
local height = 20.0
local growHeld = false
local shrinkHeld = false
local lastHeightAdj = 0

local SZ_DICT = 'safezone'
local SZ_TEX = 'kingg_safezone'
local szTexLoaded = false

local function requestSz()
    if not szTexLoaded then RequestStreamedTextureDict(SZ_DICT, true) end
end

local function releaseSz()
    if szTexLoaded then
        SetStreamedTextureDictAsNoLongerNeeded(SZ_DICT)
        szTexLoaded = false
    end
end

---@return vector3
local function camDir()
    local rot = GetGameplayCamRot(2)
    local rx = math.rad(rot.x)
    local rz = math.rad(rot.z)
    local cx = math.cos(rx)
    return vector3(-math.sin(rz) * cx, math.cos(rz) * cx, math.sin(rx))
end

---@return vector3|nil
local function aimGround()
    local cam = GetGameplayCamCoord()
    local dest = cam + camDir() * 1000.0
    local handle = StartExpensiveSynchronousShapeTestLosProbe(cam.x, cam.y, cam.z, dest.x, dest.y, dest.z, 1, PlayerPedId(), 4)
    local _, hit, coords = GetShapeTestResult(handle)
    if hit == 1 or hit == true then return coords end
    return nil
end

local function drawWall(a, b)
    local r, g, bl, al = 0, 200, 255, 90
    local z1t, z2t = a.z + WALL_HEIGHT, b.z + WALL_HEIGHT
    DrawPoly(a.x, a.y, a.z, b.x, b.y, b.z, b.x, b.y, z2t, r, g, bl, al)
    DrawPoly(b.x, b.y, z2t, b.x, b.y, b.z, a.x, a.y, a.z, r, g, bl, al)
    DrawPoly(a.x, a.y, a.z, b.x, b.y, z2t, a.x, a.y, z1t, r, g, bl, al)
    DrawPoly(a.x, a.y, z1t, b.x, b.y, z2t, a.x, a.y, a.z, r, g, bl, al)
end

local function finishBuilder()
    if mode == 'poly' then
        mode = 'off'
        local out = {}
        for i = 1, #points do
            local p = points[i]
            out[i] = { x = p.x + 0.0, y = p.y + 0.0, z = p.z + 0.0 }
        end
        Admin:openNui('openZonePoints', { points = out })
        TriggerEvent('Notify', 'success', ('Zona finalizada com %d ponto(s).'):format(#out), 5)
    elseif mode == 'radius' then
        if not center then
            TriggerEvent('Notify', 'error', 'Posicione o centro antes de finalizar.', 4)
            return
        end
        mode = 'off'
        releaseSz()
        Admin:openNui('openZonePoints', {
            center = { x = center.x + 0.0, y = center.y + 0.0, z = center.z + 0.0 },
            radius = radius + 0.0,
            height = height + 0.0,
        })
        TriggerEvent('Notify', 'success', ('Zona radius finalizada (raio %.1fm).'):format(radius), 5)
    end
end

local function builderLoop()
    while mode == 'poly' do
        local gp = aimGround()

        for i = 1, #points do
            local p = points[i]
            local nxt = points[i + 1]
            if nxt then
                drawWall(p, nxt)
                DrawLine(p.x, p.y, p.z, nxt.x, nxt.y, nxt.z, 255, 230, 0, 255)
            end
            DrawMarker(28, p.x, p.y, p.z, 0, 0, 0, 0, 0, 0, 0.35, 0.35, 0.35, 255, 230, 0, 200, false, false, 2, false, nil, nil, false)
        end

        if gp then
            DrawMarker(1, gp.x, gp.y, gp.z - 0.98, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 0, 255, 140, 140, false, true, 2, false, nil, nil, false)
            DrawMarker(0, gp.x, gp.y, gp.z + 1.5, 0, 0, 0, 180.0, 0, 0, 0.6, 0.6, 0.6, 0, 255, 140, 220, false, true, 2, false, nil, nil, false)
        end

        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 257, true)
        DisableControlAction(0, 140, true)

        local attackDown = IsDisabledControlPressed(0, 24)
        if attackDown and not attackHeld and gp then
            points[#points + 1] = gp
        end
        attackHeld = attackDown

        local aimDown = IsDisabledControlPressed(0, 25)
        if aimDown and not aimHeld and #points > 0 and (GetGameTimer() - lastUndo) > 300 then
            points[#points] = nil
            lastUndo = GetGameTimer()
        end
        aimHeld = aimDown

        drawTxt('CRIAR ZONA (POLYZONE)  |  Pontos: ' .. #points, 4, 0.5, 0.82, 0.5, 255, 255, 255, 220)
        drawTxt('~g~Click Esq~w~ adicionar    ~r~Click Dir~w~ desfazer    ~b~Enter~w~ finalizar    ~o~Backspace~w~ cancelar', 4, 0.5, 0.86, 0.4, 255, 255, 255, 180)

        Wait(0)
    end
end

local function radiusLoop()
    requestSz()
    while mode == 'radius' do
        if not szTexLoaded and HasStreamedTextureDictLoaded(SZ_DICT) then szTexLoaded = true end

        local gp = aimGround()
        local c = center or gp

        if (growHeld or shrinkHeld) and (GetGameTimer() - lastHeightAdj) >= 75 then
            lastHeightAdj = GetGameTimer()
            if growHeld then height = math.min(1000.0, height + 1.0) end
            if shrinkHeld then height = math.max(1.0, height - 1.0) end
        end

        if c then
            local size = radius
            if szTexLoaded then
                DrawMarker(28, c.x, c.y, c.z - 1.0, 0, 0, 0, 0, 0, 0, size, size, height, 40, 130, 255, 150, false, false, 2, false, SZ_DICT, SZ_TEX, false)
            else
                DrawMarker(28, c.x, c.y, c.z - 1.0, 0, 0, 0, 0, 0, 0, size, size, height, 40, 130, 255, 150, false, false, 2, false, nil, nil, false)
            end
            DrawMarker(28, c.x, c.y, c.z, 0, 0, 0, 0, 0, 0, 0.4, 0.4, 0.4, 255, 230, 0, 220, false, false, 2, false, nil, nil, false)
        end

        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 257, true)
        DisableControlAction(0, 14, true)
        DisableControlAction(0, 15, true)
        DisableControlAction(0, 140, true)

        local attackDown = IsDisabledControlPressed(0, 24)
        if attackDown and not attackHeld and gp then
            center = gp
        end
        attackHeld = attackDown

        if IsDisabledControlJustPressed(0, 15) then radius = math.min(500.0, radius + 1.0) end
        if IsDisabledControlJustPressed(0, 14) then radius = math.max(1.0, radius - 1.0) end

        drawTxt(('CRIAR ZONA (RADIUS)  |  Raio: %.1fm  |  Altura: %.0fm'):format(radius, height), 4, 0.5, 0.82, 0.5, 255, 255, 255, 220)
        if center then
            drawTxt('~g~Click Esq~w~ mover centro    ~b~Scroll~w~ tamanho    ~b~+/-~w~ altura    ~b~Enter~w~ finalizar    ~o~Backspace~w~ cancelar', 4, 0.5, 0.86, 0.4, 255, 255, 255, 180)
        else
            drawTxt('~y~Mire no chão e ~g~Click Esq~y~ pra posicionar o centro    ~o~Backspace~w~ cancelar', 4, 0.5, 0.86, 0.4, 255, 255, 255, 180)
        end

        Wait(0)
    end
end

local function chooseLoop()
    while mode == 'choose' do
        DisableControlAction(0, 157, true)
        DisableControlAction(0, 158, true)

        drawTxt('CRIAR ZONA — escolha o tipo', 4, 0.5, 0.80, 0.6, 255, 255, 255, 230)
        drawTxt('~b~[1]~w~ PolyZone       ~b~[2]~w~ Radius       ~o~Backspace~w~ cancelar', 4, 0.5, 0.85, 0.45, 255, 255, 255, 190)

        if IsDisabledControlJustPressed(0, 157) then
            points = {}
            attackHeld = true
            aimHeld = true
            mode = 'poly'
            CreateThread(builderLoop)
            TriggerEvent('Notify', 'success', 'PolyZone: mire no chão e clique pra criar os pontos.', 6)
        elseif IsDisabledControlJustPressed(0, 158) then
            center = nil
            radius = 50.0
            height = 20.0
            attackHeld = true
            mode = 'radius'
            CreateThread(radiusLoop)
            TriggerEvent('Notify', 'success', 'Radius: clique pra posicionar o centro. Scroll ou +/- ajusta o tamanho.', 7)
        end

        Wait(0)
    end
end

RegisterCommand('+zonebuilder_finish', function()
    if mode == 'poly' or mode == 'radius' then finishBuilder() end
end, false)
RegisterCommand('-zonebuilder_finish', function() end, false)
RegisterKeyMapping('+zonebuilder_finish', 'Construtor de Zona: Finalizar', 'keyboard', 'RETURN')

RegisterCommand('+zonebuilder_cancel', function()
    if mode ~= 'off' then
        mode = 'off'
        points = {}
        center = nil
        releaseSz()
        TriggerEvent('Notify', 'error', 'Construtor de zona cancelado.', 4)
    end
end, false)
RegisterCommand('-zonebuilder_cancel', function() end, false)
RegisterKeyMapping('+zonebuilder_cancel', 'Construtor de Zona: Cancelar', 'keyboard', 'BACK')

RegisterCommand('+zonebuilder_grow', function() growHeld = true end, false)
RegisterCommand('-zonebuilder_grow', function() growHeld = false end, false)
RegisterKeyMapping('+zonebuilder_grow', 'Construtor de Zona: Aumentar raio', 'keyboard', 'ADD')

RegisterCommand('+zonebuilder_shrink', function() shrinkHeld = true end, false)
RegisterCommand('-zonebuilder_shrink', function() shrinkHeld = false end, false)
RegisterKeyMapping('+zonebuilder_shrink', 'Construtor de Zona: Diminuir raio', 'keyboard', 'SUBTRACT')

RegisterNetEvent('admin:zonebuilder:start', function()
    if mode ~= 'off' then
        mode = 'off'
        points = {}
        center = nil
        releaseSz()
        TriggerEvent('Notify', 'info', 'Construtor de zona desligado.', 4)
        return
    end
    mode = 'choose'
    CreateThread(chooseLoop)
    TriggerEvent('Notify', 'info', 'CRIAR ZONA: aperte [1] PolyZone ou [2] Radius. Ligue o NOCLIP.', 6)
end)
