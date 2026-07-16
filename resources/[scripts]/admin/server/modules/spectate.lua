
---@param adminSrc number
---@param targetSrc number
function Admin.act.spectate(adminSrc, targetSrc)
    if targetSrc == adminSrc then
        return Admin.notify(adminSrc, 'warning', 'Voce nao pode spectar a si mesmo.')
    end

    if Admin.specPrevBucket[adminSrc] == nil then
        Admin.specPrevBucket[adminSrc] = GetPlayerRoutingBucket(tostring(adminSrc))
    end

    local bucket = GetPlayerRoutingBucket(tostring(targetSrc))
    SetPlayerRoutingBucket(tostring(adminSrc), bucket)

    TriggerClientEvent('admin:spec:start', adminSrc, {
        targetSrc = targetSrc,
        targetUserId = Core.getUserId(targetSrc),
        targetName = Admin.playerName(targetSrc),
    })

    Admin.notify(adminSrc, 'success', ('Spectando %s.'):format(Admin.playerName(targetSrc)))
end

RegisterNetEvent('net.admin:spec:stop', function()
    local src = source
    local prev = Admin.specPrevBucket[src]
    SetPlayerRoutingBucket(tostring(src), prev or src)
    Admin.specPrevBucket[src] = nil
end)
