local RESOURCE = GetCurrentResourceName()

---@class ClutchGameMode
---@field matches table<number, ClutchMatch>
---@field playerMatch table<number, number>
---@field handlers table<string, function[]>
---@field nextId number
local GameMode = {}
GameMode.__index = GameMode

---@return ClutchGameMode
function GameMode.new()
    local self = setmetatable({
        matches = {},
        playerMatch = {},
        handlers = {},
        nextId = 1,
    }, GameMode)

    AddEventHandler('kingg:matchmaking:start', function(batch, mode, subMode, squadType, options)
        if type(mode) ~= 'string' or mode:lower() ~= Config.Clutch.mode:lower() then return end

        local function reject(reason)
            log('error', ('clutch: rejected batch — %s'):format(reason))
            TriggerEvent('kingg:matchmaking:rejected', batch, Config.Clutch.mode, subMode, reason)
        end

        local variantKey = type(subMode) == 'string' and subMode:lower() or subMode
        local variant = Config.Clutch.variants and Config.Clutch.variants[variantKey]
        if not variant then
            return reject(('unknown variant "%s"'):format(tostring(subMode)))
        end
        if type(batch) ~= 'table' or #batch == 0 then
            return reject('empty or invalid batch')
        end
        if #batch ~= variant.totalPlayers then
            return reject(('variant=%s expected=%d got=%d'):format(subMode, variant.totalPlayers, #batch))
        end
        local sanitized = {}
        for i = 1, #batch do
            local s = tonumber(batch[i])
            if s and DoesPlayerExist(tostring(s)) then sanitized[#sanitized + 1] = s end
        end
        if #sanitized ~= variant.totalPlayers then
            return reject('some players disconnected before start')
        end
        self:createMatch(sanitized, Config.Clutch.mode, variantKey, options)
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

    log('info', 'Clutch GameMode initialized')
    return self
end

---@param batch number[]
---@param mode string
---@param variant string
---@param options table | nil
---@return ClutchMatch
function GameMode:createMatch(batch, mode, variant, options)
    local id = self.nextId
    self.nextId = self.nextId + 1

    local match = Match.new(id, batch, mode, variant, options)
    self.matches[id] = match

    for i = 1, #batch do
        self.playerMatch[batch[i]] = id
    end

    local scoreboard = match:getScoreboard()

    for i = 1, #batch do
        local src = batch[i]
        TriggerClientEvent(('net.%s:match.join'):format(RESOURCE), src,
            id, match.state, scoreboard, src, variant)
    end

    self:emit('matchCreated', match)

    return match
end

---@param matchId number
---@return ClutchMatch | nil
function GameMode:getMatch(matchId)
    return self.matches[matchId]
end

---@param src number
---@return ClutchMatch | nil
function GameMode:getPlayerMatch(src)
    local matchId = self.playerMatch[src]
    if not matchId then return nil end
    return self.matches[matchId]
end

---@param eventName string
---@param handler fun(match: ClutchMatch, ...)
function GameMode:on(eventName, handler)
    if not self.handlers[eventName] then
        self.handlers[eventName] = {}
    end
    local handlers = self.handlers[eventName]
    handlers[#handlers + 1] = handler
end

---@param eventName string
---@param match ClutchMatch
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
---@param handler fun(match: ClutchMatch, src: number, ...)
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

    log('info', ('clutch match %d destroyed'):format(matchId))
end

---@param match ClutchMatch
---@return boolean
local function matchIntegrityBroken(match)
    local variant = Config.Clutch.variants and Config.Clutch.variants[match.variant]
    if not variant then return true end
    if #match.playerList < variant.totalPlayers then return true end
    return false
end

---@param src number
function GameMode:onPlayerDropped(src)
    local match = self:getPlayerMatch(src)
    if not match then return end

    match:removePlayer(src)
    self.playerMatch[src] = nil

    match:emitClients('playerLeft', src)
    self:emit('playerLeft', match, src)

    if matchIntegrityBroken(match) then
        self:emit('matchEnded', match, 'forfeit', src)
    end
end

---@param src number
function GameMode:onPlayerLeave(src)
    local match = self:getPlayerMatch(src)
    if not match then return end

    match:emitClient(src, 'match.end')
    TriggerClientEvent('Notify', src, 'error', 'DERROTA · Voce desistiu da partida.', 6)

    match:removePlayer(src)
    self.playerMatch[src] = nil

    match:emitClients('playerLeft', src)
    self:emit('playerLeft', match, src)

    if matchIntegrityBroken(match) then
        self:emit('matchEnded', match, 'forfeit', src)
    end
end

_G.GameMode = GameMode
