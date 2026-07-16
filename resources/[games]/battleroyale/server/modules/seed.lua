while not GM do Wait(0) end

GM:on('matchStarted', function(match)

    local seed = math.random(1, 0x7fffffff)

    match:setData('seed', seed)
    match:emitClients('match.seed', seed)
    match:emitClients('chest.seed', seed)

    print(('[seed] match %d: seed=%d dispatched (match.seed + chest.seed)'):format(match.id, seed))
end)
