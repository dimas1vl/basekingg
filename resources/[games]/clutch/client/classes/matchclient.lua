local RESOURCE = GetCurrentResourceName()

---@class ClutchMatchClient
---@field matchId number | nil
---@field state MatchState | nil
---@field selfSrc number | nil
---@field variant string | nil
---@field scoreboard table | nil
---@field handlers table<string, function[]>
local MatchClient = {}
MatchClient.__index = MatchClient

---@return ClutchMatchClient
function MatchClient.new()
    local self = setmetatable({
        matchId = nil,
        state = nil,
        selfSrc = nil,
        variant = nil,
        scoreboard = nil,
        handlers = {},
    }, MatchClient)

    RegisterNetEvent(('net.%s:match.join'):format(RESOURCE), function(matchId, state, scoreboard, selfSrc, variant)
        self.matchId    = matchId
        self.state      = state
        self.selfSrc    = selfSrc
        self.variant    = variant
        self.scoreboard = scoreboard
        self:emit('matchJoined', matchId, state, scoreboard, variant)
    end)

    RegisterNetEvent(('net.%s:match.stateChange'):format(RESOURCE), function(newState)
        local oldState = self.state
        self.state = newState
        self:emit('stateChanged', newState, oldState)
    end)

    RegisterNetEvent(('net.%s:match.end'):format(RESOURCE), function()
        self:emit('matchEnded')
        self.matchId    = nil
        self.state      = nil
        self.selfSrc    = nil
        self.variant    = nil
        self.scoreboard = nil
    end)

    RegisterNetEvent(('net.%s:round.info'):format(RESOURCE), function(info)
        self:emit('roundInfo', info)
    end)

    RegisterNetEvent(('net.%s:round.spawn'):format(RESOURCE), function(payload)
        self:emit('roundSpawn', payload)
    end)

    RegisterNetEvent(('net.%s:round.fightStart'):format(RESOURCE), function()
        self:emit('fightStart')
    end)

    RegisterNetEvent(('net.%s:round.result'):format(RESOURCE), function(result)
        self:emit('roundResult', result)
    end)

    RegisterNetEvent(('net.%s:zone.start'):format(RESOURCE), function(payload)
        self:emit('zoneStart', payload)
    end)

    RegisterNetEvent(('net.%s:zone.stop'):format(RESOURCE), function()
        self:emit('zoneStop')
    end)

    RegisterNetEvent(('net.%s:scoreboard'):format(RESOURCE), function(scoreboard)
        self.scoreboard = scoreboard
        self:emit('scoreboard', scoreboard)
    end)

    RegisterNetEvent(('net.%s:killFeed'):format(RESOURCE), function(entry)
        self:emit('killFeed', entry)
    end)

    RegisterNetEvent(('net.%s:playerLeft'):format(RESOURCE), function(src)
        self:emit('playerLeft', src)
    end)

    RegisterNetEvent(('net.%s:match.result'):format(RESOURCE), function(result)
        self:emit('matchResult', result)
    end)

    return self
end

---@return boolean
function MatchClient:isInMatch()
    return self.matchId ~= nil
end

---@param eventName string
---@param handler function
function MatchClient:on(eventName, handler)
    if not self.handlers[eventName] then
        self.handlers[eventName] = {}
    end
    local handlers = self.handlers[eventName]
    handlers[#handlers + 1] = handler
end

---@param eventName string
function MatchClient:emit(eventName, ...)
    local handlers = self.handlers[eventName]
    if not handlers then return end
    for i = 1, #handlers do
        local ok, err = pcall(handlers[i], ...)
        if not ok then
            print(('ClutchMatchClient handler error [%s]: %s'):format(eventName, tostring(err)))
        end
    end
end

---@param eventName string
function MatchClient:emitServer(eventName, ...)
    TriggerServerEvent(('net.%s:%s'):format(RESOURCE, eventName), ...)
end

_G.MatchClient = MatchClient
