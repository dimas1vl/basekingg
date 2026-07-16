--[[ Helpers de geometria para zonas: triangle hit-test e checagem
     se o player esta dentro da zona configurada (circular ou polygonal). ]]

local function TriangleSign(p1, p2, p3)
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
end

local function IsPointInTriangle(p, a, b, c)
    local d1 = TriangleSign(p, a, b)
    local d2 = TriangleSign(p, b, c)
    local d3 = TriangleSign(p, c, a)
    local hasNeg = d1 < 0.0 or d2 < 0.0 or d3 < 0.0
    local hasPos = d1 > 0.0 or d2 > 0.0 or d3 > 0.0
    return not (hasNeg and hasPos)
end
_G.IsPointInTriangle = IsPointInTriangle

local function MultiTrackingIsPlayerInsideZoneConfig(zoneConfig, zoneId)
    local radiusSpawnConfig = zoneConfig and zoneConfig.radiusSpawnConfig
    if not radiusSpawnConfig then
        return true
    end

    local center = MultiTrackingParsePoint(radiusSpawnConfig.center)
    local radius = tonumber(radiusSpawnConfig.radius)
    if not (center and radius) or radius <= 0.0 then
        return true
    end

    local zoneName = zoneId
    if not zoneName then
        zoneName = zoneConfig.key or zoneConfig.label or zoneConfig.name
            or string.format("%s_%s_%s", center.x, center.y, radius)
    end

    local circleZone = CreateTrackingCirclezone(zoneName, {
        cds = center,
        radius = radius,
    })

    if circleZone and circleZone.isPointInside then
        local playerCoords = GetEntityCoords(PlayerPedId())
        return circleZone:isPointInside(playerCoords)
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z)
        - vector3(center.x, center.y, center.z))
    return radius >= distance
end
_G.MultiTrackingIsPlayerInsideZoneConfig = MultiTrackingIsPlayerInsideZoneConfig
