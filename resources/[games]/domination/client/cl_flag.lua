local flags     = {}
local worldProp = {}
local backProp  = {}
local flagBlip  = {}

local DRAW_DIST = 200.0

local function cfg() return Config.Domination.flag or {} end

local function myServerId() return GetPlayerServerId(PlayerId()) end

local function pedOf(serverId)
    if serverId == myServerId() then return PlayerPedId() end
    local p = GetPlayerFromServerId(serverId)
    if p == -1 then return 0 end
    local ped = GetPlayerPed(p)
    return (ped and ped ~= 0) and ped or 0
end

---@param id string
---@return table|nil
local function zoneById(id)
    local zs = Config.Domination.dominationZones or {}
    for i = 1, #zs do
        if zs[i].id == id then return zs[i] end
    end
    return nil
end

---@param ped number
---@param zone table|nil
---@return boolean
local function holderHasFlag(ped, zone)
    if ped == 0 or not zone or not zone.center then return false end
    if IsEntityDead(ped) or IsPedDeadOrDying(ped, true) then return false end
    local c = GetEntityCoords(ped)
    local r = tonumber(zone.radius) or 75.0
    local dx, dy = c.x - zone.center.x, c.y - zone.center.y
    return (dx * dx + dy * dy) <= (r * r)
end

local function loadProp()
    local model = cfg().model or 'prop_flag_ls'
    local hash  = type(model) == 'string' and GetHashKey(model) or model
    if not IsModelInCdimage(hash) then return nil end
    if not HasModelLoaded(hash) then
        RequestModel(hash)
        local dl = GetGameTimer() + 2000
        while not HasModelLoaded(hash) and GetGameTimer() < dl do Wait(0) end
    end
    return HasModelLoaded(hash) and hash or nil
end

local function delEntity(ref)
    if ref and DoesEntityExist(ref) then
        SetEntityAsMissionEntity(ref, true, true)
        DeleteEntity(ref)
    end
end

local function removeWorld(zoneId) delEntity(worldProp[zoneId]); worldProp[zoneId] = nil end
local function removeBack(zoneId)  delEntity(backProp[zoneId]);  backProp[zoneId]  = nil end
local function removeBlip(zoneId)
    if flagBlip[zoneId] and DoesBlipExist(flagBlip[zoneId]) then RemoveBlip(flagBlip[zoneId]) end
    flagBlip[zoneId] = nil
end

local function clearFlag(zoneId) removeWorld(zoneId); removeBack(zoneId); removeBlip(zoneId) end

local function clearAll()
    for zoneId in pairs(flags) do clearFlag(zoneId) end
    flags = {}
end

local function ensureWorld(zoneId, fs)
    removeBack(zoneId)
    local obj = worldProp[zoneId]
    if obj and DoesEntityExist(obj) then
        SetEntityCoordsNoOffset(obj, fs.x, fs.y, fs.z, false, false, false)
        return
    end
    local hash = loadProp(); if not hash then return end
    obj = CreateObject(hash, fs.x, fs.y, fs.z, false, false, false)
    SetEntityAsMissionEntity(obj, true, true)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    worldProp[zoneId] = obj
    SetModelAsNoLongerNeeded(hash)
end

local function ensureBack(zoneId, holderSrc)
    removeWorld(zoneId)
    local ped = pedOf(holderSrc)
    if ped == 0 then removeBack(zoneId); return end
    local obj = backProp[zoneId]
    if obj and DoesEntityExist(obj) and IsEntityAttachedToEntity(obj, ped) then return end
    removeBack(zoneId)
    local hash = loadProp(); if not hash then return end
    obj = CreateObject(hash, 0.0, 0.0, 0.0, false, false, false)
    local c = cfg()
    local o = c.offset or { x = 0.0, y = -0.22, z = 0.0 }
    local r = c.rot    or { x = 0.0, y = 0.0,  z = 0.0 }
    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, c.bone or 24818),
        o.x, o.y, o.z, r.x, r.y, r.z, false, false, false, false, 2, true)
    backProp[zoneId] = obj
    SetModelAsNoLongerNeeded(hash)
end

local function ensureBlip(zoneId, x, y, z, held, dropped)
    local b = flagBlip[zoneId]
    if not b or not DoesBlipExist(b) then
        b = AddBlipForCoord(x, y, z)
        SetBlipSprite(b, 309)
        SetBlipScale(b, 1.1)
        SetBlipAsShortRange(b, false)
        flagBlip[zoneId] = b
    else
        SetBlipCoords(b, x, y, z)
    end
    SetBlipColour(b, held and 1 or (dropped and 47 or 5))
    SetBlipFlashes(b, (held or dropped) and true or false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(held and 'Bandeira (em fuga)' or (dropped and 'Bandeira (no chão)' or 'Bandeira'))
    EndTextCommandSetBlipName(b)
end

local function drawFlagMarker(x, y, z)
    DrawMarker(1, x, y, z - 1.0, 0,0,0, 0,0,0, 2.0,2.0,1.5, 255,80,200,100, false, false, 2, false, nil, nil, false)
    local bob = math.sin(GetGameTimer() / 300.0) * 0.15
    DrawMarker(2, x, y, z + 1.8 + bob, 0,0,0, 180.0,0,0, 0.6,0.6,0.6, 255,220,40,200, false, true, 2, false, nil, nil, false)
end

local function setFlag(zoneId, data)
    flags[zoneId] = { holder = data.holder, x = data.x + 0.0, y = data.y + 0.0, z = data.z + 0.0, dropped = data.dropped }
end

RegisterNetEvent('domination:flag', function(zoneId, data)
    if type(zoneId) ~= 'string' or type(data) ~= 'table' then return end
    setFlag(zoneId, data)
end)

RegisterNetEvent('domination:enter', function(payload)
    if type(payload) == 'table' and type(payload.flags) == 'table' then
        for _, f in ipairs(payload.flags) do setFlag(f.id, f) end
    end
end)

RegisterNetEvent('domination:leave', function() clearAll() end)
RegisterNetEvent('domination:layout', function() clearAll() end)

local promptOn = false

local function setPrompt(on)
    if on == promptOn then return end
    promptOn = on
    SendNUIMessage({ action = 'flag:prompt', visible = on })
end

CreateThread(function()
    while true do
        local sleep = 500
        local nearZone = nil
        if Zone.active then
            local myId  = myServerId()
            local ped   = PlayerPedId()
            local mypos = (ped ~= 0) and GetEntityCoords(ped) or nil
            local cur   = currentDominationZone and currentDominationZone()
            local insideId = cur and cur.id or nil
            local tnow  = GetGameTimer()
            for zoneId, fs in pairs(flags) do
                if zoneCooldownUntil[zoneId] and zoneCooldownUntil[zoneId] > tnow then
                    clearFlag(zoneId)
                elseif fs.holder then
                    local hped = pedOf(fs.holder)
                    local hx, hy, hz = fs.x, fs.y, fs.z
                    if hped ~= 0 then local hc = GetEntityCoords(hped); hx, hy, hz = hc.x, hc.y, hc.z end
                    if holderHasFlag(hped, zoneById(zoneId)) then
                        ensureBack(zoneId, fs.holder)
                    else
                        removeBack(zoneId)
                    end
                    if insideId == zoneId then ensureBlip(zoneId, hx, hy, hz, true, false) else removeBlip(zoneId) end
                    if mypos and fs.holder ~= myId and hped ~= 0 then
                        local dx, dy = mypos.x - hx, mypos.y - hy
                        if (dx * dx + dy * dy) <= DRAW_DIST * DRAW_DIST then
                            sleep = 0
                            local bob = math.sin(tnow / 300.0) * 0.12
                            DrawMarker(2, hx, hy, hz + 1.15 + bob, 0,0,0, 180.0,0,0, 0.4,0.4,0.4, 255,60,60,200, false, true, 2, false, nil, nil, false)
                        end
                    end
                else
                    if insideId == zoneId then ensureBlip(zoneId, fs.x, fs.y, fs.z, false, fs.dropped) else removeBlip(zoneId) end
                    if mypos then
                        local dx, dy, dz = mypos.x - fs.x, mypos.y - fs.y, mypos.z - fs.z
                        local dist2 = dx * dx + dy * dy + dz * dz
                        if dist2 <= DRAW_DIST * DRAW_DIST then
                            sleep = 0
                            ensureWorld(zoneId, fs)
                            drawFlagMarker(fs.x, fs.y, fs.z)
                            local pd = tonumber(cfg().pickupDist) or 2.5
                            if dist2 <= pd * pd then nearZone = zoneId end
                        else
                            removeWorld(zoneId)
                        end
                    end
                end
            end
            setPrompt(nearZone ~= nil)
            if nearZone and IsControlJustPressed(0, 38) then
                TriggerServerEvent('domination:flag:grab', nearZone)
            end
        else
            setPrompt(false)
            if next(flags) then clearAll() end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then clearAll() end
end)

RegisterCommand('centro', function()
    if not Zone.active then return end
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local zones = Config.Domination.dominationZones or {}
    local best, bestD2
    for i = 1, #zones do
        local z = zones[i]
        if z.type == 'bandeira' then
            local c = z.center
            local dx, dy = pos.x - c.x, pos.y - c.y
            local d2 = dx * dx + dy * dy
            if not bestD2 or d2 < bestD2 then bestD2 = d2; best = z end
        end
    end
    if not best then
        TriggerEvent('Notify', 'error', 'Nenhuma zona de bandeira no sorteio atual.', 4)
        return
    end
    local c = best.center
    SetEntityCoords(ped, c.x, c.y, c.z, false, false, false, false)
    TriggerEvent('Notify', 'success', ('Centro da bandeira: %s'):format(best.label or best.id), 4)
end, false)
