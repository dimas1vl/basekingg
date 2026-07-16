while not GM do Wait(0) end

local RESOURCE = GetCurrentResourceName()
local cfgInjury = Config.BR.injury

---@param match Match
---@param src number
local function startBleedOut(match, src)

    CreateThread(function()

        local elapsed = 0
        local tickInterval = 1000

        while elapsed < cfgInjury.bleedOutTime do

            Wait(tickInterval)
            elapsed = elapsed + tickInterval

            if not match:isPlayer(src) then return end

            if match:getPlayerState(src) ~= PlayerState.INJURED then return end
        end

        if match:getPlayerState(src) == PlayerState.INJURED then

            log('info', ('match %d: player %d bled out'):format(match.id, src))

            handleDeath(match, src, nil)
        end
    end)
end

---@param match Match
---@param src number
---@param killerSrc number | nil
function handleDeath(match, src, killerSrc)

    if match.state == MatchState.WAITING then return end

    log('info', ('match %d: handleDeath called for src=%d killer=%s'):format(match.id, src, tostring(killerSrc)))

    match:setPlayerState(src, PlayerState.DEAD)
    match.stats[src].deaths = match.stats[src].deaths + 1

    local squadIndex, isSquadEliminated, aliveSquadCount = match:markDead(src)

    log('info', ('match %d: markDead result: squad=%d eliminated=%s aliveSquads=%d'):format(
        match.id, squadIndex, tostring(isSquadEliminated), aliveSquadCount
    ))

    match:emitClients('playerState.update', src, PlayerState.DEAD)
    match:emitClients('matchAlive.update', #match:getAlivePlayers(), #match:getAliveSquads())

    GM:emit('playerDied', match, src)

    log('info', ('match %d: player %d died (squad=%d, aliveSquads=%d)'):format(
        match.id, src, squadIndex, aliveSquadCount
    ))

    CreateThread(function()

        Wait(3000)

        if not match:isPlayer(src) then return end

        match:setPlayerState(src, PlayerState.SPECTATING)
        match:emitClients('playerState.update', src, PlayerState.SPECTATING)

        local alivePlayers = match:getAlivePlayers()

        TriggerClientEvent(('net.%s:spectator.init'):format(RESOURCE), src, alivePlayers)
    end)

    if isSquadEliminated then

        log('info', ('match %d: squad %d is eliminated, emitting squadEliminated'):format(match.id, squadIndex))
        GM:emit('squadEliminated', match, squadIndex, aliveSquadCount)
        match:emitClients('squadEliminated', squadIndex)
    end

    if aliveSquadCount <= 1 then

        log('info', ('match %d: aliveSquadCount=%d, transitioning to ENDING'):format(match.id, aliveSquadCount))
        match:setState(MatchState.ENDING)
        match:emitClients('match.stateChange', MatchState.ENDING)

        local winners = match:getAliveSquads()

        for i = 1, #winners do

            local squad = winners[i]

            for j = 1, #squad.players do

                local winnerSrc = squad.players[j]

                if match:isPlayer(winnerSrc) then

                    local kills = match.stats[winnerSrc] and match.stats[winnerSrc].kills or 0

                    TriggerClientEvent(('net.%s:completion.show'):format(RESOURCE), winnerSrc, {
                        placement = 1,
                        kills = kills,
                    })
                end
            end
        end

        GM:emit('matchEnding', match)
    end
end

GM:registerNetEvent('playerDeath', function(match, src, killerSrc, weaponHash)

    if match.state == MatchState.WAITING then return end

    local currentState = match:getPlayerState(src)

    if currentState ~= PlayerState.ALIVE and currentState ~= PlayerState.INJURED then return end

    if killerSrc and killerSrc > 0 and match:isPlayer(killerSrc) then

        local killerSquad = match.playerSquad[killerSrc]
        local victimSquad = match.playerSquad[src]

        if killerSquad ~= victimSquad then
            match.stats[killerSrc].kills = match.stats[killerSrc].kills + 1
        end
    end

    if currentState == PlayerState.ALIVE and match:hasAliveSquadMates(src) then

        match:setPlayerState(src, PlayerState.INJURED)
        match.stats[src].downs = match.stats[src].downs + 1

        match:emitClients('playerState.update', src, PlayerState.INJURED)
        match:emitClients('playerDeath', src, killerSrc, weaponHash)

        GM:emit('playerInjured', match, src, killerSrc)

        log('info', ('match %d: player %d injured by %s'):format(
            match.id, src, tostring(killerSrc)
        ))

        startBleedOut(match, src)
    else

        match:emitClients('playerDeath', src, killerSrc, weaponHash)

        handleDeath(match, src, killerSrc)
    end
end)

GM:registerNetEvent('playerRevive', function(match, src, targetSrc)

    if not match:isPlayer(targetSrc) then return end

    if match:getPlayerState(targetSrc) ~= PlayerState.INJURED then return end

    if match:getPlayerState(src) ~= PlayerState.ALIVE then return end

    local srcSquad = match.playerSquad[src]
    local targetSquad = match.playerSquad[targetSrc]

    if srcSquad ~= targetSquad then return end

    match:setPlayerState(targetSrc, PlayerState.ALIVE)
    match.stats[src].revives = match.stats[src].revives + 1

    match:emitClients('playerState.update', targetSrc, PlayerState.ALIVE)
    match:emitClients('matchAlive.update', #match:getAlivePlayers(), #match:getAliveSquads())

    GM:emit('playerRevived', match, targetSrc, src)

    log('info', ('match %d: player %d revived player %d'):format(match.id, src, targetSrc))
end)
