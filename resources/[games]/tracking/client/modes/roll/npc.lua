--[[ Modo "roll": cria/remove/monitora NPCs que tocam animacao de roll em zonas configuradas. ]]

local zonesConfig = MultitrackingModeRollZones or {}
local resourceName = GetCurrentResourceName()
local pedsController = MultiTrackingGetPedsController("roll")
local trackedPeds = {}
local lastSpawnAtByZone = {}
local POINT_RANDOM_RADIUS = 1.0
local configBuilder = GetGlobalConfigBuilder("roll")

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
    SetEntityInvincible(ped, false)
    SetPedCanBeTargetted(ped, true)
    SetEntityCollision(ped, true, true)
    SetEntityHeading(ped, heading + 0.0)
    FreezeEntityPosition(ped, false)
    return true
end

local function spawnRollNpc(zoneConfig, zoneKey)
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
        zoneKey = zoneKey,
        didPlayRoll = false,
        rollStartedAtMs = nil,
        rollFinishedAtMs = nil,
    }

    StartRollAnimationThread(ped, zoneKey, trackedPeds, zonesConfig)
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

local function deleteRollTrackingNpc(ped)
    trackedPeds[ped] = nil
    pedsController:deleteNpc(ped)
end
DeleteRollTrackingNpc = deleteRollTrackingNpc

local function deleteAllRollTrackingNpcs()
    local pedsList = {}
    for ped, _ in pairs(trackedPeds) do
        pedsList[#pedsList + 1] = ped
    end

    for i = 1, #pedsList do
        DeleteRollTrackingNpc(pedsList[i])
    end

    lastSpawnAtByZone = {}
end
DeleteAllRollTrackingNpcs = deleteAllRollTrackingNpcs

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

AddEventHandler("multiTracking:roll:client:monitorNpcs", function()
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

        local zoneConfig
        if zonesConfig.zones then
            zoneConfig = zonesConfig.zones[info.zoneKey]
        end

        if not zoneConfig then
            trackedPeds[ped] = nil
            return true
        end

        SetEntityInvincible(ped, false)
        SetPedCanBeTargetted(ped, true)
        SetEntityCollision(ped, true, true)

        local now = GetGameTimer()
        local rollDeleteDelayMs = tonumber(getConfig(zoneConfig, "rollDeleteDelayMs", 1000)) or 1000

        if info.rollStartedAtMs then
            local elapsed = now - info.rollStartedAtMs
            if rollDeleteDelayMs <= elapsed then
                trackedPeds[ped] = nil
                return true
            end
        end

        if info.didPlayRoll then
            if not IsPlayingRollAnimation(ped, zoneConfig) then
                ClearPedTasksImmediately(ped)
                trackedPeds[ped] = nil
                return true
            end
        end

        return false
    end)

    pedsController:startMonitor()
end)

local function checkRollTrackingNpcs(force)
    if not IsEnabledMultiTracking() then return end

    purgeDeadOrMissingPeds()

    local eligibleZones = GetRollEligibleZones()
    if #eligibleZones == 0 then
        if next(trackedPeds) ~= nil then
            DeleteAllRollTrackingNpcs()
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
                    if spawnRollNpc(zoneConfig, zoneKey) then
                        lastSpawnAtByZone[zoneKey] = now
                        didSpawn = true
                    end
                end
            end
        end
    end

    if didSpawn then
        TriggerEvent("multiTracking:roll:client:monitorNpcs")
    end
end
CheckRollTrackingNpcs = checkRollTrackingNpcs

AddEventHandler("multiTracking:client:npcKilled", function()
    if not IsEnabledMultiTracking() then return end
    CheckRollTrackingNpcs(true)
end)

AddEventHandler("onResourceStart", function(startedResource)
    if startedResource ~= resourceName then return end
    DeleteAllRollTrackingNpcs()
end)
