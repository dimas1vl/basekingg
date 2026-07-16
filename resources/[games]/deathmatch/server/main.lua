while not Core do
    Wait(100)
end

_G.log = Core.log

GM = GameMode.new()

---@param match Match
---@return { coords: vector3, heading: number } | nil
local function pickSpawn(match)
    local map = match:getCurrentMap()
    if not map or not map.spawnPoints or #map.spawnPoints == 0 then return nil end
    local sp = map.spawnPoints[math.random(1, #map.spawnPoints)]
    return { coords = vec3(sp.x, sp.y, sp.z), heading = sp.w }
end

local function broadcastScoreboard(match)
    match:emitClients('scoreboard', match:getScoreboard())
end

local function startZone(match)
    local map = match:getCurrentMap()
    local zn  = map and map.zone
    if not zn or not zn.enabled then return end

    local payload = {
        x                = map.pvpCenter.x,
        y                = map.pvpCenter.y,
        z                = map.pvpCenter.z,
        radius           = zn.radius or 150.0,
        outsideRespawnMs = Config.Deathmatch.zoneOutsideRespawnMs or 1500,
    }
    for i = 1, #match.playerList do
        TriggerClientEvent('dm:zone:start', match.playerList[i], payload)
    end
    log('info', ('DM match %d: zone(%s) radius=%.0f'):format(match.id, map.name, payload.radius))
end

---@param match Match
local function stopZone(match)
    for i = 1, #match.playerList do
        TriggerClientEvent('dm:zone:stop', match.playerList[i])
    end
end

---@param match Match
local function spawnAllInCurrentMap(match)
    for i = 1, #match.playerList do
        local src   = match.playerList[i]
        local spawn = pickSpawn(match)
        if spawn then
            match:emitClient(src, 'spawn', spawn.coords, spawn.heading)
        end
    end
end

---@param match Match
local function scheduleMapTimer(match)
    match.mapStartedAt = GetGameTimer()
    local thisMapIndex = match.currentMapIndex

    SetTimeout(Config.Deathmatch.mapTimeLimitMs, function()
        if match.state ~= MatchState.STARTED then return end
        if match.currentMapIndex ~= thisMapIndex then return end
        if match.mapEnding then return end
        GM:emit('mapEnded', match, 'time')
    end)
end

---@param match Match
local function broadcastMapInfo(match)
    local map  = match:getCurrentMap()
    local next = match:getNextMap()

    local limit     = Config.Deathmatch.mapTimeLimitMs
    local startedAt = match.mapStartedAt or GetGameTimer()
    local elapsed   = GetGameTimer() - startedAt
    local remaining = math.max(0, limit - elapsed)

    match:emitClients('mapInfo', {
        index       = match.currentMapIndex,
        total       = Config.Deathmatch:mapCount(match.subMode),
        name        = map and map.name or '?',
        nextName    = next and next.name or '?',
        timeLimitMs = limit,
        remainingMs = remaining,
        scoreLimit  = Config.Deathmatch.scoreLimit,
        ipls        = map and map.ipls or {},
        ityps       = map and map.ityps or {},
        centerX     = map and map.pvpCenter and map.pvpCenter.x or 0.0,
        centerY     = map and map.pvpCenter and map.pvpCenter.y or 0.0,
        centerZ     = map and map.pvpCenter and map.pvpCenter.z or 0.0,
    })
end

GM:on('matchCreated', function(match)

    log('info', ('DM match %d: starting (%d players) on map "%s"'):format(
        match.id, #match.playerList, (match:getCurrentMap() or {}).name or '?'
    ))

    match:setState(MatchState.STARTED)
    match:emitClients('match.stateChange', MatchState.STARTED)

    match.mapStartedAt = GetGameTimer()
    broadcastMapInfo(match)
    spawnAllInCurrentMap(match)

    broadcastScoreboard(match)
    GM:emit('matchStarted', match)

    local matchId = match.id
    CreateThread(function()
        while GM:getMatch(matchId) do
            local m = GM:getMatch(matchId)
            if m and m.state == MatchState.STARTED then
                broadcastScoreboard(m)
            end
            Wait(2000)
        end
    end)

    SetTimeout(1500, function()
        if match.state ~= MatchState.STARTED then return end
        if match.mapEnding then return end
        broadcastMapInfo(match)
        broadcastScoreboard(match)
    end)
end)

local function buildZonePayload(match)
    local map = match:getCurrentMap()
    local zn  = map and map.zone
    if not zn or not zn.enabled then return nil end
    return {
        x                = map.pvpCenter.x,
        y                = map.pvpCenter.y,
        z                = map.pvpCenter.z,
        radius           = zn.radius or 150.0,
        outsideRespawnMs = Config.Deathmatch.zoneOutsideRespawnMs or 1500,
    }
end

GM:on('playerJoined', function(match, src)
    if match.mapEnding or match.state ~= MatchState.STARTED then return end
    log('info', ('DM match %d: player %d joined mid-match'):format(match.id, src))

    local map = match:getCurrentMap()
    local nextMap = match:getNextMap()
    local limit = Config.Deathmatch.mapTimeLimitMs
    local elapsed = GetGameTimer() - (match.mapStartedAt or GetGameTimer())
    match:emitClient(src, 'mapInfo', {
        index       = match.currentMapIndex,
        total       = Config.Deathmatch:mapCount(match.subMode),
        name        = map and map.name or '?',
        nextName    = nextMap and nextMap.name or '?',
        timeLimitMs = limit,
        remainingMs = math.max(0, limit - elapsed),
        scoreLimit  = Config.Deathmatch.scoreLimit,
        ipls        = map and map.ipls or {},
        ityps       = map and map.ityps or {},
        centerX     = map and map.pvpCenter and map.pvpCenter.x or 0.0,
        centerY     = map and map.pvpCenter and map.pvpCenter.y or 0.0,
        centerZ     = map and map.pvpCenter and map.pvpCenter.z or 0.0,
    })

    local spawn = pickSpawn(match)
    if spawn then
        match:emitClient(src, 'spawn', spawn.coords, spawn.heading)
    end

    local zonePayload = buildZonePayload(match)
    if zonePayload then
        TriggerClientEvent('dm:zone:start', src, zonePayload)
    end
end)

GM:on('batchJoined', function(match, joined)
    broadcastScoreboard(match)
end)

GM:on('matchStarted', function(match)
    log('info', ('DM match %d: started on map "%s"'):format(
        match.id, (match:getCurrentMap() or {}).name or '?'
    ))
    startZone(match)
    scheduleMapTimer(match)
end)

GM:registerNetEvent('playerDeath', function(match, victimSrc, killerSrc, weaponHash)

    if match.state ~= MatchState.STARTED then return end
    if match.mapEnding then return end

    local k = tonumber(killerSrc)
    if k == 0 then k = nil end

    local killer, victim = match:registerKill(k, victimSrc)

    match:emitClients('killFeed', {
        killerSrc  = killer and killer.src or nil,
        killerName = killer and killer.name or nil,
        victimSrc  = victim.src,
        victimName = victim.name,
        weapon     = weaponHash,
        streak     = killer and killer.streak or 0,
    })

    broadcastScoreboard(match)

    SetTimeout(Config.Deathmatch.respawnDelayMs, function()
        if match.state ~= MatchState.STARTED then return end
        if match.mapEnding then return end
        if not match:isPlayer(victimSrc) then return end
        local spawn = pickSpawn(match)
        if spawn then
            match:emitClient(victimSrc, 'spawn', spawn.coords, spawn.heading)
        end
    end)

    if killer and killer.kills >= Config.Deathmatch.scoreLimit then
        GM:emit('mapEnded', match, 'score')
    end
end)

---@param match Match
---@param reason 'time' | 'score' | string
GM:on('mapEnded', function(match, reason)

    if match.mapEnding then return end
    match.mapEnding = true

    local map    = match:getCurrentMap()
    local leader = match:getLeader()

    log('info', ('DM match %d: map "%s" ended (%s, leader=%s kills=%d)'):format(
        match.id, map and map.name or '?', reason,
        leader and leader.name or '?', leader and leader.kills or 0
    ))

    stopZone(match)

    match:emitClients('mapResult', {
        mapName     = map and map.name or '?',
        nextMapName = (match:getNextMap() or {}).name or '?',
        leaderSrc   = leader and leader.src or nil,
        leaderName  = leader and leader.name or nil,
        leaderKills = leader and leader.kills or 0,
        scoreboard  = match:getScoreboard(),
        showMs      = Config.Deathmatch.mapEndShowMs,
        reason      = reason,
    })

    SetTimeout(Config.Deathmatch.mapEndShowMs, function()
        if match.state ~= MatchState.STARTED then return end

        match:advanceMap()
        match:resetMapStats()

        broadcastMapInfo(match)
        broadcastScoreboard(match)
        startZone(match)
        spawnAllInCurrentMap(match)
        scheduleMapTimer(match)
    end)
end)

GM:on('matchFinished', function(match)
    log('info', ('DM match %d: finished and cleaned up'):format(match.id))
end)

GM:on('playerLeft', function(match, src)
    log('info', ('DM match %d: player %d left'):format(match.id, src))
    broadcastScoreboard(match)
end)

GM:registerNetEvent('requestZoneRespawn', function(match, src)
    log('info', ('DM match %d: player %d zone-respawn req (state=%s, mapEnding=%s)'):format(
        match.id, src, tostring(match.state), tostring(match.mapEnding)
    ))
    if match.state ~= MatchState.STARTED then return end
    if match.mapEnding then return end
    if not match:isPlayer(src) then return end

    local spawn = pickSpawn(match)
    if spawn then
        match:emitClient(src, 'spawn', spawn.coords, spawn.heading)
        log('info', ('DM match %d: teleported %d back to arena'):format(match.id, src))
    end
end)

GM:registerNetEvent('leaveMatch', function(match, src)
    log('info', ('DM match %d: player %d requested leave'):format(match.id, src))
    GM:onPlayerLeave(src)
end)
