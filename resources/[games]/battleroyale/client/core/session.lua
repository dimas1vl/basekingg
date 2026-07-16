local RESOURCE = Game.resource

---@class Session
---@field matchId number | nil
---@field phase string | nil
---@field squadIdx number | nil
---@field squad number[]
local Session = {}
Session.__index = Session

local listeners = {}

---@param event string
---@param handler function
function Session:listen(event, handler)
    if not listeners[event] then
        listeners[event] = {}
    end
    listeners[event][#listeners[event] + 1] = handler
end

---@param event string
---@param ... any
function Session:fire(event, ...)
    local cbs = listeners[event]
    if not cbs then return end
    for i = 1, #cbs do
        local ok, err = pcall(cbs[i], ...)
        if not ok then
            print(('[Session] %s error: %s'):format(event, tostring(err)))
        end
    end
end

---@param event string
---@param ... any
function Session:send(event, ...)
    TriggerServerEvent(('net.%s:%s'):format(RESOURCE, event), ...)
end

---@param event string
---@param handler function
function Session:onNet(event, handler)
    RegisterNetEvent(('net.%s:%s'):format(RESOURCE, event), function(...)
        handler(...)
    end)
end

---@return boolean
function Session:active()
    return self.matchId ~= nil
end

---@return string | nil
function Session:currentPhase()
    return self.phase
end

local session = setmetatable({
    matchId = nil,
    phase = nil,
    squadIdx = nil,
    squad = {},
}, Session)

RegisterNetEvent(('net.%s:match.join'):format(RESOURCE), function(matchId, state, squadIndex, squadMembers)
    print(('[session] match.join received — matchId=%s state=%s squadIdx=%s squad=%d'):format(
        tostring(matchId), tostring(state), tostring(squadIndex), squadMembers and #squadMembers or 0))
    session.matchId = matchId
    session.phase = state
    session.squadIdx = squadIndex
    session.squad = squadMembers or {}
    session:fire('joined', matchId, state, squadIndex)
end)

RegisterNetEvent(('net.%s:match.stateChange'):format(RESOURCE), function(newState)
    local oldPhase = session.phase
    print(('[session] match.stateChange received — %s → %s'):format(tostring(oldPhase), tostring(newState)))
    session.phase = newState
    session:fire('phaseChange', newState, oldPhase)
end)

RegisterNetEvent(('net.%s:match.playerLeft'):format(RESOURCE), function(src, squadIndex)
    if squadIndex == session.squadIdx then
        for i = #session.squad, 1, -1 do
            if session.squad[i] == src then
                table.remove(session.squad, i)
                break
            end
        end
    end
    session:fire('playerLeft', src, squadIndex)
end)

RegisterNetEvent(('net.%s:match.end'):format(RESOURCE), function()
    print('[session] match.end received')
    session:fire('ended')
    session.matchId = nil
    session.phase = nil
    session.squadIdx = nil
    session.squad = {}
end)

Game.session = session
