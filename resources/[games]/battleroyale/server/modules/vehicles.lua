while not GM do Wait(0) end

GM:registerNetEvent('vehicles.unlock', function(match, src, vehicleIndex)

    local unlocked = match:getData('unlockedVehicles') or {}

    if unlocked[vehicleIndex] then return end

    unlocked[vehicleIndex] = true
    match:setData('unlockedVehicles', unlocked)

    match:emitClients('vehicles.unlocked', vehicleIndex, src)

    log('info', ('match %d: vehicle %d unlocked by src=%d'):format(match.id, vehicleIndex, src))
end)

GM:on('matchStarted', function(match)

    match:setData('unlockedVehicles', {})
end)
