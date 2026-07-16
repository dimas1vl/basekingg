local RESOURCE = GetCurrentResourceName()

local SHARED_BUCKET = nil

local function getSharedBucket()
    if not SHARED_BUCKET then
        SHARED_BUCKET = Core.allocateBucket()
    end
    return SHARED_BUCKET
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if SHARED_BUCKET then
        Core.releaseBucket(SHARED_BUCKET)
        SHARED_BUCKET = nil
    end
end)

---@class MMPlayerStats
---@field src number
---@field kills number
---@field deaths number
---@field streak number
---@field bestStreak number
---@field name string

---@class Match
---@field id number
---@field mode string
---@field subMode string
---@field squadType string
---@field state MatchState
---@field players table<number, true>
---@field playerList number[]
---@field stats table<number, MMPlayerStats>
---@field bucket number
---@field createdAt number
---@field startedAt number | nil
---@field data table
local Match = {}
Match.__index = Match

---@param id number
---@param batch number[]
---@param mode string
---@param subMode string
---@param squadType string
---@return Match
function Match.new(id, batch, mode, subMode, squadType)

    assert(type(batch) == 'table' and #batch > 0, 'batch must be a non-empty array')

    local self = setmetatable({
        id = id,
        mode = mode,
        subMode = subMode,
        squadType = squadType,
        state = MatchState.WAITING,
        players = {},
        playerList = {},
        stats = {},
        bucket = getSharedBucket(),
        createdAt = GetGameTimer(),
        startedAt = nil,
        data = {},
    }, Match)

    for i = 1, #batch do
        self:addPlayer(batch[i])
    end

    log('info', ('match %d created: mode=%s subMode=%s players=%d bucket=%d'):format(
        id, mode, subMode, #batch, self.bucket
    ))

    return self
end

---@param src number
function Match:addPlayer(src)

    if self.players[src] then return end

    self.players[src] = true
    self.playerList[#self.playerList + 1] = src

    local userInfo = Core.getUserInfo(src)

    self.stats[src] = {
        src        = src,
        kills      = 0,
        deaths     = 0,
        streak     = 0,
        bestStreak = 0,
        name       = (userInfo and userInfo.name) or GetPlayerName(src) or ('Player#'..src),
    }

    SetPlayerRoutingBucket(tostring(src), self.bucket)
end

---@param src number
---@return boolean
function Match:removePlayer(src)

    if not self.players[src] then return false end

    self.players[src] = nil
    self.stats[src]   = nil

    for i = #self.playerList, 1, -1 do
        if self.playerList[i] == src then
            table.remove(self.playerList, i)
            break
        end
    end

    if DoesPlayerExist(tostring(src)) then
        SetPlayerRoutingBucket(tostring(src), src)
    end

    log('info', ('match %d: player %d removed (remaining=%d)'):format(self.id, src, #self.playerList))

    return true
end

---@param src number
---@return boolean
function Match:isPlayer(src)

    return self.players[src] == true
end

---@param killerSrc number | nil
---@param victimSrc number
---@return MMPlayerStats | nil
---@return MMPlayerStats
function Match:registerKill(killerSrc, victimSrc)

    local victim = self.stats[victimSrc]

    assert(victim, ('victim %d not in match %d'):format(victimSrc, self.id))

    victim.deaths = victim.deaths + 1
    victim.streak = 0

    local killer = nil

    if killerSrc and killerSrc ~= victimSrc and self.stats[killerSrc] then
        killer = self.stats[killerSrc]
        killer.kills  = killer.kills + 1
        killer.streak = killer.streak + 1
        if killer.streak > killer.bestStreak then
            killer.bestStreak = killer.streak
        end
    end

    return killer, victim
end

---@return MMPlayerStats[]
function Match:getScoreboard()

    local list = {}

    for _, s in pairs(self.stats) do
        list[#list + 1] = {
            src        = s.src,
            kills      = s.kills,
            deaths     = s.deaths,
            streak     = s.streak,
            bestStreak = s.bestStreak,
            name       = s.name,
        }
    end

    table.sort(list, function(a, b)
        if a.kills == b.kills then return a.deaths < b.deaths end
        return a.kills > b.kills
    end)

    return list
end

---@return MMPlayerStats | nil
function Match:getLeader()

    local best

    for _, s in pairs(self.stats) do
        if not best or s.kills > best.kills then best = s end
    end

    return best
end

---@param newState MatchState
function Match:setState(newState)

    local validTransitions = {
        [MatchState.WAITING] = MatchState.STARTED,
        [MatchState.STARTED] = MatchState.ENDING,
        [MatchState.ENDING]  = MatchState.FINISHED,
    }

    assert(validTransitions[self.state] == newState,
        ('invalid state transition: %s -> %s'):format(self.state, newState))

    local oldState = self.state

    self.state = newState

    if newState == MatchState.STARTED then
        self.startedAt = GetGameTimer()
    end

    log('info', ('match %d: state %s -> %s'):format(self.id, oldState, newState))
end

---@param eventName string
function Match:emitClients(eventName, ...)

    local event = ('net.%s:%s'):format(RESOURCE, eventName)

    for i = 1, #self.playerList do
        TriggerClientEvent(event, self.playerList[i], ...)
    end
end

---@param src number
---@param eventName string
function Match:emitClient(src, eventName, ...)

    if not self.players[src] then return end

    TriggerClientEvent(('net.%s:%s'):format(RESOURCE, eventName), src, ...)
end

function Match:cleanup()

    for i = 1, #self.playerList do
        local src = self.playerList[i]
        if DoesPlayerExist(tostring(src)) then
            SetPlayerRoutingBucket(tostring(src), src)
        end
    end


    if self.state ~= MatchState.FINISHED then
        self.state = MatchState.FINISHED
    end

    log('info', ('match %d: cleanup complete'):format(self.id))
end

_G.Match = Match
