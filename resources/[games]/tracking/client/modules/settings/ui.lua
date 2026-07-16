--[[ Indexa zonas de spawn (com radiusSpawnConfig) por categoria,
     e expoe GetNearestZoneLabel(coords) -> category mais proxima
     considerando o raio de cada zona. ]]

local indexedZones = {}

local function BuildZoneIndex()
    indexedZones = {}

    local categories = GetCategoriesModesConfig()
    if not categories then
        categories = {}
    end

    for _, categoryData in pairs(categories) do
        if "table" == type(categoryData) then
            local menuCategory = categoryData.menuCategory
            if menuCategory then
                for _, modeData in pairs(categoryData) do
                    if "table" == type(modeData) then
                        for _, zone in pairs(modeData) do
                            if "table" == type(zone) then
                                local radiusSpawnConfig = zone.radiusSpawnConfig
                                if radiusSpawnConfig then
                                    local center = MultiTrackingParsePoint(radiusSpawnConfig.center)
                                    if center then
                                        local idx = #indexedZones + 1
                                        indexedZones[idx] = {
                                            center = center,
                                            zone = zone,
                                            category = menuCategory,
                                        }
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

Citizen.CreateThread(function()
    BuildZoneIndex()
end)

local function IsPointInsideZoneRadius(coords, zone)
    if not zone then
        return false
    end

    local radiusSpawnConfig = zone.radiusSpawnConfig
    if not radiusSpawnConfig or not radiusSpawnConfig.center then
        return false
    end

    local center = MultiTrackingParsePoint(radiusSpawnConfig.center)
    local radius = tonumber(radiusSpawnConfig.radius)
    if not radius then
        radius = 0.0
    end

    if not center or radius <= 0.0 then
        return false
    end

    local distance = #(coords - center)
    return radius >= distance
end

local function GetNearestZoneLabel(coords)
    if 0 == #indexedZones then
        return nil
    end

    local nearestCategory = nil
    local nearestDistance = math.huge

    for i = 1, #indexedZones do
        local entry = indexedZones[i]
        if IsPointInsideZoneRadius(coords, entry.zone) then
            local distance = #(coords - entry.center)
            if nearestDistance > distance then
                nearestDistance = distance
                nearestCategory = entry.category
            end
        end
    end

    return nearestCategory
end

_G.GetNearestZoneLabel = GetNearestZoneLabel
