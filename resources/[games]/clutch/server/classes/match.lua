local RESOURCE = GetCurrentResourceName()

---@class ClutchPlayer
---@field src number
---@field name string
---@field alive boolean
---@field score integer

---@class ClutchMatch
---@field id number
---@field mode string
---@field variant string
---@field scoreLimit number
---@field state MatchState
---@field phase RoundPhase
---@field players table<number, ClutchPlayer>
---@field playerList number[]
---@field bucket number
---@field createdAt number
---@field startedAt number | nil
---@field roundNumber integer
---@field roundStartedAt number | nil
---@field roundEnding boolean
---@field currentMap ClutchMap | nil
---@field currentSpawnVariation table | nil
---@field lastMapName string | nil
---@field clutchSrcs number[]
---@field clutchSet table<number, boolean>
---@field clutchSrc number | nil  -- legado: 1o do clutchSrcs (mantido pra HUD web atual)
---@field killsThisRound table<number, number>
---@field data table
local Match = {}
Match.__index = Match

---@param id number
---@param batch number[]
---@param mode string
---@param variant string
---@param options table | nil
---@return ClutchMatch
function Match.new(id, batch, mode, variant, options)
    assert(type(batch) == 'table' and #batch > 0, 'batch must be a non-empty array')

    local scoreLimit = options and tonumber(options.scoreLimit) or Config.Clutch.scoreLimit
    if scoreLimit < 1 then scoreLimit = 1 end
    if scoreLimit > 10 then scoreLimit = 10 end

    local self = setmetatable({
        id            = id,
        mode          = mode,
        variant       = variant,
        scoreLimit    = scoreLimit,
        state         = MatchState.WAITING,
        phase         = RoundPhase.FREEZE,
        players       = {},
        playerList    = {},
        bucket        = Core.allocateBucket(),
        createdAt     = GetGameTimer(),
        startedAt     = nil,
        roundNumber   = 0,
        roundStartedAt = nil,
        roundEnding   = false,
        currentMap    = nil,
        currentSpawnVariation = nil,
        lastMapName   = nil,
        clutchSrcs    = {},
        clutchSet     = {},
        clutchSrc     = nil,
        killsThisRound = {},
        data          = {},
    }, Match)

    for i = 1, #batch do
        self:addPlayer(batch[i])
    end

    log('info', ('clutch match %d created: variant=%s players=%d bucket=%d'):format(
        id, variant, #batch, self.bucket
    ))

    return self
end

---@param src number
function Match:addPlayer(src)
    if self.players[src] then return end

    local userInfo = Core.getUserInfo and Core.getUserInfo(src)

    self.players[src] = {
        src   = src,
        name  = (userInfo and userInfo.name) or GetPlayerName(src) or ('Player#' .. src),
        alive = true,
        score = 0,
    }
    self.playerList[#self.playerList + 1] = src

    SetPlayerRoutingBucket(tostring(src), self.bucket)
end

---@param src number
---@return boolean
function Match:removePlayer(src)
    if not self.players[src] then return false end

    self.players[src] = nil
    for i = #self.playerList, 1, -1 do
        if self.playerList[i] == src then
            table.remove(self.playerList, i)
            break
        end
    end

    if self.clutchSet[src] then
        self.clutchSet[src] = nil
        for i = #self.clutchSrcs, 1, -1 do
            if self.clutchSrcs[i] == src then
                table.remove(self.clutchSrcs, i)
                break
            end
        end
    end
    self.clutchSrc = self.clutchSrcs[1]
    self.killsThisRound[src] = nil

    if DoesPlayerExist(tostring(src)) then
        SetPlayerRoutingBucket(tostring(src), 0)
    end

    return true
end

---@param src number
---@return boolean
function Match:isPlayer(src)
    return self.players[src] ~= nil
end

---@param src number
---@return ClutchPlayer | nil
function Match:getPlayer(src)
    return self.players[src]
end

---@return ClutchPlayer[]
function Match:getScoreboard()
    local list = {}
    for _, p in pairs(self.players) do
        list[#list + 1] = {
            src   = p.src,
            name  = p.name,
            score = p.score,
            alive = p.alive,
        }
    end
    table.sort(list, function(a, b)
        if a.score == b.score then return a.name < b.name end
        return a.score > b.score
    end)
    return list
end

---@param src number
function Match:addScore(src)
    local p = self.players[src]
    if not p then return end
    p.score = p.score + 1
end

---@return ClutchPlayer | nil
function Match:getLeader()
    local best
    for _, p in pairs(self.players) do
        if not best or p.score > best.score then best = p end
    end
    return best
end

---@return boolean
function Match:hasWinner()
    for _, p in pairs(self.players) do
        if p.score >= self.scoreLimit then return true end
    end
    return false
end

---@return ClutchPlayer | nil
function Match:getWinner()
    for _, p in pairs(self.players) do
        if p.score >= self.scoreLimit then return p end
    end
    return nil
end

function Match:resetAlive()
    for _, p in pairs(self.players) do
        p.alive = true
    end
end

---@param src number
function Match:markDead(src)
    local p = self.players[src]
    if not p then return end
    p.alive = false
end

---@return number[]
function Match:getAliveSrcs()
    local out = {}
    for _, p in pairs(self.players) do
        if p.alive then out[#out + 1] = p.src end
    end
    return out
end

---@param src number
---@return boolean
function Match:isClutchPlayer(src)
    return self.clutchSet[src] == true
end

---@return number[]
function Match:getClutchSrcs()
    local out = {}
    for i = 1, #self.clutchSrcs do out[i] = self.clutchSrcs[i] end
    return out
end

---@return number[]  jogadores que NAO sao clutch (o "team")
function Match:getTeamSrcs()
    local out = {}
    for _, p in pairs(self.players) do
        if not self.clutchSet[p.src] then out[#out + 1] = p.src end
    end
    return out
end

---@return number[] legado — mesmo que getTeamSrcs (mantido pra compat com codigo do 1v2)
function Match:getDuoSrcs()
    return self:getTeamSrcs()
end

---@return boolean true quando todos os clutchers estao mortos
function Match:allClutchDead()
    if #self.clutchSrcs == 0 then return false end
    for i = 1, #self.clutchSrcs do
        local p = self.players[self.clutchSrcs[i]]
        if p and p.alive then return false end
    end
    return true
end

---@return boolean true quando todos do team estao mortos
function Match:allTeamDead()
    local anyTeam = false
    for _, p in pairs(self.players) do
        if not self.clutchSet[p.src] then
            anyTeam = true
            if p.alive then return false end
        end
    end
    return anyTeam
end

---@return boolean legado (1v2): alias pra allTeamDead
function Match:allDuoDead()
    return self:allTeamDead()
end

---@param srcs number[]
function Match:setClutchSrcs(srcs)
    self.clutchSrcs = {}
    self.clutchSet  = {}
    if type(srcs) == 'table' then
        for i = 1, #srcs do
            local s = srcs[i]
            if s and not self.clutchSet[s] then
                self.clutchSrcs[#self.clutchSrcs + 1] = s
                self.clutchSet[s] = true
            end
        end
    end
    self.clutchSrc = self.clutchSrcs[1]
end

---@param src number | nil legado (1v2): alias pra setClutchSrcs({src})
function Match:setClutch(src)
    if src then self:setClutchSrcs({ src }) else self:setClutchSrcs({}) end
end

---@param killerSrc number
function Match:recordKill(killerSrc)
    if not killerSrc then return end
    self.killsThisRound[killerSrc] = (self.killsThisRound[killerSrc] or 0) + 1
end

function Match:resetRoundKills()
    self.killsThisRound = {}
end

---@param n integer quantos clutchers preciso
---@return number[] srcs escolhidos por: alive+killer (mais kills primeiro) > alive+sem-kill (random) > dead+killer > dead+sem-kill
function Match:pickNextClutchers(n)
    if n <= 0 then return {} end

    local function bucket(filterAlive, filterKiller)
        local list = {}
        for _, p in pairs(self.players) do
            if not self.clutchSet[p.src] then
                local isAlive  = p.alive == true
                local isKiller = (self.killsThisRound[p.src] or 0) > 0
                if isAlive == filterAlive and isKiller == filterKiller then
                    -- chave random pre-atribuida → sort deterministico (strict weak order)
                    list[#list + 1] = { src = p.src, key = math.random() }
                end
            end
        end
        return list
    end

    -- sort por kills desc, ties quebrados pela chave random (estavel pro table.sort)
    local function sortByKills(list)
        table.sort(list, function(a, b)
            local ka = self.killsThisRound[a.src] or 0
            local kb = self.killsThisRound[b.src] or 0
            if ka ~= kb then return ka > kb end
            return a.key < b.key
        end)
    end

    local function sortByRandom(list)
        table.sort(list, function(a, b) return a.key < b.key end)
    end

    local aliveKillers    = bucket(true,  true)   ; sortByKills(aliveKillers)
    local aliveNonKillers = bucket(true,  false)  ; sortByRandom(aliveNonKillers)
    local deadKillers     = bucket(false, true)   ; sortByKills(deadKillers)
    local deadNonKillers  = bucket(false, false)  ; sortByRandom(deadNonKillers)

    local picks = {}
    local function take(list)
        for i = 1, #list do
            if #picks >= n then return end
            picks[#picks + 1] = list[i].src
        end
    end
    take(aliveKillers)
    take(aliveNonKillers)
    take(deadKillers)
    take(deadNonKillers)
    return picks
end

---@param n integer quantos clutchers no inicio da partida
---@return number[] N players random do roster
function Match:pickInitialClutchers(n)
    if n <= 0 then return {} end
    local pool = {}
    for i = 1, #self.playerList do pool[i] = self.playerList[i] end
    for i = #pool, 2, -1 do
        local j = math.random(1, i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    local picks = {}
    for i = 1, math.min(n, #pool) do picks[i] = pool[i] end
    return picks
end

---@return ClutchMap | nil
function Match:advanceMap()
    local nextMap = Config.Clutch:pickRandomMap(self.lastMapName)
    if not nextMap then return nil end
    self.currentMap = nextMap
    return nextMap
end

---@return ClutchMap | nil
function Match:getCurrentMap()
    return self.currentMap
end

---@param newState MatchState
---@return boolean
function Match:setState(newState)
    local validTransitions = {
        [MatchState.WAITING] = MatchState.STARTED,
        [MatchState.STARTED] = MatchState.ENDING,
        [MatchState.ENDING]  = MatchState.FINISHED,
    }
    if validTransitions[self.state] ~= newState then
        log('error', ('clutch match %d: invalid state transition %s -> %s (ignored)'):format(
            self.id, tostring(self.state), tostring(newState)
        ))
        return false
    end

    local oldState = self.state
    self.state = newState
    if newState == MatchState.STARTED then
        self.startedAt = GetGameTimer()
    end
    log('info', ('clutch match %d: state %s -> %s'):format(self.id, oldState, newState))
    return true
end

---@param phase RoundPhase
function Match:setPhase(phase)
    self.phase = phase
end

---@param eventName string
---@param ... any
function Match:emitClients(eventName, ...)
    local event = ('net.%s:%s'):format(RESOURCE, eventName)
    for i = 1, #self.playerList do
        TriggerClientEvent(event, self.playerList[i], ...)
    end
end

---@param src number
---@param eventName string
---@param ... any
function Match:emitClient(src, eventName, ...)
    if not self.players[src] then return end
    TriggerClientEvent(('net.%s:%s'):format(RESOURCE, eventName), src, ...)
end

function Match:cleanup()
    for i = 1, #self.playerList do
        local src = self.playerList[i]
        if DoesPlayerExist(tostring(src)) then
            SetPlayerRoutingBucket(tostring(src), 0)
        end
    end
    Core.releaseBucket(self.bucket)
    if self.state ~= MatchState.FINISHED then
        self.state = MatchState.FINISHED
    end
    log('info', ('clutch match %d: cleanup complete'):format(self.id))
end

_G.Match = Match
