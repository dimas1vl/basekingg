while not GM do Wait(0) end

local RESOURCE = GetCurrentResourceName()

---@param zone SafeZoneData
---@return vector3 from
---@return vector3 to
local function generateFlightPath(zone)

    local angle1 = math.random() * 2 * math.pi
    local angle2 = angle1 + math.pi * (0.89 + math.random() * 0.22)

    local alt = Config.BR.airplane.altitude
    local flightRadius = zone.radius * 1.15

    local from = vector3(
        zone.center.x + math.cos(angle1) * flightRadius,
        zone.center.y + math.sin(angle1) * flightRadius,
        alt
    )

    local to = vector3(
        zone.center.x + math.cos(angle2) * flightRadius,
        zone.center.y + math.sin(angle2) * flightRadius,
        alt
    )

    local perpAngle = angle1 + math.pi / 2
    local maxOffset = zone.radius * 0.10
    local offset = (math.random() * 2 - 1) * maxOffset

    from = vector3(from.x + math.cos(perpAngle) * offset, from.y + math.sin(perpAngle) * offset, alt)
    to = vector3(to.x + math.cos(perpAngle) * offset, to.y + math.sin(perpAngle) * offset, alt)

    return from, to
end

---@param from vector3
---@param to vector3
---@return number
local function calculateFlightDuration(from, to)

    local dist = #(from - to)

    return dist / Config.BR.airplane.speed
end

---@param match Match
local function startAirplane(match)

    math.randomseed(GetGameTimer() + match.id * 7919)

    local initialZone = {
        center = Config.BR.safezone.initialCenter,
        radius = Config.BR.safezone.initialRadius,
    }

    local from, to = generateFlightPath(initialZone)
    local duration = calculateFlightDuration(from, to)
    local routeLength = #(from - to)
    local serverTimeEnd = GetGameTimer() + 3000

    match:setData('airplane', {
        from = from,
        to = to,
        duration = duration,
        routeLength = routeLength,
        serverTimeEnd = serverTimeEnd,
        jumped = {},
        jumpedCount = 0,
        finished = false,
    })

    match:setState(MatchState.AIRPLANE)
    match:emitClients('match.stateChange', MatchState.AIRPLANE)
    match:emitClients('airplane.start', from, to, routeLength, serverTimeEnd)

    GM:emit('airplaneStarted', match)

    log('info', ('match %d: airplane phase (from=%.0f,%.0f to=%.0f,%.0f duration=%.1fs)'):format(
        match.id, from.x, from.y, to.x, to.y, duration
    ))

    CreateThread(function()

        Wait(math.floor(duration * 1000))

        local airplane = match:getData('airplane')

        if airplane.finished then return end

        airplane.finished = true

        match:emitClients('airplane.eject')

        log('info', ('match %d: airplane flight ended, ejecting remaining players'):format(match.id))

        Wait(5000)

        if match.state ~= MatchState.AIRPLANE then return end

        match:setState(MatchState.STARTED)
        match:emitClients('match.stateChange', MatchState.STARTED)

        GM:emit('matchStarted', match)
    end)
end

---@param match Match
local function checkAllJumped(match)

    local airplane = match:getData('airplane')

    if airplane.finished then return end

    if airplane.jumpedCount >= #match.playerList then

        airplane.finished = true

        log('info', ('match %d: all players jumped from airplane'):format(match.id))

        Wait(3000)

        if match.state ~= MatchState.AIRPLANE then return end

        match:setState(MatchState.STARTED)
        match:emitClients('match.stateChange', MatchState.STARTED)

        GM:emit('matchStarted', match)
    end
end

---@param match Match
---@param remaining number
local function forceAllToLobby(match, remaining)

    if remaining > 10 then return end

    local alreadyForced = match:getData('forcedToLobby')

    if alreadyForced then return end

    match:setData('forcedToLobby', true)
end

GM:on('matchCreated', function(match)

    local requiredSquads = match:getData('requiredSquads') or 3
    local countdownStarted = false

    log('info', ('BR match %d: warmup started, waiting for %d squads'):format(match.id, requiredSquads))

    CreateThread(function()

        while match.state == MatchState.WAITING do

            local aliveSquads = #match:getAliveSquads()
            local playerCount = #match.playerList
            local forceStart = match:getData('forceStart')

            if forceStart then

                Wait(3000)

                if match.state ~= MatchState.WAITING then return end

                GM.warmupMatch = nil
                GM.warmupMatchFillSquad = nil

                startAirplane(match)
                return
            end

            if not countdownStarted and (playerCount >= 30 or aliveSquads >= 10) then

                countdownStarted = true

                local countdownEnd = GetGameTimer() + 120000

                match:setData('countdownEnd', countdownEnd)
                match:emitClients('warmup.countdown', 120)

                log('info', ('match %d: countdown started (players=%d squads=%d)'):format(
                    match.id, playerCount, aliveSquads
                ))
            end

            if countdownStarted then

                local countdownEnd = match:getData('countdownEnd')
                local remaining = math.max(0, math.ceil((countdownEnd - GetGameTimer()) / 1000))

                forceAllToLobby(match, remaining)

                if remaining <= 0 then

                    GM.warmupMatch = nil
                    GM.warmupMatchFillSquad = nil

                    startAirplane(match)
                    return
                end
            end

            Wait(1000)
        end
    end)
end)

GM:registerNetEvent('airplane.jumped', function(match, src)

    local airplane = match:getData('airplane')

    if not airplane or airplane.finished then return end

    if airplane.jumped[src] then return end

    airplane.jumped[src] = true
    airplane.jumpedCount = airplane.jumpedCount + 1

    match:emitClients('airplane.playerJumped', src)

    log('info', ('match %d: player %d jumped from airplane (%d/%d)'):format(
        match.id, src, airplane.jumpedCount, #match.playerList
    ))

    checkAllJumped(match)
end)

GM:registerNetEvent('airplane.landed', function(match, src)

    log('info', ('match %d: player %d landed'):format(match.id, src))
end)

GM:registerNetEvent('airplane.leaderJump', function(match, src, heading)

    local squadIndex = match.playerSquad[src]

    if not squadIndex then return end

    match:emitSquad(squadIndex, 'airplane.leaderJumped', src, heading)

    log('info', ('match %d: squad %d leader %d jumped (heading=%.1f)'):format(
        match.id, squadIndex, src, heading or 0.0
    ))
end)
