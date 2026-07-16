while not GM do Wait(0) end

local RESOURCE = GetCurrentResourceName()
local cfgWarmup = Config.BR.warmup

---@type table<number, boolean>
local gWarmupMatches = {}

---@param list vector4[]
---@return vector3
local function randomFrom(list)

    local spawn = list[math.random(1, #list)]

    return vector3(spawn.x, spawn.y, spawn.z)
end

---@return vector3
local function randomLobbySpawn()
    return randomFrom(cfgWarmup.lobbySpawns)
end

---@return vector3
local function randomWarmupSpawn()
    return randomFrom(cfgWarmup.warmupSpawns)
end

---@param players number[]
---@return table<number, string>
local function buildNameCache(players)

    local names = {}

    for i = 1, #players do
        names[players[i]] = Core.getUserName(players[i])
    end

    return names
end

---@param match Match
---@return table
local function buildPlayerCount(match)

    local requiredSquads = match:getData('requiredSquads') or 3
    local playersPerSquad = 1

    if #match.squads > 0 and #match.playerList > 0 then
        playersPerSquad = math.ceil(#match.playerList / #match.squads)
    end

    return {
        current = #match.playerList,
        max = requiredSquads * math.max(1, playersPerSquad),
    }
end

---@param match Match
local function broadcastPlayerCount(match)

    if not gWarmupMatches[match.id] then return end

    local countData = buildPlayerCount(match)

    for i = 1, #match.playerList do
        TriggerClientEvent(('net.%s:warmup.playerCount'):format(RESOURCE), match.playerList[i], countData)
    end
end

GM:on('matchCreated', function(match)

    gWarmupMatches[match.id] = true

    log('info', ('[warmup] matchCreated id=%d playerCount=%d'):format(match.id, #match.playerList))

    local names = buildNameCache(match.playerList)
    local countData = buildPlayerCount(match)

    for i = 1, #match.playerList do

        local src = match.playerList[i]
        local coords = randomLobbySpawn()

        log('info', ('[warmup] sending warmup.start to src=%d coords=%.1f,%.1f,%.1f'):format(
            src, coords.x, coords.y, coords.z
        ))

        TriggerClientEvent(('net.%s:warmup.start'):format(RESOURCE), src, coords, countData, names)
    end

    log('info', ('match %d: warmup started'):format(match.id))
end)

GM:on('playersAdded', function(match, newPlayers)

    if not gWarmupMatches[match.id] then return end

    local countdownEnd = match:getData('countdownEnd')
    local allNames = buildNameCache(match.playerList)
    local newNames = buildNameCache(newPlayers)
    local countData = buildPlayerCount(match)

    for i = 1, #newPlayers do

        local src = newPlayers[i]
        local coords = randomLobbySpawn()

        TriggerClientEvent(('net.%s:warmup.start'):format(RESOURCE), src, coords, countData, allNames)

        if countdownEnd then

            local remaining = math.max(0, math.ceil((countdownEnd - GetGameTimer()) / 1000))

            TriggerClientEvent(('net.%s:warmup.countdown'):format(RESOURCE), src, remaining)
        end
    end

    for i = 1, #match.playerList do

        local src = match.playerList[i]
        local isNew = false

        for j = 1, #newPlayers do

            if newPlayers[j] == src then
                isNew = true
                break
            end
        end

        if not isNew then
            TriggerClientEvent(('net.%s:warmup.names'):format(RESOURCE), src, newNames)
        end
    end

    broadcastPlayerCount(match)

    log('info', ('match %d: warmup started for %d new players'):format(match.id, #newPlayers))
end)

GM:on('matchStarted', function(match)

    gWarmupMatches[match.id] = nil
end)

GM:registerNetEvent('warmup.respawn', function(match, src)

    if not gWarmupMatches[match.id] then return end
    if match.state ~= MatchState.WAITING then return end

    local coords = randomWarmupSpawn()

    log('info', ('[warmup] respawn src=%d coords=%.1f,%.1f,%.1f'):format(
        src, coords.x, coords.y, coords.z
    ))

    TriggerClientEvent(('net.%s:warmup.respawn'):format(RESOURCE), src, coords)
end)

GM:registerNetEvent('warmup.leave', function(match, src)

    log('info', ('[warmup] leave request from src=%d matchId=%d'):format(src, match.id))

    if not gWarmupMatches[match.id] then
        log('info', ('[warmup] leave: match %d not in gWarmupMatches'):format(match.id))
        return
    end

    if match.state ~= MatchState.WAITING then
        log('info', ('[warmup] leave: match %d state=%s, ignoring'):format(match.id, tostring(match.state)))
        return
    end

    local squadIndex = match.playerSquad[src]

    if not squadIndex then
        log('info', ('[warmup] leave: src=%d has no squad'):format(src))
        return
    end

    local squad = match.squads[squadIndex]

    if not squad then return end

    local membersToRemove = {}

    for i = 1, #squad.players do
        membersToRemove[#membersToRemove + 1] = squad.players[i]
    end

    for i = 1, #membersToRemove do

        local memberSrc = membersToRemove[i]

        if match:isPlayer(memberSrc) then

            match:removePlayer(memberSrc)
            GM.playerMatch[memberSrc] = nil

            if DoesPlayerExist(tostring(memberSrc)) then
                TriggerClientEvent(('net.%s:match.end'):format(RESOURCE), memberSrc)
                TriggerClientEvent('lobby:displayLobby', memberSrc)
            end
        end
    end

    broadcastPlayerCount(match)

    log('info', ('match %d: squad %d left during warmup (%d players)'):format(
        match.id, squadIndex, #membersToRemove
    ))
end)

GM:on('matchFinished', function(match)

    gWarmupMatches[match.id] = nil
end)
