--[[ Cache de instancias de TrackingVehiclesClass agrupadas por rota. ]]

local idCounter = 0
local instancesByRoute = {}

local function nextInstanceId()
    idCounter = idCounter + 1
    if idCounter > 1000000 then
        idCounter = 1
    end
    return idCounter
end

local function GetAllTrackingVehiclesInstances()
    return instancesByRoute
end

_G.GetAllTrackingVehiclesInstances = GetAllTrackingVehiclesInstances

local function CreateNoCachedTrackingVehiclesInstance(routeKey)
    local route = GetVehicleRouteByKey(routeKey)
    if not route then
        return nil
    end
    local routeId = route.routeFile and route.routeFile.routeId
    local routeName = route.routeFile and route.routeFile.name
    local instance = TrackingVehiclesClass:new(routeId, routeName, route.vehicleModel, route.vehicleConfig)
    instance.baseMultiplierVelocity = tonumber(route.baseMultiplierVelocity) or 1.0
    return instance
end

_G.CreateNoCachedTrackingVehiclesInstance = CreateNoCachedTrackingVehiclesInstance

local function CleanupTrackingVehiclesInstances(routeKey)
    if not routeKey then
        return
    end
    local routeInstances = instancesByRoute[routeKey]
    if not routeInstances then
        return
    end
    for _, instance in pairs(routeInstances) do
        if instance and not instance.destroyed then
            instance:destroy()
        end
    end
    instancesByRoute[routeKey] = nil
end

_G.CleanupTrackingVehiclesInstances = CleanupTrackingVehiclesInstances

local function CreateNewTrackingVehiclesInstance(routeKey)
    if not routeKey or type(routeKey) ~= "string" then
        return nil
    end
    local instance = CreateNoCachedTrackingVehiclesInstance(routeKey)
    if not instance then
        return nil
    end
    instancesByRoute[routeKey] = instancesByRoute[routeKey] or {}
    local instanceKey = tostring(nextInstanceId())
    instancesByRoute[routeKey][instanceKey] = instance
    return instance, instanceKey
end

_G.CreateNewTrackingVehiclesInstance = CreateNewTrackingVehiclesInstance
