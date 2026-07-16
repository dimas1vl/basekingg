local RESOURCE = GetCurrentResourceName()
local cfg = Config.DriveBy

---@class GameMode
---@field matches table<number, Match>
---@field playerMatch table<number, number>
---@field handlers table<string, function[]>
---@field nextId number
local GameMode = {}
GameMode.__index = GameMode

---@return GameMode
function GameMode.new()

    local self = setmetatable({
        matches = {},
        playerMatch = {},
        handlers = {},
        nextId = 1,
    }, GameMode)

    AddEventHandler('kingg:matchmaking:start', function(batch, mode, subMode, squadType)

        if mode ~= cfg.mode or subMode ~= cfg.subMode then return end

        self:createMatch(batch, mode, subMode, squadType)
    end)

    AddEventHandler('playerDropped', function()

        local src = source

        if not self.playerMatch[src] then return end

        self:onPlayerDropped(src)
    end)

    AddEventHandler('kingg:player:leave', function(src)

        if not self.playerMatch[src] then return end

        self:onPlayerLeave(src)
    end)

    log('info', 'Drive-By GameMode initialized')

    return self
end

---@param batch number[]
---@param mode string
---@param subMode string
---@param squadType string
---@return Match
function GameMode:createMatch(batch, mode, subMode, squadType)

    local id = self.nextId

    self.nextId = self.nextId + 1

    local match = Match.new(id, batch, mode, subMode, squadType)

    self.matches[id] = match

    for i = 1, #batch do
        self.playerMatch[batch[i]] = id
    end

    local scoreboard = match:getScoreboard()

    for i = 1, #batch do
        local src = batch[i]
        TriggerClientEvent(('net.%s:match.join'):format(RESOURCE), src, id, match.state, scoreboard, src, subMode)
    end

    self:emit('matchCreated', match)

    return match
end

---@param matchId number
---@return Match | nil
function GameMode:getMatch(matchId)

    return self.matches[matchId]
end

---@param src number
---@return Match | nil
function GameMode:getPlayerMatch(src)

    local matchId = self.playerMatch[src]

    if not matchId then return nil end

    return self.matches[matchId]
end

---@param eventName string
---@param handler fun(match: Match, ...)
function GameMode:on(eventName, handler)

    if not self.handlers[eventName] then
        self.handlers[eventName] = {}
    end

    local handlers = self.handlers[eventName]

    handlers[#handlers + 1] = handler
end

---@param eventName string
---@param match Match
function GameMode:emit(eventName, match, ...)

    local handlers = self.handlers[eventName]

    if not handlers then return end

    for i = 1, #handlers do
        local ok, err = pcall(handlers[i], match, ...)
        if not ok then
            log('error', ('GameMode handler error [%s]: %s'):format(eventName, tostring(err)))
        end
    end
end

---@param eventName string
---@param handler fun(match: Match, src: number, ...)
function GameMode:registerNetEvent(eventName, handler)

    RegisterNetEvent(('net.%s:%s'):format(RESOURCE, eventName), function(...)

        local src = source
        local match = self:getPlayerMatch(src)

        if not match then return end

        handler(match, src, ...)
    end)
end

---@param matchId number
function GameMode:destroyMatch(matchId)

    local match = self.matches[matchId]

    if not match then return end

    match:emitClients('match.end')
    match:cleanup()

    for i = 1, #match.playerList do
        self.playerMatch[match.playerList[i]] = nil
    end

    self.matches[matchId] = nil

    self:emit('matchFinished', match)

    log('info', ('match %d destroyed'):format(matchId))
end

---@param src number
function GameMode:onPlayerDropped(src)

    local match = self:getPlayerMatch(src)

    if not match then return end

    match:removePlayer(src)

    self.playerMatch[src] = nil

    match:emitClients('playerLeft', src)
    self:emit('playerLeft', match, src)

    if #match.playerList == 0 then
        self:destroyMatch(match.id)
    end
end

---@param src number
function GameMode:onPlayerLeave(src)

    local match = self:getPlayerMatch(src)

    if not match then return end

    match:emitClient(src, 'match.end')
    match:removePlayer(src)

    self.playerMatch[src] = nil

    match:emitClients('playerLeft', src)
    self:emit('playerLeft', match, src)

    if #match.playerList == 0 then
        self:destroyMatch(match.id)
    end
end

_G.GameMode = GameMode
