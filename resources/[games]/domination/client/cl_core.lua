Zone = {
    active   = false,
    id       = nil,
    label    = nil,
    center   = nil,
    radius   = 0.0,
    threadId = 0,
}

currentSlot = 1

Dom = {
    state    = nil,
    equipped = {},
    level    = 1,
    kills    = 0,
    deaths   = 0,
}

hubOpen = false
shopOpen = false
spawnOpen = false
vehiclesOpen = false
respawning = false
spawnZoneId = nil
lastSpawnedVehicle = nil

hubCam = nil

SAFE_GROUP_NAME = 'DOM_SAFE'
SAFE_GROUP_HASH = GetHashKey(SAFE_GROUP_NAME)
safeRelInit = false

function setupSafeRel()
    if safeRelInit then return end
    AddRelationshipGroup(SAFE_GROUP_NAME)
    SetRelationshipBetweenGroups(0, SAFE_GROUP_HASH, SAFE_GROUP_HASH)
    safeRelInit = true
end

function applyVehicleProtection(protectedNow)
    local veh = lastSpawnedVehicle
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    if protectedNow then
        SetEntityInvincible(veh, true)
        SetEntityAlpha(veh, hubOpen and 255 or 80, false)
    else
        SetEntityInvincible(veh, false)
        ResetEntityAlpha(veh)
    end
end

function applyNoPvpFlags()
    local ped = PlayerPedId()
    if ped == 0 then return end
    SetPedRelationshipGroupHash(ped, SAFE_GROUP_HASH)
    SetCanAttackFriendly(ped, false, false)
    NetworkSetFriendlyFireOption(false)
    if hubOpen then
        SetEntityAlpha(ped, 255, false)
    else
        SetEntityAlpha(ped, 80, false)
    end
    SetEntityInvincible(ped, true)
    SetPlayerInvincible(PlayerId(), true)
    applyVehicleProtection(true)
end

SZ_DICT     = 'safezone'
SZ_TEX      = 'kingg_safezone'
SZ_HEIGHT   = 1000.0
szTexLoaded = false

function loadSafeZoneTexture()
    if szTexLoaded then return end
    RequestStreamedTextureDict(SZ_DICT, true)
    local deadline = GetGameTimer() + 5000
    while not HasStreamedTextureDictLoaded(SZ_DICT) and GetGameTimer() < deadline do
        Wait(50)
    end
    szTexLoaded = HasStreamedTextureDictLoaded(SZ_DICT)
end

function drawMarkers()
    if not Zone.active then return end
    local ped = PlayerPedId()
    local pos = ped ~= 0 and GetEntityCoords(ped) or nil

    local insideDom = false
    local dz = Config.Domination.dominationZones
    if pos then
        for i = 1, #dz do
            local z = dz[i]
            local c = z.center
            local r = tonumber(z.radius) or 200.0
            local dx, dy = pos.x - c.x, pos.y - c.y
            if (dx * dx + dy * dy) <= (r * r) then
                insideDom = true
                local size = r
                local h = (c.w and c.w > 0.0 and c.w) or 20.0
                local m = z.marker or { 255, 255, 0, 150 }
                DrawMarker(28, c.x, c.y, c.z - 1.0, 0.0,0.0,0.0, 0.0,0.0,0.0,
                    size, size, h, m[1], m[2], m[3], m[4] or 150, false, false, 2, false, SZ_DICT, SZ_TEX, false)
            end
        end
    end

    if not insideDom then
        local sz = Config.Domination.safeZones
        for i = 1, #sz do
            local z = sz[i]
            local c = z.center
            local size = (tonumber(z.radius) or 120.0) * 1.98412
            DrawMarker(1, c.x, c.y, c.z - 300.0, 0.0,0.0,0.0, 0.0,0.0,0.0,
                size, size, SZ_HEIGHT, 60, 230, 120, 130, false, false, 2, false, SZ_DICT, SZ_TEX, false)
        end
    end
end

szBlips = {}           -- blips de raio (safe + dominacao)
zoneCentralBlip = {}   -- [zoneId] = blip central da zona de dominacao
zoneById = {}          -- [zoneId] = zona de dominacao (label/tag/cor)

function removeSafeZoneBlips()
    for i = 1, #szBlips do
        if DoesBlipExist(szBlips[i]) then RemoveBlip(szBlips[i]) end
    end
    szBlips = {}
    for _, b in pairs(zoneCentralBlip) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    zoneCentralBlip = {}
end

zoneCooldownUntil = {}  -- [zoneId] = GetGameTimer()+ms (contagem do cooldown no blip)

local function fmtCooldown(ms)
    local s = math.max(0, math.floor((ms or 0) / 1000))
    local m = math.floor(s / 60)
    local r = s % 60
    if m > 0 and r > 0 then return m .. 'm ' .. r .. 's' end
    if m > 0 then return m .. 'm' end
    return r .. 's'
end

local function setBlipName(b, name)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(name)
    EndTextCommandSetBlipName(b)
end

function applyZoneState(zoneId, st)
    local b = zoneCentralBlip[zoneId]
    local z = zoneById[zoneId]
    if not b or not z or not DoesBlipExist(b) then return end
    st = st or {}
    zoneCooldownUntil[zoneId] = nil
    SetBlipSprite(b, st.cd and 365 or ((st.cap or st.contested) and 161 or 1))
    SetBlipColour(b, tonumber(z.blipColor) or 5)  -- mantem a cor da zona em qualquer sprite
    local name
    if st.cd then
        zoneCooldownUntil[zoneId] = GetGameTimer() + (st.ms or 0)
        name = (z.label or '') .. ' — Em Cooldown (' .. fmtCooldown(st.ms) .. ')'
    elseif st.contested then
        name = (z.label or '') .. ' — Contestada'
    elseif st.cap and st.cap ~= '' then
        name = st.cap .. ' dominando ' .. (z.label or '')
    else
        name = 'Dominação ' .. (z.label or '')
    end
    setBlipName(b, name)
    SetBlipFlashes(b, st.cd == true)
end

-- atualiza o tempo restante do cooldown nos blips
CreateThread(function()
    while true do
        Wait(5000)
        for zoneId, untilMs in pairs(zoneCooldownUntil) do
            local b = zoneCentralBlip[zoneId]
            local z = zoneById[zoneId]
            if b and z and DoesBlipExist(b) then
                local rem = untilMs - GetGameTimer()
                if rem > 0 then
                    setBlipName(b, (z.label or '') .. ' — Em Cooldown (' .. fmtCooldown(rem) .. ')')
                end
            end
        end
    end
end)

function createSafeZoneBlips()
    removeSafeZoneBlips()
    zoneById = {}

    -- bases seguras: raio verde + icone "Base Segura: <Nome>"
    local sz = Config.Domination.safeZones
    for i = 1, #sz do
        local z = sz[i]
        local c = z.center
        local rad = AddBlipForRadius(c.x, c.y, c.z, tonumber(z.radius) or 120.0)
        SetBlipColour(rad, 2); SetBlipAlpha(rad, 80); SetBlipHighDetail(rad, true)
        szBlips[#szBlips + 1] = rad
        local b = AddBlipForCoord(c.x, c.y, c.z)
        SetBlipSprite(b, 1); SetBlipColour(b, 2); SetBlipScale(b, 0.8); SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('SafeZone: ' .. (z.label or ''))
        EndTextCommandSetBlipName(b)
        szBlips[#szBlips + 1] = b
    end

    -- zonas de dominacao: raio colorido + blip central "Dominação <Nome>"
    local dz = Config.Domination.dominationZones
    for i = 1, #dz do
        local z = dz[i]
        zoneById[z.id] = z
        local c = z.center
        local col = tonumber(z.blipColor) or 5
        local rad = AddBlipForRadius(c.x, c.y, c.z, tonumber(z.radius) or 200.0)
        SetBlipColour(rad, col); SetBlipAlpha(rad, 80); SetBlipHighDetail(rad, true)
        szBlips[#szBlips + 1] = rad
        local b = AddBlipForCoord(c.x, c.y, c.z)
        SetBlipSprite(b, 1); SetBlipColour(b, col); SetBlipScale(b, 0.9); SetBlipAsShortRange(b, true)
        zoneCentralBlip[z.id] = b
        applyZoneState(z.id, nil)
    end
end

RegisterNetEvent('domination:zone:state', function(zoneId, st)
    if not Zone.active then return end
    applyZoneState(zoneId, st)
end)

RegisterNetEvent('domination:layout', function(layout)
    if type(layout) ~= 'table' then return end
    Config.Domination.dominationZones = Config.Domination.buildDominationZones(layout)
    if Zone.active then
        createSafeZoneBlips()
        domReportedZone = ''
    end
end)

CreateThread(function()
    Wait(500)
    TriggerServerEvent('domination:layout:request')
end)

-- presenca/dominacao: estado da barra de captura
domReportedZone = ''
captureLastAt   = 0
captureShown    = false

RegisterNetEvent('domination:progress', function(data)
    if not Zone.active then return end
    if not data then
        captureShown = false
        SendNUIMessage({ action = 'capture', visible = false })
        return
    end
    captureLastAt = GetGameTimer()
    captureShown  = true
    SendNUIMessage({
        action    = 'capture',
        visible   = true,
        zone      = data.zone,
        team      = data.team,
        members   = data.members,
        pct       = data.pct,
        color     = data.color,
        contested = data.contested,
    })
end)

RegisterNetEvent('domination:reward', function(data)
    if not Zone.active or not data then return end
    if data.xp and data.xp > 0 and Dom.state then
        local per = Config.Domination.level.xpPerLevel
        Dom.state.xp = (Dom.state.xp or 0) + data.xp
        Dom.state.level = Config.Domination.levelFromXp(Dom.state.xp)
        Dom.state.xpIntoLevel = (Dom.state.level >= (Config.Domination.level.maxLevel or 100)) and per or (Dom.state.xp % per)
        Dom.state.xpPerLevel = per
    end
    SendNUIMessage({ action = 'dom:reward', xp = data.xp or 0, money = data.money or 0 })
end)

RegisterNetEvent('domination:zonefeed', function(data)
    if not Zone.active or not data then return end
    SendNUIMessage({ action = 'zonefeed', kind = data.kind, team = data.team, zone = data.zone })
end)

RegisterNetEvent('domination:killfeed', function(data)
    if not Zone.active or not data then return end
    local mySrc = GetPlayerServerId(PlayerId())
    SendNUIMessage({ action = 'killFeed', selfSrc = mySrc, data = data })
    if data.killerSrc == mySrc and data.victimSrc ~= mySrc then
        SendNUIMessage({ action = 'sfx', cat = 'kill' })
        if DomSettings and DomSettings.hud and DomSettings.hud.killMarker then
            SendNUIMessage({ action = 'killMarker', color = DomSettings.hud.killColor })
        end
    end
end)

-- esconde a barra se parar de chegar progresso (saiu da zona / disputada / dominou)
CreateThread(function()
    while true do
        Wait(500)
        if captureShown and (GetGameTimer() - captureLastAt) > 1600 then
            captureShown = false
            SendNUIMessage({ action = 'capture', visible = false })
        end
    end
end)

inSafeZone = false
graceUntil = 0
GRACE_MS   = 10000

function sendZoneStatus()
    if hubOpen or shopOpen or spawnOpen then return end
    if not Zone.active then
        SendNUIMessage({ action = 'status', visible = false })
        return
    end
    local lbl = (curZone and curZone.label) or Zone.label
    if inSafeZone then
        SendNUIMessage({ action = 'status', visible = true, kind = 'ghost', label = lbl })
    elseif GetGameTimer() < graceUntil then
        SendNUIMessage({ action = 'status', visible = true, kind = 'danger', label = lbl, ms = graceUntil - GetGameTimer() })
    else
        SendNUIMessage({ action = 'status', visible = false })
    end
end

curZone = nil

---@return table|nil safezone (da config) em que o player está fisicamente
function currentSafeZone()
    if not Zone.active then return nil end
    local ped = PlayerPedId()
    if ped == 0 then return nil end
    local pos = GetEntityCoords(ped)
    local zones = Config.Domination.safeZones
    for i = 1, #zones do
        local z = zones[i]
        local c = z.center
        local r = tonumber(z.radius) or 200.0
        local dx, dy = pos.x - c.x, pos.y - c.y
        if (dx * dx + dy * dy) <= (r * r) then return z end
    end
    return nil
end

function isInsideZone()
    return currentSafeZone() ~= nil
end

---@return table|nil zona de DOMINACAO em que o player está fisicamente
function currentDominationZone()
    if not Zone.active then return nil end
    local ped = PlayerPedId()
    if ped == 0 then return nil end
    local pos = GetEntityCoords(ped)
    local zones = Config.Domination.dominationZones
    for i = 1, #zones do
        local z = zones[i]
        local c = z.center
        local r = tonumber(z.radius) or 200.0
        local dx, dy = pos.x - c.x, pos.y - c.y
        if (dx * dx + dy * dy) <= (r * r) then return z end
    end
    return nil
end

function applyOutsideFlags()
    local ped = PlayerPedId()
    if ped == 0 then return end
    if not hubOpen then
        SetEntityAlpha(ped, 255, false)
    end
    SetEntityInvincible(ped, false)
    SetPlayerInvincible(PlayerId(), false)
    NetworkSetFriendlyFireOption(true)
    applyVehicleProtection(false)
end

function startZoneThread()
    Zone.threadId = Zone.threadId + 1
    local myId = Zone.threadId
    inSafeZone = true
    CreateThread(function()
        loadSafeZoneTexture()
        local lastApply = 0
        local lastView  = 'safe'
        local lastLabel = nil
        while myId == Zone.threadId and Zone.active do
            drawMarkers()

            DisableControlAction(0, 37, true)
            DisableControlAction(0, 14, true)
            DisableControlAction(0, 15, true)
            for c = 157, 165 do DisableControlAction(0, c, true) end

            -- na base segura NAO pode atirar/socar
            if inSafeZone then
                DisableControlAction(0, 24, true)   -- atacar/atirar
                DisableControlAction(0, 257, true)  -- atacar 2
                DisableControlAction(0, 25, true)   -- mirar
                DisableControlAction(0, 263, true)  -- melee
                DisableControlAction(0, 264, true)
                DisableControlAction(0, 140, true)
                DisableControlAction(0, 141, true)
                DisableControlAction(0, 142, true)
                DisableControlAction(0, 143, true)
                DisableControlAction(0, 69, true)   -- atirar no veiculo
                DisableControlAction(0, 70, true)
                DisableControlAction(0, 92, true)
                DisableControlAction(0, 114, true)
                DisablePlayerFiring(PlayerId(), true)
            end

            local now = GetGameTimer()

            if now - lastApply > 250 and not respawning then
                local zoneNow = currentSafeZone()
                local nowInside = zoneNow ~= nil
                if zoneNow then curZone = zoneNow end

                if nowInside and not inSafeZone then
                    graceUntil = 0
                elseif (not nowInside) and inSafeZone then
                    graceUntil = now + GRACE_MS
                end
                inSafeZone = nowInside

                local domNow = currentDominationZone()
                local hereId = domNow and domNow.id or ''
                if hereId ~= domReportedZone then
                    domReportedZone = hereId
                    TriggerServerEvent('domination:zone:here', hereId)
                end

                if inSafeZone or graceUntil > now then
                    applyNoPvpFlags()
                else
                    applyOutsideFlags()
                end

                local view = inSafeZone and 'safe' or (graceUntil > now and 'grace' or 'vuln')
                local curLbl = (curZone and curZone.label) or Zone.label
                if view ~= lastView or curLbl ~= lastLabel then
                    lastView  = view
                    lastLabel = curLbl
                    sendZoneStatus()
                end

                lastApply = now
            end
            Wait(0)
        end
        if szTexLoaded then
            SetStreamedTextureDictAsNoLongerNeeded(SZ_DICT)
            szTexLoaded = false
        end
    end)
end

function teleportToCenter(center)
    local ped = PlayerPedId()
    if not ped or ped == 0 then return end

    DoScreenFadeOut(300)
    local fadeDeadline = GetGameTimer() + 600
    while not IsScreenFadedOut() and GetGameTimer() < fadeDeadline do Wait(0) end

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)

    RequestCollisionAtCoord(center.x, center.y, center.z)
    NewLoadSceneStartSphere(center.x, center.y, center.z, 200.0, 0)

    SetEntityCoordsNoOffset(ped, center.x, center.y, center.z, false, false, false)
    SetEntityHeading(ped, 0.0)

    local deadline = GetGameTimer() + 8000
    while GetGameTimer() < deadline do
        RequestCollisionAtCoord(center.x, center.y, center.z)
        if HasCollisionLoadedAroundEntity(ped) then break end
        Wait(50)
    end
    NewLoadSceneStop()

    local found, gz = GetGroundZFor_3dCoord(center.x, center.y, center.z + 50.0, false)
    if found then
        SetEntityCoordsNoOffset(ped, center.x, center.y, gz + 0.1, false, false, false)
    end

    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)

    DoScreenFadeIn(500)
end

CreateThread(function()
    local last = -1
    while true do
        if Zone.active then
            local camRot = GetGameplayCamRot(2)
            local heading = math.floor(((360.0 - ((camRot.z + 360.0) % 360.0)) + 360.0) % 360.0)
            if heading ~= last then
                last = heading
                SendNUIMessage({ action = 'hud:meters', data = { heading = heading } })
            end
            Wait(0)
        else
            last = -1
            Wait(500)
        end
    end
end)