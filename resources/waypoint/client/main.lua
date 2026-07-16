local Waypoint = require 'client.modules.waypoint'
local config = require 'config'

local resourceName = GetCurrentResourceName()

local function formatMessage(...)
    local parts = {}

    for index = 1, select('#', ...) do
        parts[index] = tostring(select(index, ...))
    end

    return table.concat(parts, ' ')
end

local function debugPrint(...)
    if GetConvarInt(('%s_debug'):format(resourceName), 0) ~= 1 then
        return
    end

    print(('[%s] %s'):format(resourceName, formatMessage(...)))
end

local function notify(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

-------------------------------------------------
-- Main Render Loops
-------------------------------------------------
local shouldRender = {}
local currentlyRendering = {}
local drawRunning = false
local playerPositionMarker = nil
local mapPositionMarker = nil

local function removeTrackedMarker(id)
    if id then
        Waypoint.remove(id)
    end

    return nil
end

local function createCommandWaypoint(position, label)
    return Waypoint.create({
        coords = position,
        type = 'checkpoint',
        label = label,
        color = config.mapWaypoint.color,
        size = config.mapWaypoint.size,
        fadeDistance = config.defaults.fadeDistance,
        groundZ = position.z - 1.0,
        minHeight = config.defaults.minHeight,
        maxHeight = config.defaults.maxHeight,
        displayDistance = true,
    })
end

local function drawLoop()
    if drawRunning then return end
    drawRunning = true

    CreateThread(function()
        while #shouldRender > 0 do
            local camPos = GetFinalRenderedCamCoord()
            local playerPos = GetEntityCoords(PlayerPedId())

            for i = 1, #shouldRender do
                local waypoint = shouldRender[i]
                Waypoint.render(waypoint, camPos, playerPos)
            end

            Wait(0)
        end

        drawRunning = false
    end)
end

local currentWayPointMarker = nil
CreateThread(function()
    while true do
        if config.syncToWayPoint then
            if not currentWayPointMarker and IsWaypointActive() then
                local blipCoord = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))

                currentWayPointMarker = Waypoint.create({
                    coords = blipCoord,
                    type = config.mapWaypoint.type,
                    label = config.mapWaypoint.label,
                    color = config.mapWaypoint.color,
                    size = config.mapWaypoint.size,
                })
            elseif not IsWaypointActive() and currentWayPointMarker then
                Waypoint.remove(currentWayPointMarker)
                currentWayPointMarker = nil
            end
        end


        local newShouldRender = {}
        local newCurrentlyRendering = {}
        local camPos = GetFinalRenderedCamCoord()

        local waypointArray = Waypoint.getArray()

        for i = 1, #waypointArray do
            local waypoint = waypointArray[i]
            if Waypoint.shouldRender(waypoint, camPos) then

                if not waypoint.isRendering then
                    Waypoint.acquireForRendering(waypoint)
                end

                if waypoint.isRendering then
                    newShouldRender[#newShouldRender + 1] = waypoint
                    newCurrentlyRendering[waypoint.id] = true
                end
            end
        end

        local releasedCount = 0
        for id, _ in pairs(currentlyRendering) do
            if not newCurrentlyRendering[id] then
                local waypoint = Waypoint.get(id)
                if waypoint then
                    Waypoint.releaseFromRendering(waypoint)
                    releasedCount = releasedCount + 1
                end
            end
        end

        local prevCount = #shouldRender
        if #newShouldRender ~= prevCount or releasedCount > 0 then
            debugPrint(('[RENDER LOOP] Visible: %d | Released: %d | Total waypoints: %d'):format(
                #newShouldRender,
                releasedCount,
                #waypointArray
            ))
        end

        shouldRender = newShouldRender
        currentlyRendering = newCurrentlyRendering

        if #shouldRender > 0 and not drawRunning then
            drawLoop()
        end

        Wait(config.rendering.updateInterval)
    end
end)

RegisterCommand('wp', function()
    local coords = GetEntityCoords(PlayerPedId())

    playerPositionMarker = removeTrackedMarker(playerPositionMarker)
    playerPositionMarker = createCommandWaypoint(coords, 'DISTANCIA')

    notify('Waypoint criado na sua posicao.')
end, false)

RegisterCommand('wp2', function()
    if not IsWaypointActive() then
        notify('Marque um waypoint no mapa antes de usar /wp2.')
        return
    end

    local coords = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))

    mapPositionMarker = removeTrackedMarker(mapPositionMarker)
    mapPositionMarker = createCommandWaypoint(coords, 'DISTANCIA')

    notify('Waypoint criado na marcacao do mapa.')
end, false)

-------------------------------------------------
-- Exports
-------------------------------------------------
exports('create', Waypoint.create)
exports('update', Waypoint.update)
exports('remove', Waypoint.remove)
exports('removeAll', Waypoint.removeAll)
exports('get', Waypoint.get)
exports('setHoldProgress', Waypoint.setHoldProgress)

-------------------------------------------------
-- Server Event Handlers
-------------------------------------------------

-- Maps server waypoint IDs to client waypoint IDs
local serverToClientId = {}

RegisterNetEvent('sleepless_waypoints:create', function(serverId, data)
    local clientId = Waypoint.create(data)
    serverToClientId[serverId] = clientId
end)

RegisterNetEvent('sleepless_waypoints:update', function(serverId, data)
    local clientId = serverToClientId[serverId]
    if clientId then
        Waypoint.update(clientId, data)
    end
end)

RegisterNetEvent('sleepless_waypoints:remove', function(serverId)
    local clientId = serverToClientId[serverId]
    if clientId then
        Waypoint.remove(clientId)
        serverToClientId[serverId] = nil
    end
end)

RegisterNetEvent('sleepless_waypoints:removeAll', function()
    Waypoint.removeAll()
    serverToClientId = {}
end)

-------------------------------------------------
-- Cleanup
-------------------------------------------------
AddEventHandler('onResourceStop', function(resource)
    if resource == resourceName then
        playerPositionMarker = removeTrackedMarker(playerPositionMarker)
        mapPositionMarker = removeTrackedMarker(mapPositionMarker)
        Waypoint.removeAll()
    end
end)
