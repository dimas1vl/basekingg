while not GM do
    Wait(0)
end

GM:on('matchStarted', function(match)

    match:emitClients('matchAlive.update', #match:getAlivePlayers(), #match:getAliveSquads())

    local coordsEvent = ('net.%s:team.coords'):format(GetCurrentResourceName())
    local statesEvent = ('net.%s:team.states'):format(GetCurrentResourceName())

    CreateThread(function()

        while match.state ~= MatchState.FINISHED and match.state ~= MatchState.ENDING do

            for i = 1, #match.squads do

                local squad = match.squads[i]
                local coordsData = {}
                local statesData = {}

                for j = 1, #squad.players do

                    local src = squad.players[j]

                    if match.players[src] and DoesPlayerExist(tostring(src)) then

                        local ped = GetPlayerPed(src)
                        local coords = GetEntityCoords(ped)

                        coordsData[src] = { coords.x, coords.y, coords.z }

                        statesData[src] = {
                            health = (GetEntityHealth(ped) / ((GetEntityMaxHealth(ped) / 100) - 1)) - 100,
                            armor = GetPedArmour(ped),
                        }
                    end
                end

                for j = 1, #squad.players do

                    local src = squad.players[j]

                    if match.players[src] then
                        TriggerClientEvent(coordsEvent, src, coordsData)
                        TriggerClientEvent(statesEvent, src, statesData)
                    end
                end
            end

            Wait(10000)
        end
    end)

    log('info', ('BR match %d: started'):format(match.id))
end)

GM:on('squadEliminated', function(match, squadIndex, aliveSquadCount)

    local placement = (aliveSquadCount or 0) + 1

    print(('[BR-DEBUG] squadEliminated handler: match=%d squad=%d placement=#%d aliveSquads=%d'):format(match.id, squadIndex, placement, aliveSquadCount))

    local squad = match.squads[squadIndex]

    if not squad then
        print(('[BR-DEBUG] squad %d NOT FOUND'):format(squadIndex))
        return
    end

    print(('[BR-DEBUG] squad %d has %d players'):format(squadIndex, #squad.players))

    for i = 1, #squad.players do

        local src = squad.players[i]
        local isPlayer = match:isPlayer(src)
        local exists = DoesPlayerExist(tostring(src))

        print(('[BR-DEBUG] loser src=%d isPlayer=%s exists=%s'):format(src, tostring(isPlayer), tostring(exists)))

        if isPlayer then

            local kills = match.stats[src] and match.stats[src].kills or 0

            print(('[BR-DEBUG] sending completion.show to src=%d (placement=%d kills=%d)'):format(src, placement, kills))

            TriggerClientEvent(('net.%s:completion.show'):format(GetCurrentResourceName()), src, {
                placement = placement,
                kills = kills,
            })
        end
    end

    CreateThread(function()

        Wait(8000)

        print(('[BR-DEBUG] 8s elapsed, returning eliminated squad %d to lobby'):format(squadIndex))

        for i = 1, #squad.players do

            local src = squad.players[i]
            local isPlayer = match:isPlayer(src)
            local exists = DoesPlayerExist(tostring(src))

            print(('[BR-DEBUG] lobby-return: src=%d isPlayer=%s exists=%s'):format(src, tostring(isPlayer), tostring(exists)))

            if isPlayer then

                print(('[BR-DEBUG] sending match.end + lobby:displayLobby to src=%d'):format(src))

                TriggerClientEvent(('net.%s:match.end'):format(GetCurrentResourceName()), src)
                TriggerClientEvent('lobby:displayLobby', src)

                if exists then
                    SetPlayerRoutingBucket(tostring(src), src)
                end

                match.players[src] = nil
                GM.playerMatch[src] = nil
            end
        end

        for i = #match.playerList, 1, -1 do

            local src = match.playerList[i]

            if not match.players[src] then
                table.remove(match.playerList, i)
            end
        end
    end)
end)

GM:on('matchEnding', function(match)

    print(('[BR-DEBUG] matchEnding handler fired: match=%d state=%s playerList=%d'):format(match.id, tostring(match.state), #match.playerList))

    local allPlayers = {}

    for i = 1, #match.playerList do
        allPlayers[#allPlayers + 1] = match.playerList[i]
        print(('[BR-DEBUG] matchEnding: snapshot player src=%d'):format(match.playerList[i]))
    end

    CreateThread(function()

        print(('[BR-DEBUG] match %d: waiting 15s before destroy'):format(match.id))

        Wait(15000)

        print(('[BR-DEBUG] match %d: 15s elapsed, destroying + returning %d players'):format(match.id, #allPlayers))

        GM:destroyMatch(match.id)

        print(('[BR-DEBUG] match %d: destroyMatch complete'):format(match.id))

        for i = 1, #allPlayers do

            local src = allPlayers[i]
            local exists = DoesPlayerExist(tostring(src))
            local stillInMatch = match:isPlayer(src)

            print(('[BR-DEBUG] winner lobby-return: src=%d exists=%s stillInMatch=%s'):format(src, tostring(exists), tostring(stillInMatch)))

            if exists and stillInMatch then
                TriggerClientEvent('lobby:displayLobby', src)
                print(('[BR-DEBUG] lobby:displayLobby sent to src=%d'):format(src))
            end
        end
    end)
end)

GM:on('matchFinished', function(match)

    log('info', ('BR match %d: finished and cleaned up'):format(match.id))
end)

GM:on('playerLeft', function(match, src, squadIndex)

    log('info', ('BR match %d: player %d left (squad %d)'):format(match.id, src, squadIndex))
end)

-- Test commands

RegisterCommand('br:start', function(src)

    local players = {}

    for _, id in pairs(GetPlayers()) do
        players[#players + 1] = tonumber(id)
    end

    if #players == 0 then
        log('warning', 'br:start: no players online')
        return
    end
    log('info', 'br:start: creating match with ' .. #players .. ' players')
    GM:createMatch(players, 'Battle Royale', 'Competitivo ', 'solo', 1)

    log('info', ('br:start: created match with %d players'):format(#players))
end, false)

RegisterCommand('br:startsquad', function(src)

    local players = {}

    for _, id in pairs(GetPlayers()) do
        players[#players + 1] = tonumber(id)
    end

    if #players == 0 then
        log('warning', 'br:startsquad: no players online')
        return
    end

    log('info', 'br:startsquad: creating squad match with ' .. #players .. ' players')
    GM:createMatch(players, 'Battle Royale', 'Competitivo ', 'squad', #players)
end, false)

RegisterCommand('br:damage', function(src)

    src = tonumber(src)

    local match = GM:getPlayerMatch(src)

    if not match then
        log('warning', ('br:damage: player %d not in a match'):format(src))
        return
    end

    TriggerClientEvent(('net.%s:debug.damage'):format(GetCurrentResourceName()), src)
end, false)

RegisterCommand('br:testzone', function(src)

    src = tonumber(src)

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)

    TriggerClientEvent('kingg:safezone:start', src, {
        gas = { x = coords.x, y = coords.y, radius = 200.0 },
        safe = { x = coords.x + 50.0, y = coords.y + 50.0, radius = 80.0 },
        damage = 5,
        phase = 1,
    })

    log('info', ('br:testzone: started safezone at %.0f,%.0f for player %d'):format(coords.x, coords.y, src))
end, false)

RegisterCommand('br:testshrink', function(src)

    src = tonumber(src)

    local startAt = GetGameTimer()

    TriggerClientEvent('kingg:safezone:shrink', src, startAt, 10000)

    log('info', ('br:testshrink: shrink started for player %d (10s)'):format(src))
end, false)

RegisterCommand('br:skipzone', function(src)

    src = tonumber(src)

    local match = GM:getPlayerMatch(src)

    if not match then
        log('warning', ('br:skipzone: player %d not in a match'):format(src))
        return
    end

    local szData = match:getData('safezone')

    if not szData then
        log('warning', 'br:skipzone: safezone not initialized yet')
        return
    end

    szData.skipPhase = true

    log('info', ('br:skipzone: skipping current zone wait (match %d, phase %d)'):format(match.id, szData.currentPhase or 1))
end, false)

RegisterCommand('br:hurt', function(src)

    src = tonumber(src)

    local match = GM:getPlayerMatch(src)

    if not match then
        log('warning', ('br:hurt: player %d not in a match'):format(src))
        return
    end

    TriggerClientEvent(('net.%s:debug.hurt'):format(GetCurrentResourceName()), src)
end, false)

RegisterCommand('br:kill', function(src)

    src = tonumber(src)

    local match = GM:getPlayerMatch(src)

    if not match then
        log('warning', ('br:kill: player %d not in a match'):format(src))
        return
    end

    local currentState = match:getPlayerState(src)

    if currentState == PlayerState.ALIVE and match:hasAliveSquadMates(src) then

        match:setPlayerState(src, PlayerState.INJURED)
        match:emitClients('playerState.update', src, PlayerState.INJURED)
    else

        match:setPlayerState(src, PlayerState.DEAD)
        local squadIndex, isSquadEliminated, aliveSquadCount = match:markDead(src)

        match:emitClients('playerState.update', src, PlayerState.DEAD)

        if isSquadEliminated then
            GM:emit('squadEliminated', match, squadIndex, aliveSquadCount)
            match:emitClients('squadEliminated', squadIndex)
        end

        if aliveSquadCount <= 1 then

            match:setState(MatchState.ENDING)
            match:emitClients('match.stateChange', MatchState.ENDING)

            local winners = match:getAliveSquads()

            for i = 1, #winners do

                local squad = winners[i]

                for j = 1, #squad.players do

                    local winnerSrc = squad.players[j]

                    if match:isPlayer(winnerSrc) then

                        local kills = match.stats[winnerSrc] and match.stats[winnerSrc].kills or 0

                        TriggerClientEvent(('net.%s:completion.show'):format(GetCurrentResourceName()), winnerSrc, {
                            placement = 1,
                            kills = kills,
                        })
                    end
                end
            end

            GM:emit('matchEnding', match)
        end
    end

    log('info', ('br:kill: force-killed player %d'):format(src))
end, false)

RegisterCommand('br:revive', function(src)

    src = tonumber(src)

    local match = GM:getPlayerMatch(src)

    if not match then
        log('warning', ('br:revive: player %d not in a match'):format(src))
        return
    end

    if match:getPlayerState(src) ~= PlayerState.INJURED then
        log('warning', ('br:revive: player %d is not injured'):format(src))
        return
    end

    match:setPlayerState(src, PlayerState.ALIVE)
    match:emitClients('playerState.update', src, PlayerState.ALIVE)

    log('info', ('br:revive: force-revived player %d'):format(src))
end, false)

RegisterCommand('br:force', function(_, args)

    local subMode = args[1] or 'casual'
    local squadType = args[2] or 'solo'

    local modeKey, subModeKey, squadKey = Core.resolveMatchKeys('battle-royale', subMode, squadType)

    if not modeKey or not subModeKey or not squadKey then
        log('warning', ('br:force: could not resolve keys for sub=%s squad=%s'):format(subMode, squadType))
        return
    end

    local sources, fillMap = Core.getQueuePlayers(modeKey, subModeKey, squadKey)

    if GM.warmupMatch and GM.warmupMatch.state == MatchState.WAITING then
        if #sources > 0 then
            Core.clearQueue(modeKey, subModeKey, squadKey)

            for i = 1, #sources do
                TriggerClientEvent('lobby:closeLobby', sources[i])
            end

            GM:addToWarmupMatch(sources, fillMap)
        end

        GM.warmupMatch:setData('forceStart', true)
        log('info', ('br:force: forcing warmup match %d to start (%d players added)'):format(GM.warmupMatch.id, #sources))
        return
    end

    if #sources == 0 then
        log('warning', 'br:force: no players in queue and no warmup match')
        return
    end

    local squadGroups, batch = buildSquadGroups(sources, fillMap)

    Core.clearQueue(modeKey, subModeKey, squadKey)

    for i = 1, #batch do
        TriggerClientEvent('lobby:closeLobby', batch[i])
    end

    local match = GM:createMatch(batch, modeKey, subModeKey, squadKey, 1, squadGroups)
    match:setData('forceStart', true)

    log('info', ('br:force: created + forced match with %d players (%d squads)'):format(#batch, #squadGroups))
end, false)
