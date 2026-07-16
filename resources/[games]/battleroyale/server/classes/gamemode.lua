local RESOURCE = GetCurrentResourceName()

---@param sources number[]
---@param fillMap table<number, boolean>
---@param groupMap? table<number, number[]>
---@return number[][] squadGroups
---@return number[] batch
function _G.buildSquadGroups(sources, fillMap, groupMap)

    groupMap = groupMap or {}

    local grouped = {}
    local ungroupedFill = {}
    local ungroupedNoFill = {}
    local seenGroups = {}

    for i = 1, #sources do

        local src = sources[i]
        local gid = nil

        for id, members in pairs(groupMap) do

            for j = 1, #members do

                if members[j] == src then
                    gid = id
                    break
                end
            end

            if gid then break end
        end

        if gid then

            if not seenGroups[gid] then
                seenGroups[gid] = true
                grouped[#grouped + 1] = groupMap[gid]
            end
        elseif fillMap[src] then
            ungroupedFill[#ungroupedFill + 1] = src
        else
            ungroupedNoFill[#ungroupedNoFill + 1] = src
        end
    end

    local squadGroups = {}
    local batch = {}

    for i = 1, #grouped do

        squadGroups[#squadGroups + 1] = grouped[i]

        for j = 1, #grouped[i] do
            batch[#batch + 1] = grouped[i][j]
        end
    end

    for i = 1, #ungroupedNoFill do
        squadGroups[#squadGroups + 1] = { ungroupedNoFill[i] }
        batch[#batch + 1] = ungroupedNoFill[i]
    end

    if #ungroupedFill > 0 then

        squadGroups[#squadGroups + 1] = ungroupedFill

        for i = 1, #ungroupedFill do
            batch[#batch + 1] = ungroupedFill[i]
        end
    end

    return squadGroups, batch
end

---@class GameMode
---@field matches table<number, Match>
---@field playerMatch table<number, number>
---@field handlers table<string, function[]>
---@field nextId number
local GameMode = {}
GameMode.__index = GameMode

---@return GameMode
function GameMode.new()

    local self = setmetatable({
        matches = {},
        playerMatch = {},
        handlers = {},
        nextId = 1,
    }, GameMode)

    self.warmupMatch = nil
    self.warmupMatchFillSquad = nil

    AddEventHandler('kingg:matchmaking:start', function(batch, mode, subMode, squadType, fillMap, groupMap)
        if mode ~= 'Battle Royale' then return end

        local modeConfig = Config.Modes and Config.Modes[mode]
        local requiredSquads = modeConfig and modeConfig.sub_modes[subMode].requiredSquads or 3

        if self.warmupMatch and self.warmupMatch.state == MatchState.WAITING then
            self:addToWarmupMatch(batch, fillMap, groupMap)
        else
            local squadGroups, orderedBatch = buildSquadGroups(batch, fillMap, groupMap)
            local match = self:createMatch(orderedBatch, mode, subMode, squadType, 1, squadGroups)
            match:setData('requiredSquads', requiredSquads)
            self.warmupMatch = match

            local fillSquadIdx = nil
            for i = 1, #squadGroups do
                if #squadGroups[i] > 1 then
                    fillSquadIdx = i
                    break
                end
                for j = 1, #squadGroups[i] do
                    if fillMap[squadGroups[i][j]] then
                        fillSquadIdx = i
                        break
                    end
                end
                if fillSquadIdx then break end
            end
            self.warmupMatchFillSquad = fillSquadIdx
        end
    end)

    AddEventHandler('playerDropped', function()

        local src = source

        if not self.playerMatch[src] then return end

        self:onPlayerDropped(src)
    end)

    AddEventHandler('kingg:player:leave', function(src)
        if not self.playerMatch[src] then return end
        self:onPlayerDropped(src)
    end)

    -- log('info', 'GameMode initialized')

    return self
end

---@param batch number[]
---@param mode string
---@param subMode string
---@param squadType string
---@param squadSize number
---@param squadGroups? number[][]
---@return Match
function GameMode:createMatch(batch, mode, subMode, squadType, squadSize, squadGroups)

    local id = self.nextId

    self.nextId = self.nextId + 1

    local match = Match.new(id, batch, mode, subMode, squadType, squadSize, squadGroups)

    self.matches[id] = match

    for i = 1, #batch do
        self.playerMatch[batch[i]] = id
    end

    if Core.matches then
        match:setData('globalId', Core.matches:register(RESOURCE, mode, subMode, match.bucket, batch))
    end

    self:emit('matchCreated', match)

    local squadMembers = {}
    local squadNames = {}

    for i = 1, #match.squads do
        squadMembers[i] = match.squads[i].players

        for j = 1, #match.squads[i].players do
            local memberSrc = match.squads[i].players[j]
            squadNames[memberSrc] = Core.getUserName(memberSrc)
        end
    end

    local namesEvent = ('net.%s:team.setup'):format(RESOURCE)

    for i = 1, #batch do
        local src = batch[i]
        local squadIndex = match.playerSquad[src]

        TriggerClientEvent(('net.%s:match.join'):format(RESOURCE), src, id, match.state, squadIndex, squadMembers[squadIndex])
        TriggerClientEvent(namesEvent, src, squadNames)
    end

    return match
end

---@param batch number[]
---@param fillMap table<number, boolean>
---@param groupMap? table<number, number[]>
function GameMode:addToWarmupMatch(batch, fillMap, groupMap)

    groupMap = groupMap or {}

    local match = self.warmupMatch
    local newPlayers = {}
    local processed = {}

    for _, members in pairs(groupMap) do

        local validMembers = {}

        for i = 1, #members do

            local src = members[i]

            if not processed[src] then
                validMembers[#validMembers + 1] = src
                processed[src] = true
            end
        end

        if #validMembers > 0 then
            match:addNewSquad(validMembers)

            for i = 1, #validMembers do
                self.playerMatch[validMembers[i]] = match.id
                newPlayers[#newPlayers + 1] = validMembers[i]
            end
        end
    end

    for i = 1, #batch do

        local src = batch[i]

        if not processed[src] then

            processed[src] = true

            local isFill = fillMap[src]

            if isFill and self.warmupMatchFillSquad then
                match:addPlayerToSquad(src, self.warmupMatchFillSquad)
            elseif isFill then
                local idx = match:addNewSquad({ src })
                self.warmupMatchFillSquad = idx
            else
                match:addNewSquad({ src })
            end

            self.playerMatch[src] = match.id
            newPlayers[#newPlayers + 1] = src
        end
    end

    local squadNames = {}

    for i = 1, #match.squads do
        for j = 1, #match.squads[i].players do
            local memberSrc = match.squads[i].players[j]
            squadNames[memberSrc] = Core.getUserName(memberSrc)
        end
    end

    local namesEvent = ('net.%s:team.setup'):format(RESOURCE)
    local joinEvent = ('net.%s:match.join'):format(RESOURCE)

    for i = 1, #newPlayers do
        local src = newPlayers[i]
        local squadIndex = match.playerSquad[src]
        local squadMembers = match.squads[squadIndex].players

        TriggerClientEvent(joinEvent, src, match.id, match.state, squadIndex, squadMembers)
        TriggerClientEvent(namesEvent, src, squadNames)
    end

    for i = 1, #match.playerList do
        TriggerClientEvent(namesEvent, match.playerList[i], squadNames)
    end

    self:emit('playersAdded', match, newPlayers)

    log('info', ('match %d: added %d players during warmup (squads=%d)'):format(
        match.id, #newPlayers, #match.squads
    ))
end

---@param matchId number
---@return Match | nil
function GameMode:getMatch(matchId)

    return self.matches[matchId]
end

---@param src number
---@return Match | nil
function GameMode:getPlayerMatch(src)

    local matchId = self.playerMatch[src]

    if not matchId then return nil end

    return self.matches[matchId]
end

---@param eventName string
---@param handler fun(match: Match, ...)
function GameMode:on(eventName, handler)

    if not self.handlers[eventName] then
        self.handlers[eventName] = {}
    end

    local handlers = self.handlers[eventName]

    handlers[#handlers + 1] = handler
end

---@param eventName string
---@param match Match
---@param ... any
function GameMode:emit(eventName, match, ...)

    local handlers = self.handlers[eventName]

    if not handlers then return end

    for i = 1, #handlers do
        local ok, err = pcall(handlers[i], match, ...)

        if not ok then
            log('error', ('GameMode handler error [%s]: %s'):format(eventName, tostring(err)))
        end
    end
end

---@param eventName string
---@param handler fun(match: Match, src: number, ...)
function GameMode:registerNetEvent(eventName, handler)

    RegisterNetEvent(('net.%s:%s'):format(RESOURCE, eventName), function(...)

        local src = source
        local match = self:getPlayerMatch(src)

        if not match then
            log('warning', ('net event "%s" from src=%d not in any match'):format(eventName, src))
            return
        end

        handler(match, src, ...)
    end)
end

---@param matchId number
function GameMode:destroyMatch(matchId)

    local match = self.matches[matchId]

    if not match then return end

    match:emitClients('match.end')

    local globalId = match:getData('globalId')

    if globalId then
        Core.matches:unregister(globalId)
    end

    match:cleanup()

    for i = 1, #match.playerList do
        self.playerMatch[match.playerList[i]] = nil
    end

    self.matches[matchId] = nil

    if self.warmupMatch and self.warmupMatch.id == matchId then
        self.warmupMatch = nil
        self.warmupMatchFillSquad = nil
    end

    self:emit('matchFinished', match)

    log('info', ('match %d destroyed'):format(matchId))
end

---@param src number
function GameMode:onPlayerDropped(src)

    local match = self:getPlayerMatch(src)

    if not match then return end

    local squadIndex, isSquadEliminated, aliveSquadCount = match:removePlayer(src)

    self.playerMatch[src] = nil

    local globalId = match:getData('globalId')

    if globalId then
        Core.matches:removePlayer(globalId, src)
    end

    self:emit('playerLeft', match, src, squadIndex)

    match:emitClients('match.playerLeft', src, squadIndex)

    if isSquadEliminated then
        self:emit('squadEliminated', match, squadIndex, aliveSquadCount)
    end

    if aliveSquadCount <= 1 and match.state == MatchState.STARTED then

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

        self:emit('matchEnding', match)

        log('info', ('match %d: ending after player %d dropped (aliveSquads=%d)'):format(
            match.id, src, aliveSquadCount
        ))
    end
end

_G.GameMode = GameMode

CreateThread(function()

    while not Core do
        Wait(100)
    end

    _G.log = Core.log
    _G.GM = GameMode.new()
end)
