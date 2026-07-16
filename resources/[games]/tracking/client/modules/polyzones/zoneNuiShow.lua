--[[ Polyzones que disparam NUI show ao entrar/sair. Cobre zoneNuiShow das
     rotas, dos modos e das spawn zones. Permite consultar zonas atuais. ]]

local nuiZones = {}
local nuiZonesData = {}

local function RegisterNuiShowZone(zoneIndex, shape, routeKey, label)
    if type(zoneIndex) ~= "string" then
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

    if nuiZones[zoneIndex] then
        return nuiZones[zoneIndex]
    end

    local CircleZoneLib = rawget(_G, "CircleZone")
    if not (CircleZoneLib and CircleZoneLib.Create) then
        return nil
    end

    local zone = CircleZoneLib:Create(center, radius, {
        name = zoneIndex,
        debugPoly = MultiTrackingActiveDebug,
        useZ = true,
        debugColor = {204, 52, 41},
    })

    if not zone then
        return nil
    end

    local resolvedRouteKey = routeKey or "NONE"

    zone:onPlayerInOut(function(playerInside)
        if playerInside then
            TriggerEvent("multiTracking:zone:client:enter", zoneIndex, "zoneNuiShow", resolvedRouteKey)
            return true
        end
        TriggerEvent("multiTracking:zone:client:leave", zoneIndex, "zoneNuiShow", resolvedRouteKey)
    end, 60)

    nuiZones[zoneIndex] = zone
    nuiZonesData[zoneIndex] = {
        routeKey = routeKey,
        label = label,
        center = center,
        radius = radius,
    }
    return zone
end

local function RegisterNuiShowFromZoneConfig(zoneConfig, zoneId)
    local routeKey = GetCirclezoneRouteKey(zoneConfig, zoneId)
    if not routeKey then
        return nil
    end

    local nuiShow = zoneConfig and zoneConfig.zoneNuiShow
    if not nuiShow then
        return nil
    end

    local label = zoneConfig and zoneConfig.label
    return RegisterNuiShowZone(routeKey .. ":zoneNuiShow", nuiShow, zoneId, label)
end

local function RegisterAllVehicleRouteNuiShow()
    local modeConfig = MultitrackingModeVehicleRoutes or {}
    local routes = (modeConfig and modeConfig.routes) or {}

    for routeId, routeData in pairs(routes) do
        RegisterNuiShowFromZoneConfig(routeData, routeId)
    end
end

local function RegisterAllCategoriesNuiShow()
    local categories = GetCategoriesModesConfig() or {}

    for modeId, modeData in pairs(categories) do
        if type(modeData) == "table" then
            local zones = modeData and modeData.zones
            if type(zones) == "table" then
                for zoneId, zoneData in pairs(zones) do
                    if zoneData and zoneData.zoneNuiShow then
                        local indexKey = GetModeZoneIndex(modeId, zoneId, "zoneNuiShow")
                        local routeKey = string.format("%s:%s", modeId, zoneId)
                        RegisterNuiShowZone(indexKey, zoneData.zoneNuiShow, routeKey, zoneData.label)
                    end
                end
            end
        end
    end
end

local function RegisterAllSpawnZonesNuiShow()
    local spawnZones = MultitrackingSpawnZones or {}

    for _, spawnZone in pairs(spawnZones) do
        if type(spawnZone) == "table" then
            local name = tostring(spawnZone.name or "")
            local center = MultiTrackingParsePoint(spawnZone.centerZoneCds)
            local radius = tonumber(spawnZone.radius)

            if name ~= "" and center and radius and radius > 0.0 then
                local indexKey = string.format("spawn:%s", name)
                RegisterNuiShowZone(indexKey, {
                    center = center,
                    radius = radius,
                }, name, spawnZone.label)
            end
        end
    end
end

local function GetZoneNuiShowPolyzonesPlayerInside()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local insideZones = {}

    for zoneIndex, zone in pairs(nuiZones) do
        if zone and zone.isPointInside and zone:isPointInside(playerCoords) then
            local zoneData = nuiZonesData[zoneIndex] or {}
            local center = zoneData.center
            local distance = nil

            if center then
                local playerVec = vector3(playerCoords.x, playerCoords.y, playerCoords.z)
                local centerVec = vector3(center.x, center.y, center.z)
                distance = #(playerVec - centerVec)
            end

            insideZones[#insideZones + 1] = {
                zoneIndex = zoneIndex,
                zoneType = "zoneNuiShow",
                routeKey = zoneData.routeKey,
                label = zoneData.label,
                center = center,
                radius = zoneData.radius,
                circlezone = zone,
                distance = distance,
            }
        end
    end

    return insideZones
end
_G.GetZoneNuiShowPolyzonesPlayerInside = GetZoneNuiShowPolyzonesPlayerInside

local function DestroyAllNuiShowZones()
    for _, zone in pairs(nuiZones) do
        if zone and zone.destroy then
            zone:destroy()
        end
    end
    nuiZones = {}
    nuiZonesData = {}
end

AddEventHandler("multiTracking:whenEnter", function()
    RegisterAllVehicleRouteNuiShow()
    RegisterAllCategoriesNuiShow()
    RegisterAllSpawnZonesNuiShow()
end)

AddEventHandler("multiTracking:whenLeave", DestroyAllNuiShowZones)
