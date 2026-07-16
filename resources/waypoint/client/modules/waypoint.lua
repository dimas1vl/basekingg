local utils = require 'client.modules.utils'
local Dui = require 'client.modules.dui'
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

local function errorPrint(...)
    print(('^1[%s]^7 %s'):format(resourceName, formatMessage(...)))
end

---@class WaypointManager
local WaypointManager = {}

---@type table<number, WaypointInstance>
local waypointsById = {}
local idToIndex = {} -- maps waypoint id -> array index
local waypointArray = {}
local waypointId = 0

-- DUI Pool Management
local poolAvailable = {}
local poolInUse = {}
local poolNextId = 0
local waitingForDuiLoad = {}
local lineGradientDui = Dui.new({
    url = ('nui://%s/web/line_gradient.html'):format(resourceName),
    width = 64,
    height = 2048,
})


RegisterNUICallback('load', function(data, cb)
    local id = tonumber(data.id)
    waitingForDuiLoad[id] = nil
    cb({})
end)

--- Creates a new DUI instance
---@param id number The ID to use for this DUI
---@return table duiInstance The created DUI wrapper
local function createDui(id)
    local dui = Dui.new({
        url = ('nui://%s/web/index.html'):format(resourceName),
        width = config.dui.width,
        height = config.dui.height,
    })

    waitingForDuiLoad[id] = true

    while waitingForDuiLoad[id] do
        dui:sendMessage({ action = 'load', id = id })
        Wait(100)
    end

    return {
        id = id,
        dui = dui,
    }
end

--- Resets a DUI to its default state for reuse
---@param duiWrapper table The DUI wrapper to reset
local function resetDui(duiWrapper)
    local dui = duiWrapper.dui
    dui:sendMessage({ action = 'reset' })
end

--- Prints current pool status for debugging
local function debugPoolStatus(context)
    local inUseCount = 0
    for _ in pairs(poolInUse) do inUseCount = inUseCount + 1 end
    debugPrint(('[POOL STATUS] %s - In Use: %d | Available: %d | Total Created: %d'):format(
        context or 'Status',
        inUseCount,
        #poolAvailable,
        poolNextId
    ))
end

--- Acquire a DUI from the pool (creates new one if pool is empty)
---@return table duiWrapper The acquired DUI wrapper
---@return number id The ID of the acquired DUI
local function acquireDui()
    if #poolAvailable > 0 then
        local duiWrapper = table.remove(poolAvailable)
        poolInUse[duiWrapper.id] = duiWrapper
        debugPrint(('[POOL] Reusing DUI #%d from pool'):format(duiWrapper.id))
        debugPoolStatus('After Acquire (reused)')
        return duiWrapper, duiWrapper.id
    end

    poolNextId = poolNextId + 1
    local id = poolNextId
    local duiWrapper = createDui(id)
    poolInUse[id] = duiWrapper

    debugPrint(('[POOL] Created NEW DUI #%d (pool was empty)'):format(id))
    debugPoolStatus('After Acquire (new)')
    return duiWrapper, id
end

---@param id number The ID of the DUI to release
local function releaseDui(id)
    local duiWrapper = poolInUse[id]
    if not duiWrapper then
        debugPrint(('[POOL] WARNING: Attempted to release unknown DUI #%d'):format(id))
        return
    end

    poolInUse[id] = nil

    resetDui(duiWrapper)
    poolAvailable[#poolAvailable + 1] = duiWrapper
    debugPrint(('[POOL] Released DUI #%d back to pool'):format(id))
    debugPoolStatus('After Release')
end

--- Cleanup all DUIs (call on resource stop)
local function cleanupPool()
    debugPrint('Cleaning up DUI pool...')

    for id, duiWrapper in pairs(poolInUse) do
        duiWrapper.dui:remove()
    end
    poolInUse = {}

    for _, duiWrapper in ipairs(poolAvailable) do
        duiWrapper.dui:remove()
    end
    poolAvailable = {}

    if lineGradientDui then
        lineGradientDui:remove()
        lineGradientDui = nil
    end

    debugPrint('DUI pool cleanup complete')
end

print('Sleepless Waypoints - Client started')

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        cleanupPool()
    end
end)

--- Configures a DUI with waypoint data
---@param dui table The DUI object
---@param data table The waypoint data
local function configureDui(dui, data)
    dui:sendMessage({ action = 'setType', type = data.type })

    if data.type == 'interaction' then
        dui:sendMessage({
            action = 'setInteraction',
            key = data.key or 'E',
            actionText = data.action or '',
            detail = data.detail or '',
            detailValue = data.detailValue or '',
        })
        return
    end

    dui:sendMessage({ action = 'setColor', color = data.color })
    dui:sendMessage({ action = 'setLabel', text = data.label })
    dui:sendMessage({ action = 'showDistance', show = data.displayDistance })

    if data.icon then
        dui:sendMessage({ action = 'setIcon', icon = data.icon, iconColor = data.iconColor })
    end

    if data.image then
        dui:sendMessage({ action = 'setImage', url = data.image })
    end
end

function WaypointManager.create(data)
    waypointId = waypointId + 1
    local id = waypointId

    local waypointType = data.type or 'small'
    local isInteraction = waypointType == 'interaction'
    local ictx = config.interaction or {}

    if data.displayDistance == nil then
        data.displayDistance = not isInteraction
    end

    local drawDist = data.drawDistance or (isInteraction and ictx.drawDistance or config.defaults.drawDistance)
    local fadeDist = data.fadeDistance or config.defaults.fadeDistance
    local removeDist = data.removeDistance

    local waypoint = {
        id = id,
        data = {
            coords = data.coords,
            type = waypointType,
            color = data.color or config.defaults.color,
            label = data.label or config.defaults.label,
            icon = data.icon,
            iconColor = data.iconColor,
            image = data.image,
            size = data.size or config.defaults.size,
            drawDistance = drawDist,
            drawDistanceSq = drawDist * drawDist,
            fadeDistance = fadeDist,
            fadeDistanceSq = fadeDist * fadeDist,
            minHeight = data.minHeight or config.defaults.minHeight,
            maxHeight = data.maxHeight or config.defaults.maxHeight,
            groundZ = data.groundZ or (data.coords.z + config.defaults.groundZOffset),
            labelZ = data.labelZ,
            removeDistance = removeDist,
            removeDistanceSq = removeDist and (removeDist * removeDist) or nil,
            displayDistance = data.displayDistance,
            -- Interaction-specific
            drawLine = data.drawLine,
            zOffset = data.zOffset or (isInteraction and ictx.zOffset or 0.0),
            worldWidth = data.worldWidth,
            worldHeight = data.worldHeight,
            key = data.key,
            action = data.action,
            detail = data.detail,
            detailValue = data.detailValue,
        },
        dui = nil,
        duiId = nil,
        active = true,
        isRendering = false,
    }

    if waypoint.data.drawLine == nil then
        waypoint.data.drawLine = not isInteraction
    end

    local index = #waypointArray + 1
    waypointArray[index] = waypoint
    waypointsById[id] = waypoint
    idToIndex[id] = index

    debugPrint(('[WAYPOINT #%d] Created (no DUI yet - will acquire when visible) | Total waypoints: %d'):format(id,
        #waypointArray))

    return id
end

function WaypointManager.update(id, data)
    local waypoint = waypointsById[id]
    if not waypoint then return end

    if data.coords then
        waypoint.data.coords = data.coords
    end

    if data.type then
        waypoint.data.type = data.type
        if waypoint.dui then
            waypoint.dui:sendMessage({ action = 'setType', type = data.type })
        end
    end

    if data.color then
        waypoint.data.color = data.color
        if waypoint.dui then
            waypoint.dui:sendMessage({ action = 'setColor', color = data.color })
        end
    end

    if data.label then
        waypoint.data.label = data.label
        if waypoint.dui then
            waypoint.dui:sendMessage({ action = 'setLabel', text = data.label })
        end
    end

    if data.icon ~= nil or data.iconColor ~= nil then
        if data.icon ~= nil then
            waypoint.data.icon = data.icon
        end
        if data.iconColor ~= nil then
            waypoint.data.iconColor = data.iconColor
        end
        if waypoint.dui then
            waypoint.dui:sendMessage({
                action = 'setIcon',
                icon = waypoint.data.icon,
                iconColor = waypoint.data
                    .iconColor
            })
        end
    end

    if data.image then
        waypoint.data.image = data.image
        if waypoint.dui then
            waypoint.dui:sendMessage({ action = 'setImage', url = data.image })
        end
    end

    if data.displayDistance ~= nil then
        waypoint.data.displayDistance = data.displayDistance
        if waypoint.dui then
            waypoint.dui:sendMessage({ action = 'showDistance', show = data.displayDistance })
        end
    end

    if data.size then waypoint.data.size = data.size end

    if data.drawDistance then
        waypoint.data.drawDistance = data.drawDistance
        waypoint.data.drawDistanceSq = data.drawDistance * data.drawDistance
    end

    if data.fadeDistance then
        waypoint.data.fadeDistance = data.fadeDistance
        waypoint.data.fadeDistanceSq = data.fadeDistance * data.fadeDistance
    end

    if data.minHeight then waypoint.data.minHeight = data.minHeight end
    if data.maxHeight then waypoint.data.maxHeight = data.maxHeight end
    if data.groundZ then waypoint.data.groundZ = data.groundZ end

    if data.removeDistance then
        waypoint.data.removeDistance = data.removeDistance
        waypoint.data.removeDistanceSq = data.removeDistance * data.removeDistance
    end

    if data.drawLine ~= nil then waypoint.data.drawLine = data.drawLine end
    if data.zOffset ~= nil then waypoint.data.zOffset = data.zOffset end

    local interactionChanged = false
    if data.key ~= nil then waypoint.data.key = data.key; interactionChanged = true end
    if data.action ~= nil then waypoint.data.action = data.action; interactionChanged = true end
    if data.detail ~= nil then waypoint.data.detail = data.detail; interactionChanged = true end
    if data.detailValue ~= nil then waypoint.data.detailValue = data.detailValue; interactionChanged = true end

    if interactionChanged and waypoint.dui and waypoint.data.type == 'interaction' then
        waypoint.dui:sendMessage({
            action = 'setInteraction',
            key = waypoint.data.key or 'E',
            actionText = waypoint.data.action or '',
            detail = waypoint.data.detail or '',
            detailValue = waypoint.data.detailValue or '',
        })
    end

    if data.holdProgress ~= nil and waypoint.dui then
        waypoint.dui:sendMessage({
            action = 'setHoldProgress',
            progress = data.holdProgress,
        })
    end
end

function WaypointManager.setHoldProgress(id, progress)
    local waypoint = waypointsById[id]
    if not waypoint or not waypoint.dui then return end

    waypoint.dui:sendMessage({
        action = 'setHoldProgress',
        progress = progress,
    })
end

--- Acquires a DUI for a waypoint when it becomes visible
---@param waypoint WaypointInstance
---@return boolean success Whether the DUI was acquired successfully
function WaypointManager.acquireForRendering(waypoint)
    if waypoint.isRendering and waypoint.dui then
        return true
    end

    debugPrint(('[WAYPOINT #%d] Acquiring DUI - waypoint became visible'):format(waypoint.id))
    local duiWrapper, duiId = acquireDui()
    if not duiWrapper then
        errorPrint(('[WAYPOINT #%d] FAILED to acquire DUI from pool!'):format(waypoint.id))
        return false
    end

    waypoint.dui = duiWrapper.dui
    waypoint.duiId = duiId
    waypoint.isRendering = true

    configureDui(waypoint.dui, waypoint.data)
    debugPrint(('[WAYPOINT #%d] Now rendering with DUI #%d'):format(waypoint.id, duiId))

    return true
end

--- Releases a DUI when a waypoint is no longer visible
---@param waypoint WaypointInstance
function WaypointManager.releaseFromRendering(waypoint)
    if not waypoint.isRendering then
        return
    end

    debugPrint(('[WAYPOINT #%d] Releasing DUI #%d - waypoint no longer visible'):format(waypoint.id,
        waypoint.duiId or -1))

    if waypoint.duiId then
        releaseDui(waypoint.duiId)
    end

    waypoint.dui = nil
    waypoint.duiId = nil
    waypoint.isRendering = false
    waypoint.lastDistance = nil
    waypoint.nextDistanceUpdate = nil
end

function WaypointManager.remove(id)
    local waypoint = waypointsById[id]
    if not waypoint then return end
    waypoint.active = false

    debugPrint(('[WAYPOINT #%d] Removing (wasRendering: %s)'):format(id, tostring(waypoint.isRendering)))

    if waypoint.isRendering and waypoint.duiId then
        releaseDui(waypoint.duiId)
    end

    local index = idToIndex[id]
    local lastIndex = #waypointArray

    if index ~= lastIndex then
        local lastWaypoint = waypointArray[lastIndex]
        waypointArray[index] = lastWaypoint
        idToIndex[lastWaypoint.id] = index
    end

    waypointArray[lastIndex] = nil
    waypointsById[id] = nil
    idToIndex[id] = nil

    debugPrint(('[WAYPOINT #%d] Removed | Remaining waypoints: %d'):format(id, #waypointArray))
end

function WaypointManager.removeAll()
    for i = #waypointArray, 1, -1 do
        local waypoint = waypointArray[i]
        if waypoint then
            WaypointManager.remove(waypoint.id)
        end
    end
end

function WaypointManager.get(id)
    return waypointsById[id]
end

function WaypointManager.getAll()
    return waypointsById
end

function WaypointManager.getArray()
    return waypointArray
end

---@param basePos vector3 The base/bottom position of the triangle
---@param width number The width of the triangle
---@param height number The height of the triangle
---@param camPos vector3 The camera position (for billboard orientation)
---@return boolean onScreen Whether any corner is visible
local function isTriangleOnScreen(basePos, width, height, camPos)
    local halfW = width / 2

    local up = vec3(0.0, 0.0, 1.0)
    local toCamera = camPos - basePos
    local forward = norm(vec3(toCamera.x, toCamera.y, 0.0))
    local right = norm(cross(up, forward))

    local bottom = basePos
    local topLeft = basePos - (right * halfW) + (up * height)
    local topRight = basePos + (right * halfW) + (up * height)

    local onScreen = GetScreenCoordFromWorldCoord(bottom.x, bottom.y, bottom.z)
    if onScreen == 1 then return true end

    onScreen = GetScreenCoordFromWorldCoord(topLeft.x, topLeft.y, topLeft.z)
    if onScreen == 1 then return true end

    onScreen = GetScreenCoordFromWorldCoord(topRight.x, topRight.y, topRight.z)
    if onScreen == 1 then return true end

    local center = vec3(basePos.x, basePos.y, basePos.z + (height * 0.5))
    onScreen = GetScreenCoordFromWorldCoord(center.x, center.y, center.z)
    if onScreen == 1 then return true end

    return false
end

local function getRenderData(data, camPos)
    local diff = camPos - data.coords
    local camDistSq = diff.x * diff.x + diff.y * diff.y + diff.z * diff.z
    local camDist = math.sqrt(camDistSq)
    local baseSize = data.size * config.rendering.checkpointBaseMultiplier
    local perspectiveScale = camDist / config.rendering.perspectiveDivisor

    if data.type == 'interaction' then
        local ictx = config.interaction or {}
        local anchor = vec3(data.coords.x, data.coords.y, data.coords.z + (data.zOffset or 0.0))
        return {
            camDistSq = camDistSq,
            camDist = camDist,
            lineBasePos = anchor,
            lineTopPos = anchor,
            panelWorldWidth = data.worldWidth or ictx.worldWidth or 1.2,
            panelWorldHeight = data.worldHeight or ictx.worldHeight or 2.4,
            lineThickness = 0.0,
            isInteraction = true,
        }
    end

    if data.type == 'checkpoint' then
        local size = baseSize * math.max(config.rendering.checkpointMinScale, perspectiveScale)
        local unclampedHeight = size * config.rendering.checkpointAspectRatio
        local markerHeight = math.max(data.minHeight, math.min(data.maxHeight, unclampedHeight))
        local markerWidth = size * (markerHeight / unclampedHeight)
        local lineHeight = markerHeight * config.rendering.checkpointLineHeightRatio
        local lineBasePos = vec3(data.coords.x, data.coords.y, data.groundZ)
        local topZ = data.labelZ or (lineBasePos.z + lineHeight)
        local lineTopPos = vec3(lineBasePos.x, lineBasePos.y, topZ)

        return {
            camDistSq = camDistSq,
            camDist = camDist,
            lineBasePos = lineBasePos,
            lineTopPos = lineTopPos,
            panelWorldWidth = markerWidth * config.rendering.checkpointPanelWidthRatio,
            panelWorldHeight = markerHeight * config.rendering.checkpointPanelHeightRatio,
            lineThickness = math.max(markerWidth * config.rendering.worldLineThicknessRatio, 0.04),
        }
    end

    local size = baseSize * math.max(config.rendering.smallMinScale, perspectiveScale)
    local markerHeight = size * config.rendering.smallAspectRatio
    local markerWidth = size
    local lineHeight = markerHeight * config.rendering.smallLineHeightRatio
    local lineBasePos = vec3(data.coords.x, data.coords.y, data.coords.z - (markerHeight / 2))

    return {
        camDistSq = camDistSq,
        camDist = camDist,
        lineBasePos = lineBasePos,
        lineTopPos = vec3(lineBasePos.x, lineBasePos.y, lineBasePos.z + lineHeight),
        panelWorldWidth = markerWidth * config.rendering.smallPanelWidthRatio,
        panelWorldHeight = markerHeight * config.rendering.smallPanelHeightRatio,
        lineThickness = math.max(markerWidth * config.rendering.worldLineThicknessRatio, 0.025),
    }
end

local function isLineVisibleOnScreen(fromPos, toPos)
    if utils.worldToScreen(fromPos) then
        return true
    end

    if utils.worldToScreen(toPos) then
        return true
    end

    local midpoint = vec3(
        (fromPos.x + toPos.x) * 0.5,
        (fromPos.y + toPos.y) * 0.5,
        (fromPos.z + toPos.z) * 0.5
    )

    return utils.worldToScreen(midpoint)
end

function WaypointManager.shouldRender(waypoint, camPos)
    if not waypoint.active then
        debugPrint('Waypoint inactive:', waypoint.id)
        return false
    end

    local data = waypoint.data
    local renderData = getRenderData(data, camPos)

    if renderData.isInteraction then
        if data.drawDistanceSq and renderData.camDistSq > data.drawDistanceSq then
            return false
        end
        return utils.worldToScreen(renderData.lineTopPos)
    end

    return isLineVisibleOnScreen(renderData.lineBasePos, renderData.lineTopPos)
end

function WaypointManager.render(waypoint, camPos, playerPos)
    if not waypoint.active or not waypoint.dui then return false end

    local success = pcall(IsDuiAvailable, waypoint.dui.duiObject)

    if not success then return false end

    local data = waypoint.data
    local playerDiff = playerPos - data.coords
    local playerDistSq = playerDiff.x * playerDiff.x + playerDiff.y * playerDiff.y + playerDiff.z * playerDiff.z
    local renderData = getRenderData(data, camPos)
    local alpha = 255

    if not waypoint.dui.dictName or not waypoint.dui.txtName then return false end

    if data.displayDistance and (not waypoint.nextDistanceUpdate or GetGameTimer() >= waypoint.nextDistanceUpdate) then
        local playerDist = math.sqrt(playerDistSq)
        local flooredDist = math.floor(playerDist)
        if waypoint.lastDistance ~= flooredDist then
            waypoint.nextDistanceUpdate = GetGameTimer() + config.rendering.distanceUpdateInterval
            waypoint.lastDistance = flooredDist

            waypoint.dui:sendMessage({
                action = 'setDistance',
                value = tostring(flooredDist),
                duration = config.rendering.distanceUpdateInterval
            })
        end
    end

    if data.drawLine then
        utils.drawWorldLine(
            renderData.lineBasePos,
            renderData.lineTopPos,
            255,
            255,
            255,
            alpha,
            renderData.lineThickness,
            lineGradientDui and lineGradientDui.dictName or nil,
            lineGradientDui and lineGradientDui.txtName or nil
        )
    end

    local onScreen = utils.worldToScreen(renderData.lineTopPos)
    if onScreen then
        local screenWidth, screenHeight = utils.getScreenSizeFromWorldSize(
            renderData.camDist,
            renderData.panelWorldWidth,
            renderData.panelWorldHeight
        )

        utils.drawWorldSpriteBottomCenter(
            renderData.lineTopPos,
            screenWidth,
            screenHeight,
            255, 255, 255, alpha,
            waypoint.dui.dictName,
            waypoint.dui.txtName
        )
    end

    if data.removeDistanceSq and playerDistSq <= data.removeDistanceSq then
        WaypointManager.remove(waypoint.id)
        debugPrint('Removed waypoint for being close:', waypoint.id)
        return false
    end

    return true
end

return WaypointManager
