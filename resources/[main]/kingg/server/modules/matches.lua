while not Core do
    Wait(100)
end

---@class MatchEntry
---@field id number
---@field resource string
---@field mode string
---@field subMode string
---@field bucket number
---@field players table<number, true>
---@field spectators table<number, true>
---@field createdAt number

---@class MatchController
---@field nextId number
---@field matches table<number, MatchEntry>
---@field playerMatch table<number, number>
---@field spectatorMatch table<number, number>
local MatchController = {
    nextId = 1,
    matches = {},
    playerMatch = {},
    spectatorMatch = {},
}

---@param resource string
---@param mode string
---@param subMode string
---@param bucket number
---@param players number[]
---@return number matchId
function MatchController:register(resource, mode, subMode, bucket, players)

    local id = self.nextId
    self.nextId = self.nextId + 1

    self.matches[id] = {
        id = id,
        resource = resource,
        mode = mode,
        subMode = subMode,
        bucket = bucket,
        players = {},
        spectators = {},
        createdAt = GetGameTimer(),
    }

    for i = 1, #players do
        self.matches[id].players[players[i]] = true
        self.playerMatch[players[i]] = id
    end

    log('info', ('match controller: registered match %d (resource=%s mode=%s subMode=%s bucket=%d players=%d)'):format(
        id, resource, mode, subMode, bucket, #players
    ))

    return id
end

---@param matchId number
function MatchController:unregister(matchId)

    local entry = self.matches[matchId]

    if not entry then return end

    for src in pairs(entry.players) do
        self.playerMatch[src] = nil
    end

    for src in pairs(entry.spectators) do
        self.spectatorMatch[src] = nil

        if DoesPlayerExist(tostring(src)) then
            SetPlayerRoutingBucket(tostring(src), src)
        end
    end

    self.matches[matchId] = nil

    log('info', ('match controller: unregistered match %d'):format(matchId))
end

---@param matchId number
---@param src number
function MatchController:removePlayer(matchId, src)

    local entry = self.matches[matchId]

    if not entry then return end

    entry.players[src] = nil
    self.playerMatch[src] = nil
end

---@param matchId number
---@param src number
---@return boolean success
---@return string | nil errorMessage
function MatchController:addSpectator(matchId, src)

    local entry = self.matches[matchId]

    if not entry then
        return false, 'match not found'
    end

    if self.playerMatch[src] then
        return false, 'player is in a match'
    end

    if self.spectatorMatch[src] then
        return false, 'already spectating a match'
    end

    entry.spectators[src] = true
    self.spectatorMatch[src] = matchId

    SetPlayerRoutingBucket(tostring(src), entry.bucket)

    log('info', ('match controller: spectator %d joined match %d (bucket=%d)'):format(src, matchId, entry.bucket))

    return true
end

---@param src number
function MatchController:removeSpectator(src)

    local matchId = self.spectatorMatch[src]

    if not matchId then return end

    local entry = self.matches[matchId]

    if entry then
        entry.spectators[src] = nil
    end

    self.spectatorMatch[src] = nil

    if DoesPlayerExist(tostring(src)) then
        SetPlayerRoutingBucket(tostring(src), src)
    end

    log('info', ('match controller: spectator %d left match %d'):format(src, matchId))
end

---@param src number
---@return number | nil matchId
function MatchController:getPlayerMatchId(src)

    return self.playerMatch[src]
end

---@param src number
---@return number | nil matchId
function MatchController:getSpectatorMatchId(src)

    return self.spectatorMatch[src]
end

---@param matchId number
---@return MatchEntry | nil
function MatchController:getMatch(matchId)

    return self.matches[matchId]
end

---@return MatchEntry[]
function MatchController:listMatches()

    local result = {}

    for _, entry in pairs(self.matches) do
        result[#result + 1] = entry
    end

    return result
end

Core.matches = MatchController

AddEventHandler('playerDropped', function()

    local src = source

    MatchController:removeSpectator(src)
end)
