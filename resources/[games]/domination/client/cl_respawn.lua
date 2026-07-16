domDowned = false
domRevived = false

function finishDownedRevive()
    domDowned = false
    domRevived = false
    respawning = false
    stopKillcam()
    SendNUIMessage({ action = 'respawn', visible = false })
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    SetEntityCollision(ped, true, true)
    giveLoadout()
    graceUntil = 0
    SetEntityInvincible(ped, false)
    SetPlayerInvincible(PlayerId(), false)
    inSafeZone = false
    applyOutsideFlags()
    sendZoneStatus()
end

RegisterNetEvent('domination:revived', function()
    if domDowned then domRevived = true end
end)

---@param killerSrc? number
function handleRespawn(killerSrc)
    local z = findSpawnZone(spawnZoneId) or findSpawnZone(Zone.id)
    local c
    if z then
        c = { x = z.center.x, y = z.center.y, z = z.center.z, w = z.center.w or 0.0 }
    elseif Zone.center then
        c = { x = Zone.center.x, y = Zone.center.y, z = Zone.center.z, w = Zone.center.w or 0.0 }
    else
        return
    end

    respawning = true
    domReportedZone = ''
    TriggerServerEvent('domination:zone:here', '')

    if hubOpen then
        hubOpen = false
        destroyHubCamera()
        SendNUIMessage({ action = 'hub:visible', value = false })
    end
    shopOpen     = false
    spawnOpen    = false
    vehiclesOpen = false
    SendNUIMessage({ action = 'shop:visible', value = false })
    SendNUIMessage({ action = 'spawns:visible', value = false })
    SendNUIMessage({ action = 'vehicles:visible', value = false })
    SendNUIMessage({ action = 'status', visible = false })
    SetNuiFocus(false, false)
    applyMinimap()
    bigmapOn = false
    SetBigmapActive(false, false)

    if lastSpawnedVehicle and DoesEntityExist(lastSpawnedVehicle) then
        SetEntityAsMissionEntity(lastSpawnedVehicle, true, true)
        DeleteVehicle(lastSpawnedVehicle)
    end
    lastSpawnedVehicle = nil

    local ped = PlayerPedId()
    local dc  = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(dc.x, dc.y, dc.z, GetEntityHeading(ped), true, false)
    ped = PlayerPedId()
    ClearPedBloodDamage(ped)
    ClearPedTasksImmediately(ped)
    SetEntityInvincible(ped, true)
    SetPlayerInvincible(PlayerId(), true)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    SetPedToRagdoll(ped, 60000, 60000, 0, false, false, false)

    domDowned = true
    domRevived = false
    TriggerServerEvent('domination:downed', true)
    startKillcam(killerSrc)

    local total = (Dom.state and Dom.state.respawnMs) or 10000
    local deadline = GetGameTimer() + total
    local reported = false
    local lastSend = 0
    Dom.deathSelf = nil

    local function pollReport()

        if not reported and Dom.deathSelf == false and IsControlJustPressed(0, 45) then
            reported = true
            TriggerServerEvent('domination:report')
            SendNUIMessage({ action = 'deathcard:reported' })
        end
    end

    while Zone.active and not domRevived and GetGameTimer() < deadline do
        local nowt = GetGameTimer()
        if nowt - lastSend > 100 then
            SendNUIMessage({ action = 'respawn', visible = true, ms = deadline - nowt, total = total })
            lastSend = nowt
        end
        if not IsPedRagdoll(ped) then SetPedToRagdoll(ped, 5000, 5000, 0, false, false, false) end
        pollReport()
        Wait(0)
    end

    if domRevived then return finishDownedRevive() end

    SendNUIMessage({ action = 'respawn', visible = true, ready = true })
    while Zone.active and not domRevived do
        if not IsPedRagdoll(ped) then SetPedToRagdoll(ped, 5000, 5000, 0, false, false, false) end
        pollReport()
        if IsControlJustPressed(0, 38) then break end
        Wait(0)
    end

    if domRevived then return finishDownedRevive() end

    stopKillcam()
    SendNUIMessage({ action = 'respawn', visible = false })
    domDowned = false
    TriggerServerEvent('domination:downed', false)

    if not Zone.active then
        restorePed()
        respawning = false
        return
    end

    if z then
        Zone.id     = z.id
        Zone.label  = z.label
        Zone.center = { x = z.center.x, y = z.center.y, z = z.center.z, w = z.center.w or 0.0 }
        Zone.radius = tonumber(z.radius) or Zone.radius
    end

    ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    RequestCollisionAtCoord(c.x, c.y, c.z)
    SetEntityCoordsNoOffset(ped, c.x, c.y, c.z, false, false, false)
    SetEntityHeading(ped, 0.0)
    local cdl = GetGameTimer() + 2000
    while GetGameTimer() < cdl and not HasCollisionLoadedAroundEntity(ped) do
        RequestCollisionAtCoord(c.x, c.y, c.z)
        Wait(50)
    end
    local found, gz = GetGroundZFor_3dCoord(c.x, c.y, c.z + 50.0, false)
    if found then
        SetEntityCoordsNoOffset(ped, c.x, c.y, gz + 0.1, false, false, false)
    end
    FreezeEntityPosition(ped, false)

    inSafeZone = true
    graceUntil = 0
    giveLoadout()
    applyNoPvpFlags()
    sendZoneStatus()
    respawning = false
end

function startHudThread()
    CreateThread(function()
        while Zone.active do
            local ped = PlayerPedId()
            local hp     = math.max(0, GetEntityHealth(ped) - 100)
            local maxHp  = math.max(1, GetEntityMaxHealth(ped) - 100)
            local armor  = GetPedArmour(ped)

            local _, hash = GetCurrentPedWeapon(ped, true)
            local weapon
            for i = 1, #Config.Domination.categories do
                local cfg = weaponCfgFor(Config.Domination.categories[i].key)
                if cfg and cfg.weapon and GetHashKey(cfg.weapon) == hash then
                    weapon = cfg.weapon
                    break
                end
            end
            local _, clip = GetAmmoInClip(ped, hash or 0)
            local _, maxAmmo = GetMaxAmmo(ped, hash or 0)

            local hpPct = math.floor(hp * 100 / math.max(1, maxHp))
            SendNUIMessage({
                action = 'hud',
                data = {
                    hp        = hpPct,
                    hpMax     = 100,
                    armor     = armor,
                    armorMax  = 100,
                    kills     = Dom.kills or 0,
                    deaths    = Dom.deaths or 0,
                    streak    = 0,
                    players   = #GetActivePlayers(),
                    ammo      = clip or 0,
                    maxAmmo   = maxAmmo or 0,
                    weapon    = weapon,
                    inVehicle = false,
                    speed     = 0,
                    level     = (Dom.state and Dom.state.level) or Dom.level or 1,
                    xpInto    = (Dom.state and Dom.state.xpIntoLevel) or 0,
                    xpPer     = (Dom.state and Dom.state.xpPerLevel) or 1,
                },
            })

            Wait(250)
        end
        SendNUIMessage({ action = 'visible', value = false })
    end)
end
