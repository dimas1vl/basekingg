--[[ Utilitarios diversos: parse de pontos, shuffle, ponto aleatorio em
     quadrilateros (triangulo) de zona, e heading aleatorio. ]]

local function MultiTrackingParsePoint(point)
    if not point then
        return nil
    end

    local x = tonumber(point.x) or tonumber(point[1])
    local y = tonumber(point.y) or tonumber(point[2])
    local z = tonumber(point.z) or tonumber(point[3]) or 0.0

    if not x or not y then
        return nil
    end

    return vector3(x, y, z)
end
_G.MultiTrackingParsePoint = MultiTrackingParsePoint

local function MultiTrackingShuffleList(list)
    local count = #list
    if count <= 1 then
        return list
    end

    math.randomseed(GetGameTimer())
    for i = count, 2, -1 do
        local j = math.random(1, i)
        local temp = list[j]
        list[j] = list[i]
        list[i] = temp
    end
    return list
end
_G.MultiTrackingShuffleList = MultiTrackingShuffleList

local function MultiTrackingGetRandomPointInZoneQuad(zoneConfig, margin)
    local points = zoneConfig and zoneConfig.points
    local fromPoints = points and points.from
    local toPoints = points and points.to

    if not fromPoints or not toPoints then
        return nil
    end

    local origin = MultiTrackingParsePoint(fromPoints[1])
    local sideA = MultiTrackingParsePoint(fromPoints[2])
    local sideB = MultiTrackingParsePoint(toPoints[2])

    if not (origin and sideA) or not sideB then
        return nil
    end

    local edgeA = vector3(sideA.x - origin.x, sideA.y - origin.y, sideA.z - origin.z)
    local edgeB = vector3(sideB.x - origin.x, sideB.y - origin.y, sideB.z - origin.z)

    local lenA = #edgeA
    local lenB = #edgeB

    if lenA <= 0.0 or lenB <= 0.0 then
        return nil
    end

    local marginValue = tonumber(margin) or 0.0
    local minOffsetA = math.min(0.49, marginValue / lenA)
    local minOffsetB = math.min(0.49, marginValue / lenB)

    math.randomseed(GetGameTimer())
    local u = minOffsetA + (1.0 - minOffsetA * 2.0) * math.random()
    local v = minOffsetB + (1.0 - minOffsetB * 2.0) * math.random()

    local x = origin.x + (sideA.x - origin.x) * u + (sideB.x - origin.x) * v
    local y = origin.y + (sideA.y - origin.y) * u + (sideB.y - origin.y) * v
    local z = origin.z + (sideA.z - origin.z) * u + (sideB.z - origin.z) * v

    return vector3(x, y, z)
end
_G.MultiTrackingGetRandomPointInZoneQuad = MultiTrackingGetRandomPointInZoneQuad

local function MultiTrackingGetSpawnHeading(spawnConfig)
    local heading = tonumber(spawnConfig and spawnConfig.heading)
    if heading then
        return heading + 0.0
    end

    math.randomseed(GetGameTimer())
    return math.random(0, 359) + 0.0
end
_G.MultiTrackingGetSpawnHeading = MultiTrackingGetSpawnHeading
