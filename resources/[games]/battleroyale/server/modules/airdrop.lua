while not GM do Wait(0) end

local RESOURCE = GetCurrentResourceName()
local cfgDrop = Config.BR.airdrop

local OPEN_DURATION = 10000
local SPAWN_DELAY_MIN = 60
local SPAWN_DELAY_MAX = 120
local TICK_INTERVAL = 500
local COLLECT_RANGE_SQ = cfgDrop.collectRange * cfgDrop.collectRange
local DROPS_PER_MATCH = 3
local ALLOWED_PHASES = { [2] = true, [3] = true }

---@param match Match
---@return table | nil
local function getAirdropData(match)

    return match:getData('airdrop')
end

---@param match Match
---@param pos vector3
local function launchAirdrop(match, pos)

    local data = getAirdropData(match)

    if not data then return end

    if data.active then return end

    local dropId = (data.nextId or 0) + 1

    data.nextId = dropId
    data.active = {
        id = dropId,
        pos = pos,
        state = 'falling',
        openingSrc = nil,
        openingCancel = false,
    }

    match:setData('airdrop', data)

    match:emitClients('airdrop.spawn', dropId, pos.x, pos.y, pos.z, cfgDrop.startHeight)

    for i = 1, #match.playerList do

        local src = match.playerList[i]

        TriggerClientEvent(('net.%s:airdrop.notify'):format(RESOURCE), src, 'Um airdrop foi lancado!')
    end

    log('info', ('match %d: airdrop %d launched at %.0f,%.0f,%.0f'):format(match.id, dropId, pos.x, pos.y, pos.z))
end

---@param match Match
---@return vector3 | nil
local function getAirdropPosition(match)

    local szData = match:getData('safezone')

    if not szData or not szData.zones then return nil end

    local phase = szData.currentPhase or 1
    local zone = szData.zones[phase]

    if not zone or not zone.center or not zone.radius then return nil end

    local cx, cy = zone.center.x, zone.center.y
    local rSq = zone.radius * zone.radius

    local valid = {}

    for i = 1, #gAirdropCoords do
        local c = gAirdropCoords[i]
        local dx = c.x - cx
        local dy = c.y - cy

        if (dx * dx + dy * dy) <= rSq then
            valid[#valid + 1] = c
        end
    end

    if #valid > 0 then
        return valid[math.random(1, #valid)]
    end

    local angle = math.random() * 2 * math.pi
    local dist = math.sqrt(math.random()) * zone.radius * 0.85

    return vec3(
        cx + math.cos(angle) * dist,
        cy + math.sin(angle) * dist,
        zone.center.z or 50.0
    )
end

---@param match Match
local function scheduleNextAirdrop(match)

    if match.state ~= MatchState.STARTED then return end

    local data = getAirdropData(match)

    if not data then return end

    if data.dropped >= DROPS_PER_MATCH then return end

    local szData = match:getData('safezone')
    local currentPhase = szData and szData.currentPhase or 1

    if not ALLOWED_PHASES[currentPhase] then return end

    if data.active then return end

    local delay = math.random(SPAWN_DELAY_MIN, SPAWN_DELAY_MAX) * 1000

    CreateThread(function()

        Wait(delay)

        if match.state ~= MatchState.STARTED then return end

        local d = getAirdropData(match)

        if not d then return end

        if d.dropped >= DROPS_PER_MATCH then return end

        if d.active then return end

        local sz = match:getData('safezone')
        local phase = sz and sz.currentPhase or 1

        if not ALLOWED_PHASES[phase] then return end

        local coord = getAirdropPosition(match)

        if not coord then return end

        d.dropped = d.dropped + 1
        match:setData('airdrop', d)

        launchAirdrop(match, coord)
    end)
end

---@param match Match
---@param src number
---@param dropId number
local function startOpeningAirdrop(match, src, dropId)

    local data = getAirdropData(match)

    if not data or not data.active then return end

    if data.active.id ~= dropId then return end

    if data.active.state ~= 'idle' then return end

    if match:getPlayerState(src) ~= PlayerState.ALIVE then return end

    local ped = GetPlayerPed(src)

    if not DoesEntityExist(ped) then return end

    local coords = GetEntityCoords(ped)
    local dx = coords.x - data.active.pos.x
    local dy = coords.y - data.active.pos.y

    if (dx * dx + dy * dy) > COLLECT_RANGE_SQ then return end

    data.active.state = 'opening'
    data.active.openingSrc = src
    data.active.openingCancel = false
    match:setData('airdrop', data)

    match:emitClients('airdrop.opening', dropId, src)

    log('info', ('match %d: airdrop %d opening by src=%d'):format(match.id, dropId, src))

    CreateThread(function()

        local elapsed = 0

        while elapsed < OPEN_DURATION do

            Wait(TICK_INTERVAL)
            elapsed = elapsed + TICK_INTERVAL

            local d = getAirdropData(match)

            if not d or not d.active or d.active.id ~= dropId then return end

            if d.active.openingCancel then
                d.active.state = 'idle'
                d.active.openingSrc = nil
                d.active.openingCancel = false
                match:setData('airdrop', d)
                match:emitClients('airdrop.idle', dropId)
                log('info', ('match %d: airdrop %d opening cancelled'):format(match.id, dropId))
                return
            end

            if d.active.state ~= 'opening' then return end

            if match:getPlayerState(src) ~= PlayerState.ALIVE then
                d.active.state = 'idle'
                d.active.openingSrc = nil
                match:setData('airdrop', d)
                match:emitClients('airdrop.idle', dropId)
                return
            end

            local p = GetPlayerPed(src)

            if not DoesEntityExist(p) then
                d.active.state = 'idle'
                d.active.openingSrc = nil
                match:setData('airdrop', d)
                match:emitClients('airdrop.idle', dropId)
                return
            end

            local c = GetEntityCoords(p)
            local ddx = c.x - d.active.pos.x
            local ddy = c.y - d.active.pos.y

            if (ddx * ddx + ddy * ddy) > COLLECT_RANGE_SQ * 4 then
                d.active.state = 'idle'
                d.active.openingSrc = nil
                match:setData('airdrop', d)
                match:emitClients('airdrop.idle', dropId)
                return
            end
        end

        local d = getAirdropData(match)

        if not d or not d.active or d.active.id ~= dropId then return end

        if d.active.state ~= 'opening' then return end

        d.active.state = 'opened'
        match:setData('airdrop', d)

        TriggerClientEvent(('net.%s:airdrop.opened'):format(RESOURCE), src, dropId)

        log('info', ('match %d: airdrop %d opened by src=%d'):format(match.id, dropId, src))
    end)
end

---@param match Match
---@param src number
---@param dropId number
---@param abilityId string
local function grantReward(match, src, dropId, abilityId)

    local data = getAirdropData(match)

    if not data or not data.active or data.active.id ~= dropId then return end

    if data.active.state ~= 'opened' then return end

    if data.active.openingSrc ~= src then return end

    local dropPosition = data.active.pos

    data.active = nil
    match:setData('airdrop', data)

    match:emitClients('airdrop.remove', dropId)

    if abilityId == 'vant' then

        local squadIndex = match.playerSquad[src]
        local targets = squadIndex and match.squads[squadIndex] and match.squads[squadIndex].players or { src }

        for i = 1, #targets do
            local target = targets[i]
            if match:getPlayerState(target) == PlayerState.ALIVE then
                TriggerClientEvent(('net.%s:vant.set'):format(RESOURCE), target, true)
            end
        end

        log('info', ('match %d: airdrop %d reward=vant to squad of src=%d'):format(match.id, dropId, src))

    elseif abilityId == 'radar' then

        local squadIndex = match.playerSquad[src]
        local targets = squadIndex and match.squads[squadIndex] and match.squads[squadIndex].players or { src }

        for i = 1, #targets do
            local target = targets[i]
            if match:getPlayerState(target) == PlayerState.ALIVE then
                TriggerClientEvent(('net.%s:safezone.radar.set'):format(RESOURCE), target, true)
            end
        end

        log('info', ('match %d: airdrop %d reward=radar to squad of src=%d'):format(match.id, dropId, src))

    elseif abilityId == 'revive' then

        local squadIndex = match.playerSquad[src]

        if squadIndex then

            local squad = match.squads[squadIndex]
            local ped = GetPlayerPed(src)
            local revivePos = DoesEntityExist(ped) and GetEntityCoords(ped) or dropPosition

            for i = 1, #squad.players do

                local targetSrc = squad.players[i]

                if targetSrc ~= src then

                    local targetState = match:getPlayerState(targetSrc)

                    if targetState == PlayerState.DEAD or targetState == PlayerState.INJURED or targetState == PlayerState.SPECTATING then

                        local sq = match:getSquad(targetSrc)

                        if sq then

                            local alreadyAlive = false

                            for j = 1, #sq.alive do

                                if sq.alive[j] == targetSrc then
                                    alreadyAlive = true
                                    break
                                end
                            end

                            if not alreadyAlive then
                                sq.alive[#sq.alive + 1] = targetSrc
                            end
                        end

                        match:setPlayerState(targetSrc, PlayerState.ALIVE)
                        match:emitClients('playerState.update', targetSrc, PlayerState.ALIVE)

                        if revivePos then
                            TriggerClientEvent(('net.%s:airdrop.reviveTeleport'):format(RESOURCE), targetSrc, revivePos.x, revivePos.y, revivePos.z)
                        end

                        log('info', ('match %d: airdrop revived src=%d'):format(match.id, targetSrc))
                    end
                end
            end
        end

        log('info', ('match %d: airdrop %d reward=revive to src=%d'):format(match.id, dropId, src))
    end

    scheduleNextAirdrop(match)
end

GM:registerNetEvent('airdrop.clientLanded', function(match, src, dropId)

    local data = getAirdropData(match)

    if not data or not data.active then return end

    if data.active.id ~= tonumber(dropId) then return end

    if data.active.state ~= 'falling' then return end

    data.active.state = 'idle'
    match:setData('airdrop', data)

    match:emitClients('airdrop.landed', data.active.id)

    log('info', ('match %d: airdrop %d landed (reported by src=%d)'):format(match.id, data.active.id, src))
end)

GM:registerNetEvent('airdrop.startOpen', function(match, src, dropId)

    startOpeningAirdrop(match, src, tonumber(dropId))
end)

GM:registerNetEvent('airdrop.cancelOpen', function(match, src, dropId)

    local data = getAirdropData(match)

    if not data or not data.active then return end

    if data.active.id ~= tonumber(dropId) then return end

    if data.active.openingSrc ~= src then return end

    data.active.openingCancel = true
    match:setData('airdrop', data)
end)

GM:registerNetEvent('airdrop.select', function(match, src, dropId, abilityId)

    assert(type(abilityId) == 'string', 'abilityId must be a string')

    grantReward(match, src, tonumber(dropId), abilityId)
end)

GM:on('matchStarted', function(match)

    match:setData('airdrop', {
        active = nil,
        nextId = 0,
        dropped = 0,
    })

    log('info', ('match %d: airdrop system initialized'):format(match.id))
end)

GM:on('phaseChanged', function(match, phase)

    if not ALLOWED_PHASES[phase] then return end

    scheduleNextAirdrop(match)
end)

GM:on('matchEnding', function(match)

    local data = getAirdropData(match)

    if data and data.active then
        match:emitClients('airdrop.remove', data.active.id)
        data.active = nil
        match:setData('airdrop', data)
    end
end)

RegisterCommand('br:airdrop', function(src)

    src = tonumber(src)

    local match = GM:getPlayerMatch(src)

    if not match then
        log('warning', ('br:airdrop: player %d not in a match'):format(src))
        return
    end

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)

    local data = getAirdropData(match)

    if data and data.active then
        local prevId = data.active.id
        data.active = nil
        match:setData('airdrop', data)
        match:emitClients('airdrop.remove', prevId)
    end

    launchAirdrop(match, coords)

    log('info', ('br:airdrop: launched airdrop at player %d position'):format(src))
end, false)
