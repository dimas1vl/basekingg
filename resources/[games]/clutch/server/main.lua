while not Core do
    Wait(100)
end

_G.log = Core.log

GM = GameMode.new()

---@param match ClutchMatch
---@return ClutchMap | nil
local function pickMap(match)
    local newMap = match:advanceMap()
    if not newMap then
        match.currentSpawnVariation = nil
        return nil
    end

    local variations
    if newMap.spawns and newMap.spawns[match.variant] then
        variations = newMap.spawns[match.variant].variations
    end

    if variations and #variations > 0 then
        match.currentSpawnVariation = variations[math.random(1, #variations)]
    else
        match.currentSpawnVariation = nil
        log('error', ('clutch match %d: mapa %s nao tem variations para variant=%s'):format(
            match.id, newMap.name or '?', match.variant
        ))
    end

    return newMap
end

---@param sp vector4 | nil
---@return { coords: vector3, heading: number } | nil
local function vec4ToSpawn(sp)
    if not sp then return nil end
    return { coords = vec3(sp.x, sp.y, sp.z), heading = sp.w }
end

---@param pool vector4[] | nil
---@return vector4 | nil
local function pickRandom(pool)
    if not pool or #pool == 0 then return nil end
    return pool[math.random(1, #pool)]
end

---@param match ClutchMatch
---@param src number
---@return { coords: vector3, heading: number } | nil
local function pickSpawn(match, src)
    local map = match:getCurrentMap()
    if not map then return nil end

    local variation = match.currentSpawnVariation
    if not variation then
        log('error', ('clutch match %d: sem currentSpawnVariation no mapa %s (config quebrada?)'):format(
            match.id, map.name or '?'
        ))
        return nil
    end

    if match.variant == '1v1' then
        local idx
        for i, s in ipairs(match.playerList) do
            if s == src then idx = i; break end
        end
        if not idx then return nil end
        local key = (idx == 1) and 'sideA' or 'sideB'
        return vec4ToSpawn(variation[key])
    end

    if match.variant == '1v2' then
        -- shape legado: { clutch = vec4, duo = { vec4, vec4 } }
        if match:isClutchPlayer(src) then
            return vec4ToSpawn(variation.clutch)
        end
        local teamSrcs = match:getTeamSrcs()
        local teamIdx = 0
        for i, s in ipairs(teamSrcs) do
            if s == src then teamIdx = i; break end
        end
        local pool = type(variation.duo) == 'table' and variation.duo or {}
        return vec4ToSpawn(pool[teamIdx] or pool[1])
    end

    if match.variant == '2v4' or match.variant == '3v5' then
        -- shape novo: { clutch = { vec4, vec4, ... }, team = { vec4, vec4, ... } }
        if match:isClutchPlayer(src) then
            local clutchIdx = 0
            for i, s in ipairs(match.clutchSrcs) do
                if s == src then clutchIdx = i; break end
            end
            if clutchIdx == 0 then return nil end
            local pool = type(variation.clutch) == 'table' and variation.clutch or {}
            local sp = pool[clutchIdx] or pool[1]
            if not sp then
                log('error', ('clutch match %d: variation.clutch[%d] nil no mapa %s variant=%s'):format(
                    match.id, clutchIdx, map.name or '?', match.variant
                ))
            end
            return vec4ToSpawn(sp)
        end
        local teamSrcs = match:getTeamSrcs()
        local teamIdx = 0
        for i, s in ipairs(teamSrcs) do
            if s == src then teamIdx = i; break end
        end
        if teamIdx == 0 then return nil end
        local pool = type(variation.team) == 'table' and variation.team or {}
        local sp = pool[teamIdx] or pool[1]
        if not sp then
            log('error', ('clutch match %d: variation.team[%d] nil no mapa %s variant=%s'):format(
                match.id, teamIdx, map.name or '?', match.variant
            ))
        end
        return vec4ToSpawn(sp)
    end

    return nil
end

---@param match ClutchMatch
local function broadcastScoreboard(match)
    match:emitClients('scoreboard', match:getScoreboard())
end

---@param match ClutchMatch
local function broadcastRoundInfo(match)
    local map = match:getCurrentMap()
    match:emitClients('round.info', {
        roundNumber  = match.roundNumber,
        mapName      = map and map.name or '?',
        variant      = match.variant,
        scoreLimit   = match.scoreLimit,
        clutchSrc    = match.clutchSrc,
        clutchSrcs   = match.clutchSrcs,
        scoreboard   = match:getScoreboard(),
        centerX      = map and map.pvpCenter.x or 0.0,
        centerY      = map and map.pvpCenter.y or 0.0,
        centerZ      = map and map.pvpCenter.z or 0.0,
        ipls         = map and map.ipls or {},
        ityps        = map and map.ityps or {},
    })
end

---@param match ClutchMatch
local function broadcastZone(match)
    local map = match:getCurrentMap()
    if not map then return end
    local z = Config.Clutch.zone
    local variation = match.currentSpawnVariation

    local startRadius = (variation and variation.radius) or map.zoneRadius or z.startRadius
    local endRadius   = (variation and variation.endRadius) or map.zoneEndRadius or z.endRadius

    local payload = {
        x           = map.pvpCenter.x,
        y           = map.pvpCenter.y,
        z           = map.pvpCenter.z,
        startRadius = startRadius,
        endRadius   = endRadius,
        shrinkMs    = z.shrinkMs,
        dpsHp       = z.dpsHp,
        tickMs      = z.tickMs,
        startedAt   = GetGameTimer(),
    }
    match:emitClients('zone.start', payload)
end

---@param match ClutchMatch
local function stopZone(match)
    match:emitClients('zone.stop')
end

---@param match ClutchMatch
local function spawnAllForRound(match)
    for i = 1, #match.playerList do
        local src = match.playerList[i]
        local spawn = pickSpawn(match, src)
        if spawn then
            local isClutch = match:isClutchPlayer(src)
            match:emitClient(src, 'round.spawn', {
                coords    = spawn.coords,
                heading   = spawn.heading,
                isClutch  = isClutch,
                freezeMs  = Config.Clutch.freeze.respawnMs,
            })
        end
    end
end

---@param match ClutchMatch
---@param reason string
---@param forfeiterSrc number | nil
local function endMatch(match, reason, forfeiterSrc)
    if match.state == MatchState.ENDING or match.state == MatchState.FINISHED then return end

    match:setState(MatchState.ENDING)
    stopZone(match)

    local winner = match:getWinner() or match:getLeader()

    match:emitClients('match.result', {
        winnerSrc    = winner and winner.src or nil,
        winnerName   = winner and winner.name or nil,
        winnerScore  = winner and winner.score or 0,
        scoreboard   = match:getScoreboard(),
        reason       = reason,
        forfeiterSrc = forfeiterSrc,
        showMs       = Config.Clutch.matchEndShowMs,
    })

    log('info', ('clutch match %d: ending reason=%s winner=%s forfeiter=%s'):format(
        match.id, reason, winner and winner.name or '?', tostring(forfeiterSrc or '-')
    ))

    SetTimeout(Config.Clutch.matchEndShowMs, function()
        if not GM.matches[match.id] then return end
        GM:destroyMatch(match.id)
    end)
end

---@param match ClutchMatch
local function startNextRound(match)
    if match.state ~= MatchState.STARTED then return end
    if match:hasWinner() then
        endMatch(match, 'score')
        return
    end

    match.roundNumber  = match.roundNumber + 1
    match.roundEnding  = false
    match.lastMapName  = match.currentMap and match.currentMap.name or nil
    match:resetRoundKills()

    local map = pickMap(match)
    if not map then
        log('error', ('clutch match %d: no map available'):format(match.id))
        endMatch(match, 'error')
        return
    end

    match.roundStartedAt = GetGameTimer()
    match:setPhase(RoundPhase.FREEZE)

    match:resetAlive()
    broadcastRoundInfo(match)
    spawnAllForRound(match)

    local rn = match.roundNumber
    SetTimeout(Config.Clutch.freeze.respawnMs, function()
        if match.state ~= MatchState.STARTED then return end
        if match.roundNumber ~= rn then return end
        if match.roundEnding then return end
        match:setPhase(RoundPhase.FIGHTING)
        match:emitClients('round.fightStart')
        broadcastZone(match)
    end)
end

---@param match ClutchMatch
---@param winnerSrc number | nil
---@param newClutchSrcs number[] | nil  -- nil = mantem o time clutch atual
local function endRound(match, winnerSrc, newClutchSrcs)
    if match.roundEnding then return end
    match.roundEnding = true
    match:setPhase(RoundPhase.RESULT)
    stopZone(match)

    if winnerSrc then
        match:addScore(winnerSrc)
    end
    if newClutchSrcs ~= nil then
        match:setClutchSrcs(newClutchSrcs)
    end

    local winnerPlayer = winnerSrc and match:getPlayer(winnerSrc) or nil
    local newClutchNames = {}
    if newClutchSrcs then
        for i = 1, #newClutchSrcs do
            local p = match:getPlayer(newClutchSrcs[i])
            if p then newClutchNames[#newClutchNames + 1] = p.name end
        end
    end

    match:emitClients('round.result', {
        roundNumber    = match.roundNumber,
        winnerSrc      = winnerSrc,
        winnerName     = winnerPlayer and winnerPlayer.name or nil,
        newClutchSrc   = newClutchSrcs and newClutchSrcs[1] or nil, -- legado
        newClutchSrcs  = newClutchSrcs,
        newClutchName  = newClutchNames[1],                          -- legado
        newClutchNames = newClutchNames,
        scoreboard     = match:getScoreboard(),
        showMs         = Config.Clutch.roundResultShowMs,
    })

    broadcastScoreboard(match)

    log('info', ('clutch match %d round %d: winner=%s newClutchers=%s'):format(
        match.id, match.roundNumber,
        winnerPlayer and winnerPlayer.name or '-',
        #newClutchNames > 0 and table.concat(newClutchNames, ', ') or '-'
    ))

    SetTimeout(Config.Clutch.roundResultShowMs, function()
        if match.state ~= MatchState.STARTED then return end
        startNextRound(match)
    end)
end

GM:on('matchCreated', function(match)
    log('info', ('clutch match %d: starting (variant=%s players=%d)'):format(
        match.id, match.variant, #match.playerList
    ))

    match:setState(MatchState.STARTED)
    match:emitClients('match.stateChange', MatchState.STARTED)

    local variantCfg = Config.Clutch.variants[match.variant]
    local initialClutchSize = (variantCfg and variantCfg.clutchSize) or 0
    if initialClutchSize > 0 then
        local initial = match:pickInitialClutchers(initialClutchSize)
        match:setClutchSrcs(initial)
        local names = {}
        for i = 1, #initial do
            local p = match:getPlayer(initial[i])
            names[#names + 1] = p and p.name or ('src#' .. initial[i])
        end
        log('info', ('clutch match %d: initial clutchers (%d) = %s'):format(
            match.id, #initial, table.concat(names, ', ')
        ))
    end

    broadcastScoreboard(match)
    SetTimeout(Config.Clutch.freeze.matchStartMs, function()
        if match.state ~= MatchState.STARTED then return end
        startNextRound(match)
    end)
end)

GM:registerNetEvent('playerDeath', function(match, src, killerSrc, weaponHash)
    if match.state ~= MatchState.STARTED then return end
    if match.phase ~= RoundPhase.FIGHTING then return end
    if match.roundEnding then return end

    local victimSrc = src

    local k = tonumber(killerSrc)
    if k == 0 then k = nil end
    if k and not match:getPlayer(k) then k = nil end
    local killerPlayer = k and match:getPlayer(k) or nil
    if killerPlayer and not killerPlayer.alive then
        k = nil
        killerPlayer = nil
    end

    local victim = match:getPlayer(victimSrc)
    if not victim then return end
    if not victim.alive then return end

    match:markDead(victimSrc)
    if k then match:recordKill(k) end

    match:emitClients('killFeed', {
        killerSrc  = k,
        killerName = killerPlayer and killerPlayer.name or nil,
        victimSrc  = victimSrc,
        victimName = victim.name,
        weapon     = weaponHash,
    })

    if match.variant == '1v1' then
        if k then
            endRound(match, k, nil)
        else
            endRound(match, nil, nil)
        end
        return
    end

    local variantCfg = Config.Clutch.variants[match.variant]
    if variantCfg and variantCfg.hasClutchRole then
        local clutchSize = variantCfg.clutchSize or 1

        if match:isClutchPlayer(victimSrc) then
            -- um clutcher morreu. so muda time se TODOS clutchers morreram.
            if match:allClutchDead() then
                -- team venceu o round → escolhe N novos clutchers pela regra de prioridade
                local nextClutchers = match:pickNextClutchers(clutchSize)
                endRound(match, nil, nextClutchers)
            end
            return
        end

        -- um membro do team morreu
        if match:allTeamDead() then
            -- clutch venceu o round → mantem time (passa nil), score pro killer (ou 1o clutcher se gas)
            local winner = k
            if not winner and #match.clutchSrcs > 0 then
                winner = match.clutchSrcs[1]
            end
            endRound(match, winner, nil)
        end
        return
    end
end)

GM:on('matchEnded', function(match, reason, forfeiterSrc)
    endMatch(match, reason or 'forfeit', forfeiterSrc)
end)

exports('canStart', function(mode, variant, playerCount)
    if mode ~= Config.Clutch.mode then return false end
    local v = Config.Clutch.variants and Config.Clutch.variants[variant]
    if not v then return false end
    if playerCount and playerCount ~= v.totalPlayers then return false end
    return true
end)

exports('getExpectedPlayers', function(variant)
    local v = Config.Clutch.variants and Config.Clutch.variants[variant]
    return v and v.totalPlayers or 0
end)

RegisterCommand('clutch_force_start', function(src, args)
    src = tonumber(src) or 0
    if src == 0 then
        print('[clutch] clutch_force_start: console nao suportado')
        return
    end

    if GM:getPlayerMatch(src) then
        TriggerClientEvent('Notify', src, 'error', 'Voce ja esta em uma partida Clutch.', 5)
        return
    end

    local roomVariant, roomScoreLimit
    pcall(function()
        local room = exports['lobby_minigames']:getRoomByPlayer(src)
        if room and room.gameMode == 'clutch' then
            roomVariant    = room.variant
            roomScoreLimit = room.scoreLimit
        end
    end)

    local variant    = (args and args[1]) or roomVariant or '1v1'
    local scoreLimit = tonumber(args and args[2]) or roomScoreLimit or Config.Clutch.scoreLimit
    if not Config.Clutch.variants[variant] then
        TriggerClientEvent('Notify', src, 'error', 'Variante invalida. Use: /clutch_force_start 1v1 [rounds]', 6)
        return
    end
    if scoreLimit < 1 then scoreLimit = 1 end
    if scoreLimit > 10 then scoreLimit = 10 end

    pcall(function()
        if exports['lobby_minigames']:getRoomByPlayer(src) then
            exports['lobby_minigames']:removePlayerFromRoom(src)
        end
    end)

    local wasInArea = false
    pcall(function()
        wasInArea = exports['lobby_minigames']:isInArea(src) == true
    end)
    if wasInArea then
        TriggerClientEvent('lobby_minigames:handover', src)
    end
    pcall(function() exports['lobby_minigames']:releaseSession(src) end)

    TriggerClientEvent('lobby:closeLobby', src)

    local source = (roomVariant or roomScoreLimit) and 'sala' or 'default'
    print(('^5[clutch] FORCE START src=%d variant=%s rounds=%d source=%s (validations bypassed)^7'):format(src, variant, scoreLimit, source))
    TriggerClientEvent('Notify', src, 'success', ('[FORCE START] Clutch %s · ate %d round%s (%s)'):format(
        variant:upper(), scoreLimit, scoreLimit == 1 and '' or 's', source
    ), 5)

    SetTimeout(300, function()
        if not DoesPlayerExist(tostring(src)) then return end
        GM:createMatch({ src }, Config.Clutch.mode, variant, { scoreLimit = scoreLimit })
    end)
end, false)

GM:on('playerLeft', function(match, src)
    broadcastScoreboard(match)
end)

GM:registerNetEvent('leaveMatch', function(match, src)
    GM:onPlayerLeave(src)
end)
