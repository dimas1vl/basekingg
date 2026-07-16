--[[ Modo "area": cria/remove/monitora NPCs fixos em zonas configuradas como triangulo/quad. ]]

local zonesConfig = MultitrackingModeAreaZones or {}
local resourceName = GetCurrentResourceName()
local pedsController = MultiTrackingGetPedsController("area")
local trackedPeds = {}
local lastSpawnAtByZone = {}
local POINT_RANDOM_RADIUS = 1.0
local configBuilder = GetGlobalConfigBuilder("area")

local function getConfig(_zoneConfig, key, default)
    if configBuilder and configBuilder.get then
        local value = configBuilder.get(key)
        if value ~= nil then
            return value
        end
    end
    return default
end

local function getRandomSpawnPoint(zoneConfig)
    return MultiTrackingGetRandomPointInZoneQuad(zoneConfig, POINT_RANDOM_RADIUS)
end

local function applyPedSetup(ped, heading)
    if not (ped and DoesEntityExist(ped)) then
        return false
    end

    MultiTrackingApplyDefaultPedFlags(ped, { canRagdoll = false })
    SetEntityHeading(ped, heading + 0.0)
    TaskStandStill(ped, -1)
    FreezeEntityPosition(ped, true)
    return true
end

local function spawnAreaNpc(zoneConfig, zoneKey)
    local spawnPoint = getRandomSpawnPoint(zoneConfig)
    if not spawnPoint then return false end

    local heading = MultiTrackingGetSpawnHeading(zoneConfig)
    local ped = CreateMultiTrackingPed(spawnPoint)
    if not ped then return false end

    if not applyPedSetup(ped, heading) then
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
        return false
    end

    trackedPeds[ped] = {
        createdAtMs = GetGameTimer(),
        zoneKey = zoneKey,
    }
    pedsController:registerNpc(ped)
    return true
end

local function countAlivePedsInZone(zoneKey)
    if not zoneKey then return 0 end

    local count = 0
    for ped, info in pairs(trackedPeds) do
        if ped and DoesEntityExist(ped) and info and info.zoneKey == zoneKey then
            count = count + 1
        end
    end
    return count
end

local function deleteAreaTrackingNpc(ped)
    trackedPeds[ped] = nil
    pedsController:deleteNpc(ped)
end
DeleteAreaTrackingNpc = deleteAreaTrackingNpc

local function deleteAllAreaTrackingNpcs()
    local pedsList = {}
    for ped, _ in pairs(trackedPeds) do
        pedsList[#pedsList + 1] = ped
    end

    for i = 1, #pedsList do
        DeleteAreaTrackingNpc(pedsList[i])
    end

    lastSpawnAtByZone = {}
end
DeleteAllAreaTrackingNpcs = deleteAllAreaTrackingNpcs

local function purgeDeadOrMissingPeds()
    local toRemove = {}
    for ped, _ in pairs(trackedPeds) do
        if not (ped and DoesEntityExist(ped) and not IsEntityDead(ped)) then
            toRemove[#toRemove + 1] = ped
        end
    end

    for i = 1, #toRemove do
        trackedPeds[toRemove[i]] = nil
    end
end

local function parseQuadCorners(zoneConfig)
    local points = zoneConfig and zoneConfig.points or nil
    if not points then
        return nil, nil, nil, nil
    end

    local fromList = points.from
    local toList = points.to

    local rawA = (fromList and fromList[1]) or points[1] or points.A
    local rawB = (fromList and fromList[2]) or points[2] or points.B
    local rawC = (toList and toList[1]) or points[3] or points.C
    local rawD = (toList and toList[2]) or points[4] or points.D

    local a = MultiTrackingParsePoint(rawA)
    local b = MultiTrackingParsePoint(rawB)
    local c = MultiTrackingParsePoint(rawC)
    local d = MultiTrackingParsePoint(rawD)

    if not (a and b and c and d) then
        return nil, nil, nil, nil
    end
    return a, b, c, d
end

local function isPointInsideZoneQuad(coords, zoneConfig)
    local a, b, c, d = parseQuadCorners(zoneConfig)
    if not (a and b and c and d) then
        return false
    end

    local p  = vector3(coords.x, coords.y, 0.0)
    local va = vector3(a.x, a.y, 0.0)
    local vb = vector3(b.x, b.y, 0.0)
    local vc = vector3(c.x, c.y, 0.0)
    local vd = vector3(d.x, d.y, 0.0)

    local inside = IsPointInTriangle(p, va, vb, vc)
    if not inside then
        inside = IsPointInTriangle(p, va, vc, vd)
    end
    return inside
end

AddEventHandler("multiTracking:area:client:monitorNpcs", function()
    if not pedsController then return end

    pedsController:setMonitorHandler(function(ped)
        local info = trackedPeds[ped]
        if not info then
            return false
        end

        if not DoesEntityExist(ped) then
            trackedPeds[ped] = nil
            return true
        end

        if IsEntityDead(ped) then
            trackedPeds[ped] = nil
            return true
        end

        local now = GetGameTimer()
        local zoneConfig
        if zonesConfig.zones then
            zoneConfig = zonesConfig.zones[info.zoneKey]
        end

        local lifetimeMs = tonumber(getConfig(zoneConfig, "pedLifetimeMs", 12000)) or 12000
        local age = now - info.createdAtMs
        if lifetimeMs <= age then
            trackedPeds[ped] = nil
            return true
        end

        local coords = GetEntityCoords(ped)
        if zoneConfig and isPointInsideZoneQuad(coords, zoneConfig) then
            return false
        end

        trackedPeds[ped] = nil
        return true
    end)

    pedsController:startMonitor()
end)

local function checkAreaTrackingNpcs(force)
    if not IsEnabledMultiTracking() then return end

    purgeDeadOrMissingPeds()

    local eligibleZones = GetAreaEligibleZones()
    if #eligibleZones == 0 then
        if next(trackedPeds) ~= nil then
            DeleteAllAreaTrackingNpcs()
        end
        return
    end

    local now = GetGameTimer()
    local zonesMap = zonesConfig.zones or {}
    local shuffled = MultiTrackingShuffleList(eligibleZones)
    local didSpawn = false

    for i = 1, #shuffled do
        local zoneKey = shuffled[i]
        local zoneConfig = zonesMap[zoneKey]
        if zoneConfig then
            local aliveCount = countAlivePedsInZone(zoneKey)
            local maxPeds = tonumber(getConfig(zoneConfig, "maxGeneratePeds", 6)) or 6

            if aliveCount < maxPeds then
                local lastSpawnAt = lastSpawnAtByZone[zoneKey] or 0
                local cooldownMs = tonumber(getConfig(zoneConfig, "spawnCooldownMs", 1500)) or 1500

                local canSpawn
                if force then
                    canSpawn = force
                else
                    canSpawn = cooldownMs <= (now - lastSpawnAt)
                end

                if canSpawn then
                    if spawnAreaNpc(zoneConfig, zoneKey) then
                        lastSpawnAtByZone[zoneKey] = now
                        didSpawn = true
                    end
                end
            end
        end
    end

    if didSpawn then
        TriggerEvent("multiTracking:area:client:monitorNpcs")
    end
end
CheckAreaTrackingNpcs = checkAreaTrackingNpcs

AddEventHandler("multiTracking:client:npcKilled", function()
    if not IsEnabledMultiTracking() then return end
    CheckAreaTrackingNpcs(true)
end)

AddEventHandler("onResourceStart", function(startedResource)
    if startedResource ~= resourceName then return end
    DeleteAllAreaTrackingNpcs()
end)
