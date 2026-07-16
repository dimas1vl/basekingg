--[[ Orquestra o spawn de veículos por segmentos respeitando cooldown e limites. ]]

local vehicleModeEnabled = GetConvarBool("multiTrackingVehicleModeEnabled", true)
local scheduledRoutes = {}
local scheduledFlags = {}
local resetGeneration = 0

---@return boolean
local function isInsidePedOnlyZone()
    local rollFn = rawget(_G, 'GetRollEligibleZones')
    if type(rollFn) == 'function' then
        local ok, list = pcall(rollFn)
        if ok and type(list) == 'table' and #list > 0 then return true end
    end
    local areaFn = rawget(_G, 'GetAreaEligibleZones')
    if type(areaFn) == 'function' then
        local ok, list = pcall(areaFn)
        if ok and type(list) == 'table' and #list > 0 then return true end
    end
    return false
end

---@return boolean
local function isSpawnAllowed()
    if not vehicleModeEnabled then return false end
    if isInsidePedOnlyZone() then return false end
    local config = GetGlobalConfigBuilder("vehicles")
    if not config then return true end
    local value = config.get("vehicleSpawnEnabled")
    if value == nil then return true end
    return value == true
end

---@param routeKey      string
---@param segmentOffset number
---@param coords        vector3
local function spawnInstanceAtCoords(routeKey, segmentOffset, coords)
    if not coords or type(coords) ~= "vector3" then return end
    if not isSpawnAllowed() then return end
    if HasLimitTrackingVehicles() then return end

    local instance = CreateNewTrackingVehiclesInstance(routeKey)
    if not instance then return end

    instance.spawning = true

    local config = GetGlobalConfigBuilder("vehicles")
    local driveSpeedMultiplier = (config and config.get("driveSpeedMultiplier")) or 1.0
    local baseMultiplier = instance.baseMultiplierVelocity or 1.0
    instance:setPlaybackSpeed(baseMultiplier * driveSpeedMultiplier)
    instance.segmentOffset = segmentOffset
    instance:setStartRouteAt(GetGameTimer())

    Citizen.CreateThread(function()
        local ok = pcall(function() instance:createLocalVehicle(coords, 0.0) end)
        instance.spawning = false
        if not ok or not (instance.vehicle and DoesEntityExist(instance.vehicle)) then
            instance.destroyed = true
        end
    end)
end

---@param routeKey string
---@return number
local function countActiveOnRoute(routeKey)
    local routeInstances = GetAllTrackingVehiclesInstances()[routeKey] or {}
    local active = 0
    for instanceKey, instance in pairs(routeInstances) do
        if not instance.destroyed then
            if instance.spawning then
                active = active + 1
            elseif instance.vehicle and DoesEntityExist(instance.vehicle) then
                active = active + 1
            else
                instance.destroyed = true
                routeInstances[instanceKey] = nil
            end
        end
    end
    return active
end

---@param routeKey string
local function SpawnVehiclesBySegments(_, routeKey)
    if not routeKey or type(routeKey) ~= "string" then return end
    if not isSpawnAllowed() then return end
    scheduledRoutes[routeKey] = {}
    scheduledFlags[routeKey] = false
    TriggerEvent("multiTracking:reloadVehicles")
end
_G.SpawnVehiclesBySegments = SpawnVehiclesBySegments

AddEventHandler("multiTracking:vehicle:client:refreshPlaybackSpeed", function()
    local config = GetGlobalConfigBuilder("vehicles")
    local driveSpeedMultiplier = (config and config.get("driveSpeedMultiplier")) or 1.0
    local instances = GetAllTrackingVehiclesInstances()
    for _, routeInstances in pairs(instances) do
        for _, instance in pairs(routeInstances) do
            if not instance.destroyed then
                if instance.aiPatrolMode and instance.applyAiTask then
                    instance:applyAiTask()
                else
                    local baseMultiplier = instance.baseMultiplierVelocity or 1.0
                    instance:setPlaybackSpeed(baseMultiplier * driveSpeedMultiplier)
                end
            end
        end
    end
end)

local function fullVehicleCleanup()
    resetGeneration = resetGeneration + 1

    local instances = GetAllTrackingVehiclesInstances()
    for routeKey, routeInstances in pairs(instances) do
        for instanceKey, instance in pairs(routeInstances) do
            if instance then
                instance.aiPatrolMode = false
                if not instance.destroyed then
                    pcall(function() instance:destroy() end)
                end
                if instance.ped and DoesEntityExist(instance.ped) then
                    pcall(function()
                        SetEntityAsMissionEntity(instance.ped, true, true)
                        DeleteEntity(instance.ped)
                    end)
                end
                if instance.vehicle and DoesEntityExist(instance.vehicle) then
                    pcall(function()
                        SetEntityAsMissionEntity(instance.vehicle, true, true)
                        DeleteVehicle(instance.vehicle)
                    end)
                end
                if instance.blip and DoesBlipExist(instance.blip) then
                    pcall(function() RemoveBlip(instance.blip) end)
                end
                instance.ped = nil
                instance.vehicle = nil
                instance.blip = nil
            end
            routeInstances[instanceKey] = nil
        end
        instances[routeKey] = nil
    end

    for routeKey in pairs(scheduledRoutes) do
        scheduledRoutes[routeKey] = nil
        scheduledFlags[routeKey] = nil
    end
end
_G.FullTrackingVehicleCleanup = fullVehicleCleanup

AddEventHandler("multiTracking:vehicle:client:spawnDisabled", fullVehicleCleanup)
AddEventHandler("multiTracking:whenLeave", fullVehicleCleanup)

AddEventHandler("multiTracking:blips:changed", function()
    local instances = GetAllTrackingVehiclesInstances()
    for _, routeInstances in pairs(instances) do
        for _, instance in pairs(routeInstances) do
            if not instance.destroyed and instance.ensureBlip then
                pcall(function() instance:ensureBlip() end)
            end
        end
    end
end)

AddEventHandler("multiTracking:radiusSpawnConfig:client:leave", function(_, routeKey)
    scheduledRoutes[routeKey] = nil
    scheduledFlags[routeKey] = false
end)

---@param activeRouteKey string
local function deactivateOtherRoutes(activeRouteKey)
    for routeKey in pairs(scheduledRoutes) do
        if routeKey ~= activeRouteKey then
            scheduledRoutes[routeKey] = nil
            scheduledFlags[routeKey] = false
        end
    end
end
_G.DeactivateOtherVehicleRoutes = deactivateOtherRoutes

---@return vector3[]
local function getActiveVehiclePositions()
    local list = {}
    local instances = GetAllTrackingVehiclesInstances()
    for _, routeInstances in pairs(instances) do
        for _, instance in pairs(routeInstances) do
            if not instance.destroyed and instance.vehicle and DoesEntityExist(instance.vehicle) then
                list[#list + 1] = GetEntityCoords(instance.vehicle)
            end
        end
    end
    return list
end

local MIN_SPAWN_GAP = 6.0

local function isOccupied(coord, occupied)
    for i = 1, #occupied do
        local o = occupied[i]
        local dx = coord.x - o.x
        local dy = coord.y - o.y
        if (dx * dx + dy * dy) < (MIN_SPAWN_GAP * MIN_SPAWN_GAP) then
            return true
        end
    end
    return false
end

---@param route table
---@return vector3|nil
local function computeSpawnCoords(route)
    local explicit = route and route.radiusSpawnsCoords
    if type(explicit) == 'table' and #explicit > 0 then
        local pc = GetEntityCoords(PlayerPedId())
        local occupied = getActiveVehiclePositions()

        local farFree, anyFree = {}, {}
        for i = 1, #explicit do
            local c = explicit[i]
            if c and c.x and not isOccupied(c, occupied) then
                anyFree[#anyFree + 1] = c
                if #(vector3(c.x, c.y, c.z) - pc) >= 50.0 then
                    farFree[#farFree + 1] = c
                end
            end
        end

        if farFree[1] then
            local pick = farFree[math.random(1, #farFree)]
            return vector3(pick.x, pick.y, pick.z)
        end
        if anyFree[1] then
            local pick = anyFree[math.random(1, #anyFree)]
            return vector3(pick.x, pick.y, pick.z)
        end

        local base = explicit[math.random(1, #explicit)]
        for attempt = 1, 8 do
            local angle = math.random() * 2 * math.pi
            local dist  = 15.0 + math.random() * 25.0
            local jx = base.x + math.cos(angle) * dist
            local jy = base.y + math.sin(angle) * dist
            for nth = 1, 4 do
                local ok, nodePos = GetNthClosestVehicleNode(jx, jy, base.z, nth, 1, 3.0, 0)
                if ok and nodePos and nodePos.x and nodePos.x ~= 0 then
                    local cand = vector3(nodePos.x, nodePos.y, nodePos.z)
                    if not isOccupied(cand, occupied) then
                        return cand
                    end
                end
            end
        end
        return vector3(base.x, base.y, base.z)
    end

    local rcfg = route and route.radiusSpawnConfig
    if not (rcfg and rcfg.center) then return nil end

    local center = rcfg.center
    local radius = (tonumber(rcfg.radius) or 200.0) * 0.7
    local pc = GetEntityCoords(PlayerPedId())
    local dx, dy = center.x - pc.x, center.y - pc.y
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1.0 then
        local theta = math.random() * 2 * math.pi
        dx, dy, len = math.cos(theta), math.sin(theta), 1.0
    end
    local nx, ny = dx / len, dy / len

    local targetX = pc.x + nx * radius
    local targetY = pc.y + ny * radius
    local targetZ = center.z

    for nth = 1, 10 do
        local ok, nodePos = GetNthClosestVehicleNode(targetX, targetY, targetZ, nth, 1, 3.0, 0)
        if ok and nodePos and nodePos.x and nodePos.x ~= 0 then
            local toPlayer = #(vector3(nodePos.x, nodePos.y, nodePos.z) - pc)
            if toPlayer >= 60.0 then
                return vector3(nodePos.x, nodePos.y, nodePos.z)
            end
        end
    end
    return vector3(targetX, targetY, targetZ)
end

local VEHICLE_Z_TOLERANCE = 30.0

---@param route table
---@return boolean
local function isPlayerInsideRoute(route)
    local rcfg = route and route.radiusSpawnConfig
    if not (rcfg and rcfg.center) then return true end
    local pc = GetEntityCoords(PlayerPedId())
    local c = rcfg.center
    local r = tonumber(rcfg.radius) or 200.0
    local dx, dy = pc.x - c.x, pc.y - c.y
    if (dx * dx + dy * dy) > (r * r) then return false end
    local dz = math.abs(pc.z - c.z)
    if dz > VEHICLE_Z_TOLERANCE then return false end
    return true
end

AddEventHandler("multiTracking:reloadVehicles", function()
    for routeKey in pairs(scheduledRoutes) do
        if not scheduledFlags[routeKey] then
            local route = GetVehicleRouteByKey(routeKey)
            local segments = (route and CalculateTrackingVehiclesSegments(route.maxVehicles)) or 1
            local activeCount = countActiveOnRoute(routeKey)
            if not isPlayerInsideRoute(route) then
                scheduledRoutes[routeKey] = nil
                CleanupTrackingVehiclesInstances(routeKey)
                goto continue
            end
            if segments > activeCount and not HasLimitTrackingVehicles() then
                scheduledFlags[routeKey] = true
                Citizen.CreateThread(function()
                    local generationAtStart = resetGeneration

                    local config = GetGlobalConfigBuilder("vehicles")
                    local burstGap = (config and config.get("spawnCooldownMs")) or 500
                    burstGap = math.max(50, burstGap)
                    local burstCount = 0

                    while true do
                        local schedOK   = scheduledRoutes[routeKey] ~= nil
                        local limitOK   = not HasLimitTrackingVehicles()
                        local active    = countActiveOnRoute(routeKey)
                        local underSeg  = active < segments
                        local genOK     = resetGeneration == generationAtStart
                        local inZone    = isPlayerInsideRoute(route)
                        local pedOnly   = isInsidePedOnlyZone()

                        if not (schedOK and limitOK and underSeg and genOK and inZone) or pedOnly then
                            if pedOnly then fullVehicleCleanup() end
                            break
                        end

                        local coords
                        local rId = route and route.routeFile and route.routeFile.routeId
                        local rName = route and route.routeFile and route.routeFile.name
                        if rId and rName and HasVehicleRecordingBeenLoaded(rId, rName) then
                            local ok, rec = pcall(GetPositionOfVehicleRecordingAtTime, rId, 0.0, rName)
                            if ok and rec and rec.x then
                                coords = vector3(rec.x, rec.y, rec.z)
                            end
                        end
                        if not coords then
                            coords = computeSpawnCoords(route)
                        end

                        if coords then
                            pcall(spawnInstanceAtCoords, routeKey, 0, coords)
                        end
                        burstCount = burstCount + 1
                        Wait(burstGap)
                    end

                    scheduledFlags[routeKey] = false

                    if burstCount > 0 then
                        local config = GetGlobalConfigBuilder("vehicles")
                        local cd = (config and config.get("spawnCooldownMs")) or 500
                        Wait(math.max(50, cd))
                        if resetGeneration == generationAtStart
                            and scheduledRoutes[routeKey]
                            and not HasLimitTrackingVehicles()
                        then
                            TriggerEvent("multiTracking:reloadVehicles")
                        end
                    end
                end)
            end
        end
        ::continue::
    end
end)

AddConvarChangeListener("multiTrackingVehicleModeEnabled", function()
    vehicleModeEnabled = GetConvarBool("multiTrackingVehicleModeEnabled", true)
    if not vehicleModeEnabled then
        TriggerEvent("multiTracking:vehicle:client:spawnDisabled")
    end
end)

local pedOnlyWatcherActive = false
local pedOnlyLastState = false

local function startPedOnlyWatcher()
    if pedOnlyWatcherActive then return end
    pedOnlyWatcherActive = true
    pedOnlyLastState = false
    CreateThread(function()
        while pedOnlyWatcherActive do
            local now = isInsidePedOnlyZone()
            if now and not pedOnlyLastState then
                fullVehicleCleanup()
            end
            pedOnlyLastState = now
            Wait(1000)
        end
    end)
end

AddEventHandler("multiTracking:whenEnter", startPedOnlyWatcher)
AddEventHandler("multiTracking:whenLeave", function()
    pedOnlyWatcherActive = false
    pedOnlyLastState = false
end)
