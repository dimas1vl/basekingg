while not Core do
    Wait(100)
end

local RESOURCE = GetCurrentResourceName()

---@class MatchSquad
---@field index number
---@field players number[]
---@field alive number[]

---@class MatchPlayerStats
---@field kills number
---@field deaths number
---@field downs number
---@field revives number

---@class Match
---@field id number
---@field mode string
---@field subMode string
---@field squadType string
---@field state MatchState
---@field players table<number, true>
---@field playerList number[]
---@field squads MatchSquad[]
---@field playerSquad table<number, number>
---@field playerStates table<number, PlayerState>
---@field stats table<number, MatchPlayerStats>
---@field bucket number
---@field createdAt number
---@field data table
local Match = {}
Match.__index = Match

---@param id number
---@param batch number[]
---@param mode string
---@param subMode string
---@param squadType string
---@param squadSize number
---@param squadGroups? number[][]
---@return Match
function Match.new(id, batch, mode, subMode, squadType, squadSize, squadGroups)

    assert(type(batch) == 'table' and #batch > 0, 'batch must be a non-empty array')
    local self = setmetatable({
        id = id,
        mode = mode,
        subMode = subMode,
        squadType = squadType,
        state = MatchState.WAITING,
        players = {},
        playerList = {},
        squads = {},
        playerSquad = {},
        playerStates = {},
        stats = {},
        bucket = Core.allocateBucket(),
        createdAt = GetGameTimer(),
        data = {},
    }, Match)

    if squadGroups then
        for squadIndex = 1, #squadGroups do
            local group = squadGroups[squadIndex]

            self.squads[squadIndex] = {
                index = squadIndex,
                players = {},
                alive = {},
            }

            local squad = self.squads[squadIndex]

            for j = 1, #group do
                local src = group[j]

                self.players[src] = true
                self.playerList[#self.playerList + 1] = src
                self.playerStates[src] = PlayerState.ALIVE
                self.stats[src] = { kills = 0, deaths = 0, downs = 0, revives = 0 }

                squad.players[#squad.players + 1] = src
                squad.alive[#squad.alive + 1] = src
                self.playerSquad[src] = squadIndex

                SetPlayerRoutingBucket(tostring(src), self.bucket)
            end
        end
    else
        assert(type(squadSize) == 'number' and squadSize > 0, 'squadSize must be a positive number')

        for i = 1, #batch do
            local src = batch[i]

            self.players[src] = true
            self.playerList[#self.playerList + 1] = src
            self.playerStates[src] = PlayerState.ALIVE
            self.stats[src] = { kills = 0, deaths = 0, downs = 0, revives = 0 }

            local squadIndex = math.ceil(i / squadSize)

            if not self.squads[squadIndex] then
                self.squads[squadIndex] = {
                    index = squadIndex,
                    players = {},
                    alive = {},
                }
            end

            local squad = self.squads[squadIndex]

            squad.players[#squad.players + 1] = src
            squad.alive[#squad.alive + 1] = src
            self.playerSquad[src] = squadIndex

            SetPlayerRoutingBucket(tostring(src), self.bucket)
        end
    end

    log('info', ('match %d created: mode=%s subMode=%s squad=%s players=%d squads=%d bucket=%d'):format(
        id, mode, subMode, squadType, #batch, #self.squads, self.bucket
    ))

    return self
end

---@param src number
---@return boolean
function Match:isPlayer(src)

    return self.players[src] == true
end

---@param src number
---@return MatchSquad | nil
function Match:getSquad(src)

    local idx = self.playerSquad[src]

    if not idx then return nil end

    return self.squads[idx]
end

---@return number[]
function Match:getAlivePlayers()

    local alive = {}

    for i = 1, #self.squads do
        local squad = self.squads[i]

        for j = 1, #squad.alive do
            alive[#alive + 1] = squad.alive[j]
        end
    end

    return alive
end

---@return MatchSquad[]
function Match:getAliveSquads()

    local result = {}

    for i = 1, #self.squads do
        if #self.squads[i].alive > 0 then
            result[#result + 1] = self.squads[i]
        end
    end

    return result
end

---@param src number
---@return number squadIndex
---@return boolean isSquadEliminated
---@return number aliveSquadCount
function Match:markDead(src)

    assert(self.players[src], ('player %d is not in match %d'):format(src, self.id))

    local squadIndex = self.playerSquad[src]
    local squad = self.squads[squadIndex]

    for i = #squad.alive, 1, -1 do
        if squad.alive[i] == src then
            table.remove(squad.alive, i)
            break
        end
    end

    local isSquadEliminated = #squad.alive == 0
    local aliveSquadCount = 0

    for i = 1, #self.squads do
        if #self.squads[i].alive > 0 then
            aliveSquadCount = aliveSquadCount + 1
        end
    end

    log('info', ('match %d: player %d marked dead (squad=%d, squadAlive=%d, aliveSquads=%d)'):format(
        self.id, src, squadIndex, #squad.alive, aliveSquadCount
    ))

    return squadIndex, isSquadEliminated, aliveSquadCount
end

---@param src number
---@return number squadIndex
---@return boolean isSquadEliminated
---@return number aliveSquadCount
function Match:removePlayer(src)

    assert(self.players[src], ('player %d is not in match %d'):format(src, self.id))

    local squadIndex = self.playerSquad[src]

    self.players[src] = nil
    self.playerSquad[src] = nil

    for i = #self.playerList, 1, -1 do
        if self.playerList[i] == src then
            table.remove(self.playerList, i)
            break
        end
    end

    local squad = self.squads[squadIndex]

    for j = #squad.players, 1, -1 do
        if squad.players[j] == src then
            table.remove(squad.players, j)
            break
        end
    end

    for j = #squad.alive, 1, -1 do
        if squad.alive[j] == src then
            table.remove(squad.alive, j)
            break
        end
    end

    local isSquadEliminated = #squad.alive == 0
    local aliveSquadCount = 0

    for i = 1, #self.squads do
        if #self.squads[i].alive > 0 then
            aliveSquadCount = aliveSquadCount + 1
        end
    end

    if DoesPlayerExist(tostring(src)) then
        SetPlayerRoutingBucket(tostring(src), src)
    end

    log('info', ('match %d: player %d removed (squad=%d, aliveSquads=%d)'):format(
        self.id, src, squadIndex, aliveSquadCount
    ))

    return squadIndex, isSquadEliminated, aliveSquadCount
end

---@param newState MatchState
function Match:setState(newState)

    local validTransitions = {
        [MatchState.WAITING]  = MatchState.AIRPLANE,
        [MatchState.AIRPLANE] = MatchState.STARTED,
        [MatchState.STARTED]  = MatchState.ENDING,
        [MatchState.ENDING]   = MatchState.FINISHED,
    }

    assert(validTransitions[self.state] == newState,
        ('invalid state transition: %s -> %s'):format(self.state, newState)
    )

    local oldState = self.state

    self.state = newState

    log('info', ('match %d: state %s -> %s'):format(self.id, oldState, newState))
end

---@param eventName string
---@param ... any
function Match:emitClients(eventName, ...)

    local event = ('net.%s:%s'):format(RESOURCE, eventName)

    for i = 1, #self.playerList do
        TriggerClientEvent(event, self.playerList[i], ...)
    end

    local globalId = self.data and self.data.globalId

    if globalId and Core and Core.matches then

        local entry = Core.matches:getMatch(globalId)

        if entry then

            for src in pairs(entry.spectators) do
                TriggerClientEvent(event, src, ...)
            end
        end
    end
end

---@param squadIndex number
---@param eventName string
---@param ... any
function Match:emitSquad(squadIndex, eventName, ...)

    assert(self.squads[squadIndex], ('squad %d does not exist'):format(squadIndex))

    local event = ('net.%s:%s'):format(RESOURCE, eventName)
    local players = self.squads[squadIndex].players

    for i = 1, #players do
        if self.players[players[i]] then
            TriggerClientEvent(event, players[i], ...)
        end
    end
end

---@param key string
---@return any
function Match:getData(key)

    return self.data[key]
end

---@param key string
---@param value any
function Match:setData(key, value)

    self.data[key] = value
end

---@param src number
---@return PlayerState
function Match:getPlayerState(src)

    assert(self.players[src], ('player %d is not in match %d'):format(src, self.id))

    return self.playerStates[src]
end

---@param src number
---@param state PlayerState
function Match:setPlayerState(src, state)

    assert(self.players[src], ('player %d is not in match %d'):format(src, self.id))

    self.playerStates[src] = state
end

---@param src number
---@return boolean
function Match:hasAliveSquadMates(src)

    local squad = self:getSquad(src)

    if not squad then return false end

    for i = 1, #squad.alive do
        if squad.alive[i] ~= src and self.playerStates[squad.alive[i]] == PlayerState.ALIVE then
            return true
        end
    end

    return false
end

---@param sources number[]
---@return number squadIndex
function Match:addNewSquad(sources)

    local squadIndex = #self.squads + 1

    self.squads[squadIndex] = {
        index = squadIndex,
        players = {},
        alive = {},
    }

    for i = 1, #sources do
        self:_addPlayerToSquad(sources[i], squadIndex)
    end

    return squadIndex
end

---@param src number
---@param squadIndex number
function Match:addPlayerToSquad(src, squadIndex)

    self:_addPlayerToSquad(src, squadIndex)
end

---@param src number
---@param squadIndex number
function Match:_addPlayerToSquad(src, squadIndex)

    self.players[src] = true
    self.playerList[#self.playerList + 1] = src
    self.playerStates[src] = PlayerState.ALIVE
    self.stats[src] = { kills = 0, deaths = 0, downs = 0, revives = 0 }

    local squad = self.squads[squadIndex]

    squad.players[#squad.players + 1] = src
    squad.alive[#squad.alive + 1] = src
    self.playerSquad[src] = squadIndex

    SetPlayerRoutingBucket(tostring(src), self.bucket)
end

function Match:cleanup()

    for i = 1, #self.playerList do
        local src = self.playerList[i]

        if DoesPlayerExist(tostring(src)) then
            SetPlayerRoutingBucket(tostring(src), src)
        end
    end

    Core.releaseBucket(self.bucket)

    if self.state ~= MatchState.FINISHED then
        self.state = MatchState.FINISHED
    end

    log('info', ('match %d: cleanup complete'):format(self.id))
end

_G.Match = Match
