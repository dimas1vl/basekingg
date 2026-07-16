AddEventHandler('kingg:matchmaking:start', function(batch, mode, subMode)
    if type(batch) ~= 'table' then return end
    local label = mode and subMode and ('%s / %s'):format(mode, subMode) or (mode or subMode or 'Partida')
    for i = 1, #batch do
        Admin.playerMode[tonumber(batch[i])] = label
    end
end)

AddEventHandler('kingg:player:leave', function(src)
    Admin.playerMode[tonumber(src)] = nil
end)

---Resolve the current mode label for an online source.
---@param src number
---@return string
function Admin.getPlayerMode(src)
    src = tonumber(src)
    if not src then return 'Desconhecido' end

    local bucket = GetPlayerRoutingBucket(tostring(src))
    if bucket == src then
        Admin.playerMode[src] = nil
        return 'Lobby'
    end

    return Admin.playerMode[src] or 'Em partida'
end
