-- Opens the ban interface for the target sent by the server and forwards the
-- confirmed ban (duration + reason) back to the server.

RegisterNetEvent('admin:ban:open', function(data)
    if type(data) ~= 'table' then return end
    Admin:openNui('openBan', {
        targetSrc = data.targetSrc,
        targetUserId = data.targetUserId,
        targetName = data.targetName,
    })
end)

RegisterNUICallback('submitBan', function(data, cb)
    if type(data) == 'table' and data.targetUserId then
        TriggerServerEvent('net.admin:submitBan', {
            targetUserId = data.targetUserId,
            days = tonumber(data.days) or 0,
            reason = data.reason or 'Sem motivo',
        })
    end
    Admin:closeNui()
    cb({ ok = true })
end)
