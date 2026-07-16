RegisterNetEvent('domination:enter', function(data)
    print(('^5[dom-cl] domination:enter RECEBIDO data=%s^7'):format(json.encode(data or {})))
    if type(data) ~= 'table' or not data.center then
        print('^1[dom-cl] data invalido, abortando^7')
        return
    end

    print('^5[dom-cl] chamando setupSafeRel + teleportToCenter...^7')
    setupSafeRel()

    Zone.active = true
    Zone.id     = data.id
    Zone.label  = data.label
    Zone.center = { x = data.center.x, y = data.center.y, z = data.center.z, w = data.center.w or 0.0 }
    Zone.radius = tonumber(data.radius) or 200.0
    spawnZoneId = data.id

    -- reconstroi as zonas de dominacao com o layout sorteado pelo servidor
    -- ANTES de criar os blips/markers (senao usariamos um layout vazio/antigo)
    if type(data.layout) == 'table' then
        Config.Domination.dominationZones = Config.Domination.buildDominationZones(data.layout)
    end

    createSafeZoneBlips()
    if type(data.zones) == 'table' then
        for i = 1, #data.zones do
            applyZoneState(data.zones[i].id, data.zones[i])  -- estado atual (cooldown/capturando)
        end
    end

    SetNuiFocus(false, false)

    SendNUIMessage({ action = 'visible', value = true })
    SendNUIMessage({ action = 'show' })
    SendNUIMessage({ action = 'status', visible = true, kind = 'ghost', label = Zone.label })

    applyState(data.state)

    teleportToCenter(Zone.center)
    giveLoadout()
    applyNoPvpFlags()
    graceUntil = 0
    domReportedZone = ''
    startZoneThread()

    publishWeapons()
    startHudThread()
    applySettings()

    applyMinimap()
    DisplayHud(true)

    TriggerEvent('Notify', 'success', ('Entrou em Ghost Mode: %s'):format(data.label or data.id), 4)
end)

RegisterNetEvent('domination:state', function(state)
    applyState(state)
    if Zone.active then publishWeapons() end
end)

RegisterNetEvent('domination:deathcard', function(card)
    Dom.deathSelf = card and card.self or false
    SendNUIMessage({ action = 'deathcard', data = card })
end)

RegisterNetEvent('domination:equip', function(data)
    if type(data) ~= 'table' or not data.category then return end
    if not Zone.active then return end

    local ped    = PlayerPedId()
    local oldCfg = weaponCfgFor(data.category)

    Dom.equipped[data.category] = data.id or Dom.equipped[data.category]

    local newHash = data.weapon and GetHashKey(data.weapon) or nil
    if oldCfg and oldCfg.weapon then
        local oldHash = GetHashKey(oldCfg.weapon)
        if newHash and oldHash ~= newHash and HasPedGotWeapon(ped, oldHash, false) then
            RemovePedWeapon(ped, oldHash)
        end
    end

    local cat = Config.Domination.getCategory(data.category)
    if cat then giveSlotWeapon(cat.slot, true) end
    publishWeapons()
    TriggerEvent('Notify', 'success', 'Arma equipada.', 2)
end)

CreateThread(function()
    local handling = false
    while true do
        if Zone.active then
            local ped = PlayerPedId()
            if not handling and ped ~= 0 and (IsEntityDead(ped) or IsPedFatallyInjured(ped)) then
                handling = true

                local killerServerId = nil
                local killerPed = GetPedSourceOfDeath(ped)
                if killerPed and killerPed ~= 0 and DoesEntityExist(killerPed) and IsEntityAPed(killerPed) then
                    local pIndex = NetworkGetPlayerIndexFromPed(killerPed)
                    if pIndex ~= -1 and pIndex ~= PlayerId() then
                        killerServerId = GetPlayerServerId(pIndex)
                    end
                end
                local dc = GetEntityCoords(ped)
                TriggerServerEvent('domination:kill', killerServerId, dc.x, dc.y, dc.z)

                handleRespawn(killerServerId)
                handling = false
            end
            Wait(200)
        else
            handling = false
            Wait(750)
        end
    end
end)

RegisterNetEvent('domination:leave', function()
    Zone.active   = false
    Zone.threadId = Zone.threadId + 1
    Zone.id       = nil
    Zone.label    = nil
    Zone.center   = nil
    Zone.radius   = 0.0

    NetworkSetFriendlyFireOption(true)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    SetPedCanBeKnockedOffVehicle(PlayerPedId(), 0)
    if settingsOpen then setSettingsOpen(false) end
    settingsCleanup()
    removeSafeZoneBlips()
    domReportedZone = ''
    captureShown = false
    SendNUIMessage({ action = 'capture', visible = false })

    restorePed()

    SendNUIMessage({ action = 'visible', value = false })
    SendNUIMessage({ action = 'status', visible = false })
    SendNUIMessage({ action = 'hub:visible', value = false })
    SendNUIMessage({ action = 'shop:visible', value = false })
    SendNUIMessage({ action = 'spawns:visible', value = false })
    SendNUIMessage({ action = 'vehicles:visible', value = false })
    SendNUIMessage({ action = 'respawn', visible = false })
    SetNuiFocus(false, false)
    respawning   = false
    hubOpen      = false
    shopOpen     = false
    spawnOpen    = false
    vehiclesOpen = false
    if lastSpawnedVehicle and DoesEntityExist(lastSpawnedVehicle) then
        SetEntityAsMissionEntity(lastSpawnedVehicle, true, true)
        DeleteVehicle(lastSpawnedVehicle)
    end
    lastSpawnedVehicle = nil
    destroyHubCamera()
    DisplayRadar(false)

    RemoveAllPedWeapons(PlayerPedId(), true)

    TriggerEvent('Notify', 'info', 'Você saiu da Dominação.', 4)
end)

CreateThread(function()
    for i = 1, 4 do
        local cmd = 'dom_slot_' .. i
        RegisterCommand('+' .. cmd, function() selectSlot(domHotbarSlot(i)) end, false)
        RegisterCommand('-' .. cmd, function() end, false)
        RegisterKeyMapping('+' .. cmd, ('Slot %d (Domination)'):format(i), 'keyboard', tostring(i))
    end
end)
