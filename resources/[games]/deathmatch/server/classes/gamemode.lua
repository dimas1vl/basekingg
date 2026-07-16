local RESOURCE = GetCurrentResourceName()

local GameMode = {}
GameMode.__index = GameMode

function GameMode.new()

    local self = setmetatable({
        matches = {},
        submodeMatches = {},
        playerMatch = {},
        handlers = {},
        nextId = 1,
    }, GameMode)

    AddEventHandler('kingg:matchmaking:start', function(batch, mode, subMode, squadType)
        if mode ~= Config.Deathmatch.mode then return end
        if not Config.Deathmatch.variants or not Config.Deathmatch.variants[subMode] then return end
        self:onBatch(batch, mode, subMode, squadType)
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

    log('info', 'Deathmatch GameMode initialized')

    return self
end

function GameMode:onBatch(batch, mode, subMode, squadType)
    local existingId = self.submodeMatches[subMode]
    local match = existingId and self.matches[existingId] or nil

    if match then
        self:joinExisting(match, batch)
    else
        match = self:createMatch(batch, mode, subMode, squadType)
        if match then
            self.submodeMatches[subMode] = match.id
        end
    end
end

function GameMode:createMatch(batch, mode, subMode, squadType)

    local sanitized = {}
    for i = 1, #batch do
        local src = tonumber(batch[i])
        if src and DoesPlayerExist(tostring(src)) then
            sanitized[#sanitized + 1] = src
        end
    end
    if #sanitized == 0 then return nil end

    local id = self.nextId
    self.nextId = self.nextId + 1

    local match = Match.new(id, sanitized, mode, subMode, squadType)
    self.matches[id] = match

    for i = 1, #sanitized do
        self.playerMatch[sanitized[i]] = id
    end

    local scoreboard = match:getScoreboard()

    for i = 1, #sanitized do
        local src = sanitized[i]
        TriggerClientEvent(('net.%s:match.join'):format(RESOURCE), src,
            id, match.state, scoreboard, src, subMode)
    end

    self:emit('matchCreated', match)

    return match
end

function GameMode:joinExisting(match, batch)
    local joined = {}
    for i = 1, #batch do
        local src = tonumber(batch[i])
        if src and DoesPlayerExist(tostring(src)) and not match:isPlayer(src) then
            match:addPlayer(src)
            self.playerMatch[src] = match.id
            joined[#joined + 1] = src
        end
    end

    if #joined == 0 then return end

    local scoreboard = match:getScoreboard()
    for i = 1, #joined do
        local src = joined[i]
        TriggerClientEvent(('net.%s:match.join'):format(RESOURCE), src,
            match.id, match.state, scoreboard, src, match.subMode)
        self:emit('playerJoined', match, src)
    end
    self:emit('batchJoined', match, joined)
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
---@param ... any
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

function GameMode:onPlayerDropped(src)
    local match = self:getPlayerMatch(src)
    if not match then return end

    match:removePlayer(src)
    self.playerMatch[src] = nil

    match:emitClients('playerLeft', src)
    self:emit('playerLeft', match, src)

    if #match.playerList == 0 then
        if self.submodeMatches[match.subMode] == match.id then
            self.submodeMatches[match.subMode] = nil
        end
        self:destroyMatch(match.id)
    end
end

function GameMode:onPlayerLeave(src)
    local match = self:getPlayerMatch(src)
    if not match then return end

    match:emitClient(src, 'match.end')

    match:removePlayer(src)
    self.playerMatch[src] = nil

    match:emitClients('playerLeft', src)
    self:emit('playerLeft', match, src)

    if #match.playerList == 0 then
        if self.submodeMatches[match.subMode] == match.id then
            self.submodeMatches[match.subMode] = nil
        end
        self:destroyMatch(match.id)
    end
end

_G.GameMode = GameMode
