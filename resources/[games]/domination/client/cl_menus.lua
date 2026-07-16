setupHubCamera = function()
    if hubCam and DoesCamExist(hubCam) then return end
    local ped = PlayerPedId()
    if ped == 0 then return end

    local coords  = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local rad     = math.rad(heading)
    local fx      = -math.sin(rad)
    local fy      =  math.cos(rad)

    local DIST  = 3.5
    local CAM_H = 1.55
    local LOOK_H = 0.35

    local camX = coords.x + fx * DIST
    local camY = coords.y + fy * DIST
    local camZ = coords.z + CAM_H

    hubCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', false)
    SetCamCoord(hubCam, camX, camY, camZ)
    PointCamAtCoord(hubCam, coords.x, coords.y, coords.z + LOOK_H)
    SetCamFov(hubCam, 38.0)
    SetCamActive(hubCam, true)
    RenderScriptCams(true, true, 350, false, false)
end

destroyHubCamera = function()
    if hubCam and DoesCamExist(hubCam) then
        SetCamActive(hubCam, false)
        RenderScriptCams(false, true, 250, false, false)
        DestroyCam(hubCam, false)
    end
    hubCam = nil
end

function setHubOpen(open)
    if open and settingsOpen then setSettingsOpen(false) end
    hubOpen = open and true or false
    SetNuiFocus(hubOpen, hubOpen)
    SendNUIMessage({ action = 'hub:visible', value = hubOpen })

    local ped = PlayerPedId()
    if hubOpen then
        if ped ~= 0 then
            FreezeEntityPosition(ped, true)
            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
            SetEntityAlpha(ped, 255, false)
        end
        setupHubCamera()
        DisplayRadar(false)
        SendNUIMessage({ action = 'visible', value = false })
        SendNUIMessage({ action = 'status', visible = false })
        TriggerServerEvent('domination:team:request')
        TriggerServerEvent('domination:state:request')
    else
        destroyHubCamera()
        if ped ~= 0 then
            FreezeEntityPosition(ped, false)
            if Zone.active then
                SetEntityAlpha(ped, inSafeZone and 80 or 255, false)
            end
        end
        applyMinimap()
        if Zone.active then
            SendNUIMessage({ action = 'visible', value = true })
            sendZoneStatus()
        end
    end
end

RegisterNUICallback('hub:close', function(_, cb)
    setHubOpen(false)
    cb({})
end)

RegisterNUICallback('hub:exit', function(_, cb)
    cb({})
    hubOpen = false
    SetNuiFocus(false, false)
    destroyHubCamera()
    applyMinimap()
    local ped = PlayerPedId()
    if ped ~= 0 then
        FreezeEntityPosition(ped, false)
    end
    TriggerServerEvent('domination:leave')
end)

setShopOpen = function(open)
    open = open and true or false
    if open == shopOpen then return end
    shopOpen = open

    if shopOpen then
        if settingsOpen then setSettingsOpen(false) end
        if hubOpen then setHubOpen(false) end
        SetNuiFocus(true, true)
        TriggerServerEvent('domination:state:request')
        if Dom.state then SendNUIMessage({ action = 'shop', data = Dom.state }) end
        SendNUIMessage({ action = 'shop:visible', value = true })
    else
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'shop:visible', value = false })
    end
end

RegisterNUICallback('shop:close', function(_, cb)
    setShopOpen(false)
    cb({})
end)

RegisterNUICallback('shop:buy', function(data, cb)
    if type(data) == 'table' and data.category and data.id then
        TriggerServerEvent('domination:shop:buy', data.category, data.id)
    end
    cb({ ok = true })
end)

RegisterNUICallback('shop:equip', function(data, cb)
    if type(data) == 'table' and data.category and data.id then
        TriggerServerEvent('domination:shop:equip', data.category, data.id)
    end
    cb({ ok = true })
end)

RegisterCommand('domination:shop', function()
    if not Zone.active or respawning then return end
    if not shopOpen and not inSafeZone then
        TriggerEvent('Notify', 'error', 'Você só pode abrir a loja na zona segura.', 3)
        return
    end
    setShopOpen(not shopOpen)
end, false)

RegisterKeyMapping('domination:shop', '[DOMINATION] Abrir Armamentos (Loja)', 'keyboard', 'F2')

setSpawnOpen = function(open)
    open = open and true or false
    if open == spawnOpen then return end
    spawnOpen = open
    if spawnOpen then
        if settingsOpen then setSettingsOpen(false) end
        if hubOpen then setHubOpen(false) end
        if shopOpen then setShopOpen(false) end
        SetNuiFocus(true, true)
        local zones = {}
        for i = 1, #Config.Domination.safeZones do
            local zz = Config.Domination.safeZones[i]
            zones[#zones + 1] = { id = zz.id, label = zz.label }
        end
        SendNUIMessage({ action = 'spawns', data = { zones = zones, current = spawnZoneId } })
        SendNUIMessage({ action = 'spawns:visible', value = true })
    else
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'spawns:visible', value = false })
    end
end

RegisterNUICallback('spawn:close', function(_, cb)
    setSpawnOpen(false)
    cb({})
end)

RegisterNUICallback('spawn:select', function(data, cb)
    if type(data) == 'table' and data.id then
        if inSafeZone then
            relocateToZone(data.id)
        else
            spawnZoneId = data.id
            TriggerServerEvent('domination:relocate', data.id)
        end
    end
    setSpawnOpen(false)
    cb({ ok = true })
end)

RegisterCommand('domination:spawns', function()
    if not Zone.active or respawning then return end
    if not inSafeZone then
        TriggerEvent('Notify', 'error', 'Você só pode escolher spawn dentro da zona segura.', 3)
        return
    end
    setSpawnOpen(not spawnOpen)
end, false)

RegisterKeyMapping('domination:spawns', '[DOMINATION] Escolher Spawn', 'keyboard', 'F5')
