--[[ Interface client: gerencia o rodape (footer controller) que exibe
     o spawn / rota mais proxima dentro do modo MultiTracking. ]]

local currentSpawns = {}
local currentIndex = 1

local function getRouteConfig(routeKey)
    local cfg = MultitrackingModeVehicleRoutes or {}
    local routes = cfg and cfg.routes
    if not routes then routes = {} end
    return routes[routeKey]
end

local function resolveSpawnLabel(spawn)
    local routeKey = spawn and spawn.routeKey
    local label = spawn and spawn.label

    if type(label) == "string" and label ~= "" then
        return label
    end

    local route = getRouteConfig(routeKey)
    if route and type(route.label) == "string" and route.label ~= "" then
        return route.label
    end

    return tostring(routeKey or "")
end

local function refreshFooter(keepIndex)
    local insideZones = (GetZoneNuiShowPolyzonesPlayerInside and GetZoneNuiShowPolyzonesPlayerInside()) or {}

    local bestByRoute = {}
    for _, zone in ipairs(insideZones) do
        if zone and zone.routeKey and zone.routeKey ~= "NONE" then
            local routeId = zone.zoneIndex or zone.routeKey
            local distance = tonumber(zone.distance) or 999999.0
            local existing = bestByRoute[routeId]
            if not existing or distance < existing.distance then
                bestByRoute[routeId] = {
                    routeId = routeId,
                    routeKey = zone.routeKey,
                    label = zone.label,
                    distance = distance,
                }
            end
        end
    end

    local sortedSpawns = {}
    for _, entry in pairs(bestByRoute) do
        sortedSpawns[#sortedSpawns + 1] = entry
    end
    table.sort(sortedSpawns, function(a, b)
        return a.distance < b.distance
    end)

    currentSpawns = {}
    for _, entry in ipairs(sortedSpawns) do
        currentSpawns[#currentSpawns + 1] = entry
    end

    if #currentSpawns <= 0 then
        currentIndex = 1
        SendFooterControllerMessage(false, "")
        return
    end

    if not keepIndex then
        currentIndex = 1
    end
    if currentIndex > #currentSpawns then
        currentIndex = 1
    end
    if currentIndex < 1 then
        currentIndex = #currentSpawns
    end

    local current = currentSpawns[currentIndex]
    SendFooterControllerMessage(true, resolveSpawnLabel(current))
end

AddEventHandler("multiTracking:zone:client:enter", function(_, kind)
    if kind ~= "zoneNuiShow" then return end
    refreshFooter(false)
end)

AddEventHandler("multiTracking:zone:client:leave", function(_, kind)
    if kind ~= "zoneNuiShow" then return end
    refreshFooter(false)
end)

AddEventHandler("multiTracking:whenEnter", function()
    refreshFooter(false)
end)

AddEventHandler("multiTracking:whenLeave", function()
    refreshFooter(false)
    Wait(1000)
    refreshFooter(false)
end)
