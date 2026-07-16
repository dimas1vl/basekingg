while not GM do Wait(0) end

local EXPLOSION_MAP = {
    [20] = 'smoke.create',
    [21] = 'smoke.create',
    [22] = 'smoke.create',
    [39] = 'smoke.create',
}

AddEventHandler('explosionEvent', function(src, eventData)
    print('explosionEvent fired', type(src), type(eventData))
    if not eventData then return end

    local eventName = EXPLOSION_MAP[eventData.explosionType]
    print('eventName', eventName)
    if not eventName then return end

    local match = GM:getPlayerMatch(tonumber(src))
    print('match', match)
    if not match then return end

    local coords = { eventData.posX, eventData.posY, eventData.posZ }
    print('coords', coords)
    match:emitClients(eventName, coords)
    print('match:emitClients(eventName, coords)', eventName, coords)
end)
