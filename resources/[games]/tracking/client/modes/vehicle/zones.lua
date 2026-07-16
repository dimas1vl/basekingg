--[[ Listeners de entrada/saída das zonas de spawn de veículos do tracking. ]]

---@param routeKey string
---@return table|nil
local function GetVehicleRouteByKey(routeKey)
    if not routeKey or type(routeKey) ~= "string" then return nil end
    local routes = (MultitrackingModeVehicleRoutes or {}).routes or {}
    return routes[routeKey]
end
_G.GetVehicleRouteByKey = GetVehicleRouteByKey

---@return string[]
local function GetVehicleEligibleRoutes()
    local routes = (MultitrackingModeVehicleRoutes or {}).routes or {}
    local eligible = {}
    local pc = GetEntityCoords(PlayerPedId())
    for routeKey, route in pairs(routes) do
        local rcfg = route and route.radiusSpawnConfig
        if rcfg and rcfg.center then
            local c = rcfg.center
            local r = tonumber(rcfg.radius) or 200.0
            local dx, dy = pc.x - c.x, pc.y - c.y
            if (dx * dx + dy * dy) <= (r * r) then
                eligible[#eligible + 1] = routeKey
            end
        end
    end
    return eligible
end
_G.GetVehicleEligibleRoutes = GetVehicleEligibleRoutes

AddEventHandler("multiTracking:radiusSpawnConfig:client:enter", function(_, routeKey)
    if not routeKey or type(routeKey) ~= "string" then return end
    local route = GetVehicleRouteByKey(routeKey)
    if not route then return end

    local rcfg = route.radiusSpawnConfig
    if rcfg and rcfg.center then
        local pc = GetEntityCoords(PlayerPedId())
        if math.abs(pc.z - rcfg.center.z) > 30.0 then return end
    end

    if DeactivateOtherVehicleRoutes then DeactivateOtherVehicleRoutes(routeKey) end
    local instances = GetAllTrackingVehiclesInstances and GetAllTrackingVehiclesInstances() or {}
    for otherKey, _ in pairs(instances) do
        if otherKey ~= routeKey then
            CleanupTrackingVehiclesInstances(otherKey)
        end
    end
    local segments = CalculateTrackingVehiclesSegments(route.maxVehicles)
    SpawnVehiclesBySegments(segments, routeKey)
end)

AddEventHandler("multiTracking:radiusSpawnConfig:client:leave", function(_, routeKey)
    CleanupTrackingVehiclesInstances(routeKey)
end)

AddEventHandler("multiTracking:whenLeave", function()
    TriggerEvent("multiTracking:vehicle:client:spawnDisabled")
end)
