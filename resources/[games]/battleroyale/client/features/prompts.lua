Game.prompts = {}

local registered = {}
local activePromptKey = nil
local interactionWaypointId = nil

---@class PromptDef
---@field id string
---@field priority number
---@field label fun(): string | nil
---@field available fun(): boolean
---@field execute fun()
---@field hold? boolean
---@field position? fun(): vector3 | nil World coord where the 3D prompt marker is anchored
---@field zOffset? number
---@field worldWidth? number
---@field worldHeight? number

---@param def PromptDef
function Game.prompts.register(def)
    registered[def.id] = def
end

---@param id string
function Game.prompts.unregister(id)
    registered[id] = nil
end

RegisterCommand('+br:interact', function()
    if not Game.session:active() then return end
    Game.session:fire('interact.pressed')
end, false)

RegisterCommand('-br:interact', function()
    Game.session:fire('interact.released')
end, false)

RegisterKeyMapping('+br:interact', 'Interagir', 'KEYBOARD', 'E')


local function removeInteractionWaypoint()
    if not interactionWaypointId then return end
    pcall(function()
        exports.waypoint:remove(interactionWaypointId)
    end)
    interactionWaypointId = nil
end

---@param pos vector3
---@param label string
---@param zOffset? number
---@param worldWidth? number
---@param worldHeight? number
local function showInteractionWaypoint(pos, label, zOffset, worldWidth, worldHeight)
    if interactionWaypointId then
        pcall(function()
            exports.waypoint:update(interactionWaypointId, {
                coords = pos,
                action = label,
            })
        end)
        return
    end

    local id = nil
    local ok = pcall(function()
        id = exports.waypoint:create({
            type = 'interaction',
            coords = pos,
            drawLine = false,
            key = 'E',
            action = label,
            detail = '',
            detailValue = '',
            zOffset = zOffset,
            worldWidth = worldWidth,
            worldHeight = worldHeight,
        })
    end)

    if ok then
        interactionWaypointId = id
    end
end

---@param progress number 0..1
function Game.prompts.setHoldProgress(progress)
    if not interactionWaypointId then return end
    pcall(function()
        exports.waypoint:setHoldProgress(interactionWaypointId, progress)
    end)
end

local function hide2D()
    Game.ui.send('hud:interaction', {
        visible = false,
        key = '',
        action = '',
        detail = '',
        detailValue = '',
    })
end

---@param label string
local function show2D(label)
    Game.ui.send('hud:interaction', {
        visible = true,
        key = 'E',
        action = label,
        detail = '',
        detailValue = '',
    })
end

local function clearPrompt()
    activePromptKey = nil
    removeInteractionWaypoint()
    hide2D()
end

CreateThread(function()
    while true do
        if Game.session:active() then
            local best = nil
            local bestPrio = -1

            for _, def in pairs(registered) do
                if def.available() then
                    local prio = def.priority or 0
                    if prio > bestPrio then
                        bestPrio = prio
                        best = def
                    end
                end
            end

            if best then
                local label = best.label() or ''
                local pos = best.position and best.position() or nil
                local key = label .. '|' .. best.id .. '|' .. (pos and ('%.2f|%.2f|%.2f'):format(pos.x, pos.y, pos.z) or '2d')

                if activePromptKey ~= key then
                    removeInteractionWaypoint()
                    hide2D()
                    activePromptKey = key
                    if pos then
                        showInteractionWaypoint(pos, label, best.zOffset, best.worldWidth, best.worldHeight)
                    else
                        show2D(label)
                    end
                end
                Wait(0)
            else
                if activePromptKey then
                    clearPrompt()
                end
                Wait(200)
            end
        else
            if activePromptKey then
                clearPrompt()
            end
            Wait(1000)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        removeInteractionWaypoint()
    end
end)
