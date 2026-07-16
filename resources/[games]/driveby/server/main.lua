while not Core do
    Wait(100)
end

_G.log = Core.log

local cfg = Config.DriveBy

GM = GameMode.new()

---@return { coords: vector3, heading: number }
local function pickSpawn()

    local list = cfg.spawnPoints

    return list[math.random(1, #list)]
end

---@param match Match
local function broadcastScoreboard(match)

    match:emitClients('scoreboard', match:getScoreboard())
end

GM:on('matchCreated', function(match)

    log('info', ('DriveBy match %d: starting (%d players)'):format(match.id, #match.playerList))

    match:setState(MatchState.STARTED)
    match:emitClients('match.stateChange', MatchState.STARTED)

    for i = 1, #match.playerList do
        local src = match.playerList[i]
        local spawn = pickSpawn()
        match:emitClient(src, 'spawn', spawn.coords, spawn.heading)
    end

    broadcastScoreboard(match)

    GM:emit('matchStarted', match)
end)

---@param match Match
local function startZone(match)
    if not cfg.zone or not cfg.zone.enabled then return end
    local center = cfg.pvpCenter
    if not center then return end

    local payload = {
        x             = center.x,
        y             = center.y,
        z             = center.z,
        radius        = cfg.zone.radius or 200.0,
        outsideKillMs = cfg.zone.outsideKillMs or 1500,
    }
    for i = 1, #match.playerList do
        TriggerClientEvent('db:zone:start', match.playerList[i], payload)
    end
    log('info', ('DriveBy match %d: zone radius=%.0f'):format(match.id, payload.radius))
end

---@param match Match
local function stopZone(match)
    for i = 1, #match.playerList do
        TriggerClientEvent('db:zone:stop', match.playerList[i])
    end
end

GM:on('matchStarted', function(match)

    log('info', ('DriveBy match %d: started'):format(match.id))

    startZone(match)

    SetTimeout(cfg.timeLimitMs, function()

        if match.state ~= MatchState.STARTED then return end

        match:setState(MatchState.ENDING)
        match:emitClients('match.stateChange', MatchState.ENDING)

        GM:emit('matchEnding', match)
    end)
end)

GM:registerNetEvent('playerDeath', function(match, victimSrc, killerSrc, weaponHash)

    if match.state ~= MatchState.STARTED then return end

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

    SetTimeout(cfg.respawnDelayMs, function()

        if match.state ~= MatchState.STARTED then return end
        if not match:isPlayer(victimSrc) then return end

        local spawn = pickSpawn()

        match:emitClient(victimSrc, 'spawn', spawn.coords, spawn.heading)
    end)

    if killer and killer.kills >= cfg.scoreLimit then
        match:setState(MatchState.ENDING)
        match:emitClients('match.stateChange', MatchState.ENDING)
        GM:emit('matchEnding', match)
    end
end)

GM:on('matchEnding', function(match)

    local leader = match:getLeader()

    log('info', ('DriveBy match %d: ending (leader=%s kills=%d)'):format(
        match.id, leader and leader.name or '?', leader and leader.kills or 0
    ))

    stopZone(match)

    match:emitClients('matchResult', {
        scoreboard = match:getScoreboard(),
        leaderSrc  = leader and leader.src or nil,
    })

    SetTimeout(cfg.endingMs, function()
        GM:destroyMatch(match.id)
    end)
end)

GM:on('matchFinished', function(match)

    log('info', ('DriveBy match %d: finished'):format(match.id))
end)

GM:on('playerLeft', function(match, src)

    log('info', ('DriveBy match %d: player %d left'):format(match.id, src))

    broadcastScoreboard(match)
end)

GM:registerNetEvent('leaveMatch', function(match, src)
    log('info', ('DriveBy match %d: player %d requested leave'):format(match.id, src))
    GM:onPlayerLeave(src)
end)
