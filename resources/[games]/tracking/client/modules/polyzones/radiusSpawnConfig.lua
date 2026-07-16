--[[ Cria CircleZones para spawn radius dos modos/rotas e dispara eventos
     enter/leave por zona. Limpa todas ao sair do modo de tracking. ]]

local routeZones = {}
local destroyedRouteZones = {}
local ENTER_EVENT = "multiTracking:radiusSpawnConfig:client:enter"
local LEAVE_EVENT = "multiTracking:radiusSpawnConfig:client:leave"

local function RegisterRouteCircleZone(routeKey, shape, zoneId)
    if type(routeKey) ~= "string" then
        return nil
    end
    if type(shape) ~= "table" then
        return nil
    end

    local center = MultiTrackingParsePoint(shape.center)
    local radius = tonumber(shape.radius)
    if not (center and radius) or radius <= 0.0 then
        return nil
    end

    if routeZones[routeKey] then
        return routeZones[routeKey]
    end

    local CircleZoneLib = rawget(_G, "CircleZone")
    if not (CircleZoneLib and CircleZoneLib.Create) then
        return nil
    end

    local zone = CircleZoneLib:Create(center, radius, {
        name = routeKey,
        debugPoly = MultiTrackingActiveDebug,
        useZ = true,
    })

    if not zone then
        return nil
    end

    local resolvedZoneId = zoneId or "NONE"
    local isInside = false
    destroyedRouteZones[routeKey] = false

    zone:onPlayerInOut(function(playerInside)
        if destroyedRouteZones[routeKey] then
            return
        end
        if playerInside == isInside then
            return
        end
        isInside = playerInside
        if playerInside then
            TriggerEvent(ENTER_EVENT, routeKey, resolvedZoneId)
        else
            TriggerEvent(LEAVE_EVENT, routeKey, resolvedZoneId)
        end
    end, 60)

    routeZones[routeKey] = zone
    return zone
end

local function RegisterRouteFromZoneConfig(zoneConfig, zoneId)
    local raw = zoneConfig and (zoneConfig.zoneConfig or zoneConfig.radiusSpawnConfig)
    if not raw then
        return nil
    end

    local routeKey = GetCirclezoneRouteKey(zoneConfig, zoneId)
    if not routeKey then
        return nil
    end

    return RegisterRouteCircleZone(routeKey, raw, zoneId)
end

local function RegisterAllVehicleRoutes()
    local modeConfig = MultitrackingModeVehicleRoutes or {}
    local routes = (modeConfig and modeConfig.routes) or {}

    for routeId, routeData in pairs(routes) do
        RegisterRouteFromZoneConfig(routeData, routeId)
    end
end

local function RegisterAllCategoriesModeZones()
    local categories = GetCategoriesModesConfig() or {}

    for modeId, modeData in pairs(categories) do
        if type(modeData) == "table" then
            local zones = (modeData and modeData.zones)
            if type(zones) == "table" then
                for zoneId, zoneData in pairs(zones) do
                    local raw = zoneData and (zoneData.zoneConfig or zoneData.radiusSpawnConfig)
                    if raw then
                        local indexKey = GetModeZoneIndex(modeId, zoneId, "range")
                        RegisterRouteCircleZone(indexKey, raw, zoneId)
                    end
                end
            end
        end
    end
end

local function GetRadiusSpawnConfigRouteZone(zoneConfig, zoneId)
    local routeKey = GetCirclezoneRouteKey(zoneConfig, zoneId)
    if not routeKey then
        return nil
    end
    return routeZones[routeKey]
end
_G.GetRadiusSpawnConfigRouteZone = GetRadiusSpawnConfigRouteZone

local function DestroyAllRouteZones()
    for routeKey, zone in pairs(routeZones) do
        destroyedRouteZones[routeKey] = true
        if zone and zone.destroy then
            zone:destroy()
        end
    end
    routeZones = {}
    destroyedRouteZones = {}
end

AddEventHandler("multiTracking:whenEnter", function()
    RegisterAllVehicleRoutes()
    RegisterAllCategoriesModeZones()
end)

AddEventHandler("multiTracking:whenLeave", DestroyAllRouteZones)
