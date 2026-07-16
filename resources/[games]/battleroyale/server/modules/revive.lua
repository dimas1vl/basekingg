while not GM do Wait(0) end

local RESOURCE = GetCurrentResourceName()
local CARD_REVIVE_TIME = 5000

local platformPositions = gPlatformCoords

---@param match Match
---@param x number
---@param y number
---@return boolean
local function isInsideSafezone(match, x, y)

    local szData = match:getData('safezone')

    if not szData then return true end

    local zone = szData.zones[szData.currentPhase]

    if not zone then return true end

    local dx = x - zone.center.x
    local dy = y - zone.center.y

    return (dx * dx + dy * dy) < (zone.radius * zone.radius)
end

---@param match Match
---@return number[]
local function getValidPlatforms(match)

    local valid = {}

    for i = 1, #platformPositions do

        local pos = platformPositions[i]

        if isInsideSafezone(match, pos[1], pos[2]) then
            valid[#valid + 1] = i
        end
    end

    return valid
end

---@param match Match
local function updateValidPlatforms(match)

    local valid = getValidPlatforms(match)

    match:setData('validPlatforms', valid)
    match:emitClients('revive.platformsUpdate', valid)

    log('info', ('match %d: revive platforms updated, %d valid'):format(match.id, #valid))
end

---@param match Match
---@param src number
---@param pos table {x, y, z}
local function dropCard(match, src, pos)

    local nextId = (match:getData('reviveNextCardId') or 0) + 1

    match:setData('reviveNextCardId', nextId)

    local cards = match:getData('reviveCards') or {}

    cards[nextId] = { src = src, x = pos.x, y = pos.y, z = pos.z }

    match:setData('reviveCards', cards)

    local squadIndex = match.playerSquad[src]

    if not squadIndex then return end

    match:emitSquad(squadIndex, 'revive.cardDropped', nextId, src, pos.x, pos.y, pos.z)

    log('info', ('match %d: card %d dropped for player %d at %.1f,%.1f,%.1f'):format(
        match.id, nextId, src, pos.x, pos.y, pos.z
    ))
end

---@param match Match
---@param targetSrc number
---@param platformIdx number
local function revivePlayer(match, targetSrc, platformIdx)

    local currentState = match:getPlayerState(targetSrc)

    if currentState == PlayerState.DEAD then

        local squad = match:getSquad(targetSrc)

        if squad then

            local alreadyAlive = false

            for i = 1, #squad.alive do

                if squad.alive[i] == targetSrc then
                    alreadyAlive = true
                    break
                end
            end

            if not alreadyAlive then
                squad.alive[#squad.alive + 1] = targetSrc
            end
        end
    end

    match:setPlayerState(targetSrc, PlayerState.ALIVE)
    match:emitClients('playerState.update', targetSrc, PlayerState.ALIVE)

    local pos = platformPositions[platformIdx]

    TriggerClientEvent(('net.%s:revive.playerRevived'):format(RESOURCE), targetSrc, pos[1], pos[2], pos[3])

    log('info', ('match %d: player %d revived at platform %d'):format(match.id, targetSrc, platformIdx))
end

---@param match Match
---@param src number
---@param totemIdx number
local function startTotemSession(match, src, totemIdx)

    local sessions = match:getData('reviveSessions') or {}

    if sessions[src] then return end

    sessions[src] = { totemIdx = totemIdx, active = true }
    match:setData('reviveSessions', sessions)

    match:emitClients('revive.totemStarted', totemIdx, src)

    CreateThread(function()

        while true do

            Wait(CARD_REVIVE_TIME)

            local s = match:getData('reviveSessions')

            if not s or not s[src] or not s[src].active then break end

            if not match:isPlayer(src) then break end

            if match:getPlayerState(src) ~= PlayerState.ALIVE then break end

            local ped = GetPlayerPed(src)

            if not DoesEntityExist(ped) then break end

            local coords = GetEntityCoords(ped)
            local pos = platformPositions[totemIdx]
            local dx = coords.x - pos[1]
            local dy = coords.y - pos[2]

            if (dx * dx + dy * dy) > (5.0 * 5.0) then break end

            local collected = match:getData('collectedCards') or {}
            local playerCards = collected[src]

            if not playerCards or #playerCards == 0 then break end

            local cardData = table.remove(playerCards, 1)

            collected[src] = playerCards
            match:setData('collectedCards', collected)

            local targetSrc = cardData.src
            local targetState = match:getPlayerState(targetSrc)
            local targetSquad = match.playerSquad[targetSrc]
            local srcSquad = match.playerSquad[src]

            if targetSquad == srcSquad and (targetState == PlayerState.INJURED or targetState == PlayerState.DEAD or targetState == PlayerState.SPECTATING) then
                revivePlayer(match, targetSrc, totemIdx)
            end

            TriggerClientEvent(('net.%s:revive.cardConsumed'):format(RESOURCE), src, #playerCards)

            if #playerCards == 0 then break end

            local validPlatforms = match:getData('validPlatforms') or {}
            local stillValid = false

            for i = 1, #validPlatforms do

                if validPlatforms[i] == totemIdx then
                    stillValid = true
                    break
                end
            end

            if not stillValid then break end
        end

        local s2 = match:getData('reviveSessions')

        if s2 and s2[src] then
            s2[src] = nil
            match:setData('reviveSessions', s2)
        end

        match:emitClients('revive.totemStopped', totemIdx, src)

        log('info', ('match %d: player %d totem session ended at platform %d'):format(match.id, src, totemIdx))
    end)
end

GM:on('playerDied', function(match, src)

    local ped = GetPlayerPed(src)

    if not DoesEntityExist(ped) then return end

    local coords = GetEntityCoords(ped)

    dropCard(match, src, coords)
end)

GM:on('squadEliminated', function(match, squadIndex)

    local squad = match.squads[squadIndex]

    if not squad then return end

    local squadPlayers = {}

    for i = 1, #squad.players do
        squadPlayers[squad.players[i]] = true
    end

    local cards = match:getData('reviveCards') or {}
    local toRemove = {}

    for cardId, card in pairs(cards) do

        if squadPlayers[card.src] then
            toRemove[#toRemove + 1] = cardId
        end
    end

    for i = 1, #toRemove do

        local cardId = toRemove[i]

        cards[cardId] = nil
        match:emitClients('revive.cardCollected', cardId)
    end

    match:setData('reviveCards', cards)

    if #toRemove > 0 then
        log('info', ('match %d: removed %d cards for eliminated squad %d'):format(match.id, #toRemove, squadIndex))
    end
end)

GM:registerNetEvent('revive.collectCard', function(match, src, cardId)

    local cards = match:getData('reviveCards') or {}

    if not cards[cardId] then return end

    local cardData = cards[cardId]
    local srcSquad = match.playerSquad[src]
    local targetSquad = match.playerSquad[cardData.src]

    if not srcSquad or srcSquad ~= targetSquad then return end

    cardData.collectedBy = cardData.collectedBy or {}

    if cardData.collectedBy[src] then return end

    cardData.collectedBy[src] = true
    cards[cardId] = cardData
    match:setData('reviveCards', cards)

    local collected = match:getData('collectedCards') or {}

    if not collected[src] then
        collected[src] = {}
    end

    collected[src][#collected[src] + 1] = { src = cardData.src, cardId = cardId }

    match:setData('collectedCards', collected)

    TriggerClientEvent(('net.%s:revive.cardCollected'):format(RESOURCE), src, cardId)

    TriggerClientEvent(('net.%s:revive.cardPickedUp'):format(RESOURCE), src, cardId, #collected[src])

    log('info', ('match %d: player %d collected card %d (total=%d)'):format(match.id, src, cardId, #collected[src]))
end)

GM:registerNetEvent('revive.startTotem', function(match, src, totemIdx)

    if match:getPlayerState(src) ~= PlayerState.ALIVE then return end

    local collected = match:getData('collectedCards') or {}

    if not collected[src] or #collected[src] == 0 then return end

    local validPlatforms = match:getData('validPlatforms') or {}
    local isValid = false

    for i = 1, #validPlatforms do

        if validPlatforms[i] == totemIdx then
            isValid = true
            break
        end
    end

    if not isValid then return end

    startTotemSession(match, src, totemIdx)
end)

GM:registerNetEvent('revive.cancelTotem', function(match, src)

    local sessions = match:getData('reviveSessions') or {}

    if not sessions[src] then return end

    sessions[src].active = false
    match:setData('reviveSessions', sessions)
end)

GM:on('matchStarted', function(match)

    match:setData('reviveCards', {})
    match:setData('collectedCards', {})
    match:setData('reviveNextCardId', 0)
    match:setData('reviveSessions', {})

    local valid = getValidPlatforms(match)

    match:setData('validPlatforms', valid)

    match:emitClients('revive.init', valid)

    log('info', ('match %d: revive system initialized, %d valid platforms'):format(match.id, #valid))
end)

