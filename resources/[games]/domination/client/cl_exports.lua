RegisterCommand('domination:vehicles', function()
    if not Zone.active or respawning then return end
    if vehiclesOpen then
        setVehiclesOpen(false)
        return
    end
    if not inSafeZone and currentDominationZone() ~= nil then
        TriggerEvent('Notify', 'error', 'Você não pode abrir os veículos dentro de uma zona de dominação.', 3)
        return
    end
    setVehiclesOpen(true)
end, false)

RegisterKeyMapping('domination:vehicles', '[DOMINATION] Veículos', 'keyboard', 'F3')

bigmapOn = false

RegisterCommand('domination:map', function()
    if not Zone.active or respawning then return end
    bigmapOn = not bigmapOn
    SetBigmapActive(bigmapOn, false)
end, false)
RegisterKeyMapping('domination:map', '[DOMINATION] Abrir Mapa', 'keyboard', 'm')

CreateThread(function()
    while true do
        if Zone.active then

            if IsControlJustPressed(0, 288) and not shopOpen and not spawnOpen and not vehiclesOpen and not respawning then
                if hubOpen then
                    setHubOpen(false)
                elseif inSafeZone then
                    setHubOpen(true)
                else
                    TriggerEvent('Notify', 'error', 'Você só pode abrir o menu na zona segura.', 3)
                end
            end
            Wait(0)
        else
            if hubOpen then setHubOpen(false) end
            if shopOpen then setShopOpen(false) end
            if spawnOpen then setSpawnOpen(false) end
            if vehiclesOpen then setVehiclesOpen(false) end
            if bigmapOn then bigmapOn = false; SetBigmapActive(false, false) end
            Wait(500)
        end
    end
end)

exports('getSafeZones', function()
    local list = {}
    if Config and Config.Domination and Config.Domination.safeZones then
        for i = 1, #Config.Domination.safeZones do
            local z = Config.Domination.safeZones[i]
            list[#list + 1] = { id = z.id, label = z.label, type = z.type }
        end
    end
    return list
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    Zone.active   = false
    Zone.threadId = Zone.threadId + 1
    bigmapOn = false
    SetBigmapActive(false, false)
    NetworkSetFriendlyFireOption(true)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    local ped = PlayerPedId()
    if ped ~= 0 then
        ResetEntityAlpha(ped)
        SetEntityInvincible(ped, false)
        FreezeEntityPosition(ped, false)
        SetEntityVisible(ped, true, false)
        SetEntityCollision(ped, true, true)
    end
    SetPlayerInvincible(PlayerId(), false)
    SetPedCanBeKnockedOffVehicle(ped, 0)
    removeSafeZoneBlips()
    if lastSpawnedVehicle and DoesEntityExist(lastSpawnedVehicle) then
        SetEntityAsMissionEntity(lastSpawnedVehicle, true, true)
        DeleteVehicle(lastSpawnedVehicle)
    end
    destroyHubCamera()
    SetNuiFocus(false, false)
end)
