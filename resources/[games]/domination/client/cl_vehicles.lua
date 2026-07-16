vehState = nil
local vehExitAt = nil

function vehicleActive()
    return lastSpawnedVehicle and DoesEntityExist(lastSpawnedVehicle) and not IsEntityDead(lastSpawnedVehicle)
end

function spawnVehicle(model, label)
    local hash = type(model) == 'string' and GetHashKey(model) or model
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        TriggerEvent('Notify', 'error', 'Modelo de veículo inválido.', 3)
        return
    end
    RequestModel(hash)
    local deadline = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < deadline do Wait(10) end
    if not HasModelLoaded(hash) then
        TriggerEvent('Notify', 'error', 'Falha ao carregar o veículo.', 3)
        return
    end

    if lastSpawnedVehicle and DoesEntityExist(lastSpawnedVehicle) then
        SetEntityAsMissionEntity(lastSpawnedVehicle, true, true)
        DeleteVehicle(lastSpawnedVehicle)
    end
    lastSpawnedVehicle = nil

    local ped     = PlayerPedId()
    local coords  = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local fwd     = GetEntityForwardVector(ped)
    local sx, sy  = coords.x + fwd.x * 4.0, coords.y + fwd.y * 4.0

    local veh = CreateVehicle(hash, sx, sy, coords.z, heading, true, false)
    SetModelAsNoLongerNeeded(hash)
    SetVehicleOnGroundProperly(veh)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehicleDirtLevel(veh, 0.0)
    SetVehRadioStation(veh, 'OFF')
    SetPedIntoVehicle(ped, veh, -1)
    lastSpawnedVehicle = veh
    vehExitAt = nil

    applyVehicleProtection(inSafeZone or GetGameTimer() < graceUntil)
    TriggerEvent('Notify', 'success', ('Veículo: %s'):format(label or ''), 3)
end

RegisterNetEvent('domination:veh:dropOrphan', function()
    if lastSpawnedVehicle and DoesEntityExist(lastSpawnedVehicle) then
        if GetVehiclePedIsIn(PlayerPedId(), false) ~= lastSpawnedVehicle then
            SetEntityAsMissionEntity(lastSpawnedVehicle, true, true)
            DeleteVehicle(lastSpawnedVehicle)
            lastSpawnedVehicle = nil
        end
    end
end)

setVehiclesOpen = function(open)
    open = open and true or false
    if open == vehiclesOpen then return end
    vehiclesOpen = open
    if vehiclesOpen then
        if settingsOpen then setSettingsOpen(false) end
        if hubOpen then setHubOpen(false) end
        if shopOpen then setShopOpen(false) end
        if spawnOpen then setSpawnOpen(false) end
        SetNuiFocus(true, true)
        TriggerServerEvent('domination:veh:state:request')
        if vehState then SendNUIMessage({ action = 'vehicles', data = vehState }) end
        SendNUIMessage({ action = 'vehicles:visible', value = true })
    else
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'vehicles:visible', value = false })
    end
end

RegisterNetEvent('domination:veh:state', function(state)
    vehState = state
    SendNUIMessage({ action = 'vehicles', data = state })
end)

RegisterNetEvent('domination:veh:do_spawn', function(data)
    if type(data) ~= 'table' or not data.model then return end
    if not Zone.active then return end
    spawnVehicle(data.model, data.label)
end)

RegisterNUICallback('veh:close', function(_, cb)
    setVehiclesOpen(false)
    cb({})
end)

RegisterNUICallback('veh:buy', function(data, cb)
    if type(data) == 'table' and data.category and data.id then
        TriggerServerEvent('domination:veh:buy', data.category, data.id)
    end
    cb({ ok = true })
end)

RegisterNUICallback('veh:spawn', function(data, cb)
    if type(data) == 'table' and data.category and data.id then
        lastVehChoice = { category = data.category, id = data.id }
        TriggerServerEvent('domination:veh:spawn', data.category, data.id)
        setVehiclesOpen(false)
    end
    cb({ ok = true })
end)

RegisterNUICallback('veh:favorite', function(data, cb)
    if type(data) == 'table' and data.category and data.id then
        TriggerServerEvent('domination:veh:favorite', data.category, data.id, data.fav and true or false)
    end
    cb({ ok = true })
end)

lastVehChoice = nil

RegisterCommand('domination:quickveh', function()
    if not Zone.active or respawning then return end
    if not lastVehChoice then
        TriggerEvent('Notify', 'error', 'Escolha um veículo no menu (F3) primeiro.', 3)
        return
    end
    if not inSafeZone and currentDominationZone() ~= nil then
        TriggerEvent('Notify', 'error', 'Você não pode spawnar veículos dentro de uma zona de dominação.', 3)
        return
    end
    if vehiclesOpen then setVehiclesOpen(false) end
    TriggerServerEvent('domination:veh:spawn', lastVehChoice.category, lastVehChoice.id)
end, false)
RegisterKeyMapping('domination:quickveh', '[DOMINATION] Spawnar veículo selecionado', 'keyboard', 'g')

CreateThread(function()
    while true do
        local wait = 250
        local ped = PlayerPedId()
        if Zone.active and ped ~= 0 and IsPedInAnyVehicle(ped, false) then
            wait = 0
            DisableControlAction(0, 80, true)
            if IsDisabledControlJustPressed(0, 80) then
                MakePedReload(ped)
            end
        end
        Wait(wait)
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        if Zone.active and lastSpawnedVehicle and DoesEntityExist(lastSpawnedVehicle) then
            local ped = PlayerPedId()
            if GetVehiclePedIsIn(ped, false) == lastSpawnedVehicle then
                vehExitAt = nil
            else
                local now = GetGameTimer()
                if not vehExitAt then vehExitAt = now end
                local seatOk = IsVehicleSeatFree(lastSpawnedVehicle, -1)
                    and GetVehicleNumberOfPassengers(lastSpawnedVehicle) == 0
                local pc = GetEntityCoords(ped)
                local vc = GetEntityCoords(lastSpawnedVehicle)
                local dx, dy, dz = pc.x - vc.x, pc.y - vc.y, pc.z - vc.z
                local farAway  = (dx * dx + dy * dy + dz * dz) > (100.0 * 100.0)
                local timedOut = (now - vehExitAt) >= 15000
                if seatOk and (inSafeZone or farAway or timedOut) then
                    SetEntityAsMissionEntity(lastSpawnedVehicle, true, true)
                    DeleteVehicle(lastSpawnedVehicle)
                    lastSpawnedVehicle = nil
                    vehExitAt = nil
                end
            end
        else
            vehExitAt = nil
        end
    end
end)

CreateThread(function()
    while true do
        local wait = 500
        if Zone.active then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                wait = 0
                local players = GetActivePlayers()
                for i = 1, #players do
                    local op = GetPlayerPed(players[i])
                    if op ~= 0 and op ~= ped then
                        SetEntityNoCollisionEntity(veh, op, true)
                        SetEntityNoCollisionEntity(op, veh, true)
                    end
                end
            end
        end
        Wait(wait)
    end
end)

