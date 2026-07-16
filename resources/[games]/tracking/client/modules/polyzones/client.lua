--[[ Camada de PolyZone (CircleZone) para zonas de tracking. Cria, cacheia,
     consulta se player esta dentro e limpa ao sair do modo. ]]

local trackingCircleZones = {}
local CircleZoneLib = rawget(_G, "CircleZone")

local function ParseZoneShape(rawConfig)
    if type(rawConfig) ~= "table" then
        return nil
    end

    local center = MultiTrackingParsePoint(rawConfig.center)
    local radius = tonumber(rawConfig.radius)
    if not (center and radius) or radius <= 0.0 then
        return nil
    end

    return {
        center = center,
        radius = radius,
    }
end

local function GetZoneShapeFromConfig(zoneConfig)
    if type(zoneConfig) ~= "table" then
        return nil
    end

    local raw = zoneConfig.zoneConfig or zoneConfig.radiusSpawnConfig
    return ParseZoneShape(raw)
end

local function CreateTrackingCirclezone(zoneName, zoneData)
    if type(zoneName) ~= "string" then
        return nil
    end
    if type(zoneData) ~= "table" then
        return nil
    end

    local center = MultiTrackingParsePoint(zoneData.cds)
    local radius = tonumber(zoneData.radius)
    if not (center and radius) or radius <= 0.0 then
        return nil
    end

    if trackingCircleZones[zoneName] then
        return trackingCircleZones[zoneName]
    end

    if not (CircleZoneLib and CircleZoneLib.Create) then
        return nil
    end

    local zone = CircleZoneLib:Create(center, radius, {
        name = zoneName,
        debugPoly = MultiTrackingActiveDebug,
        useZ = true,
    })

    if not zone then
        return nil
    end

    trackingCircleZones[zoneName] = zone
    return zone
end
_G.CreateTrackingCirclezone = CreateTrackingCirclezone

local function GetCirclezoneRouteKey(zoneConfig, zoneId)
    local shape = GetZoneShapeFromConfig(zoneConfig)
    if not shape then
        return nil
    end

    local key = zoneId or (zoneConfig and zoneConfig.label)
        or (shape.center.x .. "_" .. shape.center.y .. "_" .. shape.radius)
    return tostring(key)
end
_G.GetCirclezoneRouteKey = GetCirclezoneRouteKey

local function GetTrackingCircleZoneForConfig(zoneConfig, zoneId)
    if GetRadiusSpawnConfigRouteZone then
        local zone = GetRadiusSpawnConfigRouteZone(zoneConfig, zoneId)
        if zone then
            return zone
        end
    end

    local key = GetCirclezoneRouteKey(zoneConfig, zoneId)
    if not key then
        return nil
    end
    return trackingCircleZones[key]
end

local function IsInsideRoute(zoneConfig, zoneId)
    local shape = GetZoneShapeFromConfig(zoneConfig)
    if not shape then
        return true
    end

    local zone = GetTrackingCircleZoneForConfig(zoneConfig, zoneId)
    if zone and zone.isPointInside then
        local playerCoords = GetEntityCoords(PlayerPedId())
        return zone:isPointInside(playerCoords)
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local centerVec = vector3(shape.center.x, shape.center.y, shape.center.z)
    local playerVec = vector3(playerCoords.x, playerCoords.y, playerCoords.z)
    return #(playerVec - centerVec) <= shape.radius
end
_G.IsInsideRoute = IsInsideRoute

local function GetModeZoneIndex(modeId, zoneId, kind)
    return string.format("%s:%s:%s", modeId, zoneId, kind)
end
_G.GetModeZoneIndex = GetModeZoneIndex

AddEventHandler("multiTracking:whenLeave", function()
    for _, zone in pairs(trackingCircleZones) do
        if zone and zone.destroy then
            zone:destroy()
        end
    end
    trackingCircleZones = {}
end)
