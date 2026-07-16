-- Global Notify. Because TriggerEvent dispatches to every resource on the client,
-- any `TriggerEvent('Notify', type, message, duration)` (e.g. from royale/tracking)
-- reaches this handler. RegisterNetEvent also lets the server fire it directly with
-- TriggerClientEvent('Notify', src, ...).

RegisterNetEvent('Notify')
AddEventHandler('Notify', function(notifyType, message, duration)
    if not message then return end
    SendNUIMessage({
        action = 'notify',
        data = {
            type = notifyType or 'info',
            message = tostring(message),
            duration = tonumber(duration) or 5,
        },
    })
end)
