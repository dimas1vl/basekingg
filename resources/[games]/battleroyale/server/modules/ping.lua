while not GM do Wait(0) end

local RESOURCE = GetCurrentResourceName()

GM:registerNetEvent('ping.create', function(match, src, x, y, z, targetServerId)

    local squadIndex = match.playerSquad[src]

    if not squadIndex then return end

    local squad = match.squads[squadIndex]

    if not squad then return end

    for _, memberSrc in ipairs(squad.players) do

        TriggerClientEvent(('net.%s:ping.show'):format(RESOURCE), memberSrc, { x = x, y = y, z = z }, src, targetServerId)
    end
end)

GM:registerNetEvent('marker.create', function(match, src, position)

    local squadIndex = match.playerSquad[src]

    if not squadIndex then return end

    local squad = match.squads[squadIndex]

    if not squad then return end

    for _, memberSrc in ipairs(squad.players) do

        TriggerClientEvent(('net.%s:marker.create'):format(RESOURCE), memberSrc, src, position)
    end
end)
