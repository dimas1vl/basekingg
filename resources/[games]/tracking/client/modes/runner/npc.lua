--[[ Modo "runner": NPCs que spawnam em um lado da zona, correm ate o lado oposto e sao removidos. ]]

local zonesConfig = MultitrackingModeRunnerZones or {}
local resourceName = GetCurrentResourceName()
local pedsController = MultiTrackingGetPedsController("runner")
local trackedPeds = {}
local lastSpawnAtMs = 0
local configBuilder = GetGlobalConfigBuilder("runner")

local function getConfig(key, default)
    if configBuilder and configBuilder.get then
        local value = configBuilder.get(key)
        if value ~= nil then
            return value
        end
    end
    return default
end

local function getRunSpeed()
    local raw = getConfig("runSpeed", 3.0)
    local speed = tonumber(raw) or 3.0
    return speed + 0.0
end

local function normalizeVector2d(rawVec)
    local v = MultiTrackingParsePoint(rawVec)
    if not v then return nil end

    local length = math.sqrt((v.x * v.x) + (v.y * v.y))
    if length <= 0.0 then
        return nil
    end

    return vector3(v.x / length, v.y / length, 0.0)
end

local function computeRunDirection(zoneConfig)
    local points = zoneConfig and zoneConfig.points or nil
    if not points then return nil end

    local fromList = points.from
    local toList = points.to
    if not fromList or not toList then return nil end

    local fromA = MultiTrackingParsePoint(fromList[1])
    local fromB = MultiTrackingParsePoint(fromList[2])
    local toA = MultiTrackingParsePoint(toList[1])
    local toB = MultiTrackingParsePoint(toList[2])

    if not (fromA and fromB and toA and toB) then
        return nil
    end

    local fromCenter = vector3((fromA.x + fromB.x) / 2.0, (fromA.y + fromB.y) / 2.0, 0.0)
    local toCenter = vector3((toA.x + toB.x) / 2.0, (toA.y + toB.y) / 2.0, 0.0)

    return normalizeVector2d(vector3(toCenter.x - fromCenter.x, toCenter.y - fromCenter.y, 0.0))
end

local function getRunDirection(zoneConfig)
    local dir = computeRunDirection(zoneConfig)
    if dir then return dir end
    return vector3(1.0, 0.0, 0.0)
end

local function getRunnerEligibleZones()
    local zonesMap = zonesConfig.zones or {}
    local eligible = {}

    for zoneKey, zoneConfig in pairs(zonesMap) do
        if MultiTrackingIsPlayerInsideZoneConfig(zoneConfig, zoneKey) then
            eligible[#eligible + 1] = zoneKey
        end
    end

    return eligible
end
GetRunnerEligibleZones = getRunnerEligibleZones

local function pickRandomEligibleZone()
    local zonesMap = zonesConfig.zones or {}
    local eligible = getRunnerEligibleZones()
    if #eligible == 0 then
        return nil, nil
    end

    math.randomseed(GetGameTimer())
    local idx = math.random(1, #eligible)
    local zoneKey = eligible[idx]
    return zonesMap[zoneKey], zoneKey
end

local function getRandomSpawnInFromEdge(zoneConfig)
    local points = zoneConfig and zoneConfig.points or nil
    local fromList = points and points.from or nil
    if not fromList then return nil end

    local fromA = MultiTrackingParsePoint(fromList[1])
    local fromB = MultiTrackingParsePoint(fromList[2])
    if not (fromA and fromB) then return nil end

    math.randomseed(GetGameTimer())
    local t = math.random()

    return vector3(
        fromA.x + (fromB.x - fromA.x) * t,
        fromA.y + (fromB.y - fromA.y) * t,
        fromA.z + (fromB.z - fromA.z) * t
    )
end

local function assignRunTask(ped, info)
    if not (ped and DoesEntityExist(ped)) then return end
    if not info then return end

    local target = info.target
    if not target then return end

    local heading = GetHeadingFromVector_2d(info.dir.x, info.dir.y)
    local runSpeed = getRunSpeed()

    local moveRate = math.max(1.0, math.min(10.0, runSpeed / 2.5))
    local moveBlend = math.max(1.0, math.min(3.0, runSpeed / 5.0))

    SetPedMoveRateOverride(ped, moveRate + 0.0)
    SetPedDesiredMoveBlendRatio(ped, moveBlend + 0.0)
    SetPedMaxMoveBlendRatio(ped, 3.0)
    SetPedMinMoveBlendRatio(ped, 1.0)
    TaskGoStraightToCoord(ped, target.x, target.y, target.z, runSpeed, -1, heading, 0.0)
    SetEntityHeading(ped, heading)
end

local function enforceRunVelocity(ped, info)
    if not (ped and DoesEntityExist(ped)) then return end
    if not (info and info.dir) then return end

    local velocity = GetEntityVelocity(ped)
    local runSpeed = getRunSpeed()
    local vx = info.dir.x * runSpeed
    local vy = info.dir.y * runSpeed

    SetEntityVelocity(ped, vx + 0.0, vy + 0.0, velocity.z + 0.0)
end

local function applyRunnerPedSetup(ped, dir)
    if not (ped and DoesEntityExist(ped)) then
        return false
    end

    MultiTrackingApplyDefaultPedFlags(ped, { canRagdoll = false })
    SetPedMaxMoveBlendRatio(ped, 3.0)
    SetPedMinMoveBlendRatio(ped, 1.0)
    SetPedDesiredMoveBlendRatio(ped, 3.0)
    SetPedMoveRateOverride(ped, 1.0)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)

    local heading = GetHeadingFromVector_2d(dir.x, dir.y)
    SetEntityHeading(ped, heading)
    return true
end

local function spawnRunnerNpc(zoneConfig, zoneKey)
    local spawnPoint = getRandomSpawnInFromEdge(zoneConfig)
    if not spawnPoint then return false end

    local dir = getRunDirection(zoneConfig)
    local ped = CreateMultiTrackingPed(spawnPoint)
    if not ped then return false end

    if not applyRunnerPedSetup(ped, dir) then
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
        return false
    end

    local runDistance = tonumber(getConfig("runDistance", 120.0)) or 120.0
    local target = vector3(
        spawnPoint.x + dir.x * runDistance,
        spawnPoint.y + dir.y * runDistance,
        spawnPoint.z
    )

    local toCenter
    local points = zoneConfig and zoneConfig.points or nil
    if points and points.to then
        local toA = MultiTrackingParsePoint(points.to[1])
        local toB = MultiTrackingParsePoint(points.to[2])
        if toA and toB then
            toCenter = vector3(
                (toA.x + toB.x) / 2.0,
                (toA.y + toB.y) / 2.0,
                (toA.z + toB.z) / 2.0
            )
        end
    end

    local info = {
        dir = dir,
        target = target,
        zoneKey = zoneKey,
        toCenter = toCenter,
    }
    trackedPeds[ped] = info

    pedsController:registerNpc(ped)
    assignRunTask(ped, trackedPeds[ped])
    return true
end

local function getRunnerPedsRegistry()
    return trackedPeds
end
GetRunnerPedsRegistry = getRunnerPedsRegistry

local function deleteRunnerNpc(ped)
    trackedPeds[ped] = nil
    pedsController:deleteNpc(ped)
end

local function deleteAllRunnerNpcs()
    local pedsList = {}
    for ped, _ in pairs(trackedPeds) do
        pedsList[#pedsList + 1] = ped
    end

    for i = 1, #pedsList do
        deleteRunnerNpc(pedsList[i])
    end

    lastSpawnAtMs = 0
end

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

local function hasPassedTarget(coords, info)
    if info.toCenter then
        local dx = (coords.x - info.toCenter.x) * info.dir.x
        local dy = (coords.y - info.toCenter.y) * info.dir.y
        return (dx + dy) >= 0.0
    else
        local zoneConfig
        if zonesConfig.zones then
            zoneConfig = zonesConfig.zones[info.zoneKey]
        end
        local insideQuad = isPointInsideZoneQuad(coords, zoneConfig)
        return (not zoneConfig) or insideQuad
    end
end

AddEventHandler("multiTracking:runner:client:monitorNpcs", function()
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

        local coords = GetEntityCoords(ped)
        if hasPassedTarget(coords, info) then
            trackedPeds[ped] = nil
            return true
        end

        TickRunnerMovement(ped, info, coords, assignRunTask, enforceRunVelocity)
        return false
    end)

    pedsController:startMonitor()
end)

local function checkRunnerTrackingNpcs(force)
    if not IsEnabledMultiTracking() then return end

    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 then return end

    local playerCoords = GetEntityCoords(playerPed)
    if playerCoords.x == 0.0 and playerCoords.y == 0.0 and playerCoords.z == 0.0 then
        return
    end

    purgeDeadOrMissingPeds()

    local eligibleZones = getRunnerEligibleZones()
    if #eligibleZones == 0 then
        if next(trackedPeds) ~= nil then
            deleteAllRunnerNpcs()
        end
        return
    end

    local aliveCount = 0
    for ped, _ in pairs(trackedPeds) do
        if ped and DoesEntityExist(ped) then
            aliveCount = aliveCount + 1
        end
    end

    local zoneConfig, zoneKey = pickRandomEligibleZone()
    if not zoneConfig then return end

    local maxPeds = tonumber(getConfig("maxGeneratePeds", 4)) or 4
    if aliveCount >= maxPeds then return end

    local now = GetGameTimer()
    local cooldownMs = tonumber(getConfig("spawnCooldownMs", 1500)) or 1500

    if not force then
        if cooldownMs > (now - lastSpawnAtMs) then
            return
        end
    end

    if spawnRunnerNpc(zoneConfig, zoneKey) then
        lastSpawnAtMs = now
        TriggerEvent("multiTracking:runner:client:monitorNpcs")
    end
end
CheckRunnerTrackingNpcs = checkRunnerTrackingNpcs

AddEventHandler("multiTracking:client:npcKilled", function()
    if not IsEnabledMultiTracking() then return end
    CheckRunnerTrackingNpcs(true)
end)

AddEventHandler("onResourceStart", function(startedResource)
    if startedResource ~= resourceName then return end
    deleteAllRunnerNpcs()
end)

AddEventHandler("multiTracking:whenLeave", function()
    deleteAllRunnerNpcs()
end)
