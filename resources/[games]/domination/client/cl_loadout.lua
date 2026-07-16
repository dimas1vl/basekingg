function weaponCfgFor(categoryKey)
    local id = Dom.equipped and Dom.equipped[categoryKey]
    local cfg = id and (select(1, Config.Domination.findWeapon(id, categoryKey))) or nil
    if not cfg then cfg = Config.Domination.getDefaultWeapon(categoryKey) end
    return cfg
end

function giveSlotWeapon(slot, switchTo, draw)
    local cat = Config.Domination.getCategoryBySlot(slot)
    if not cat then return end
    local cfg = weaponCfgFor(cat.key)
    if not cfg or not cfg.weapon then return end

    local ped  = PlayerPedId()
    local hash = type(cfg.weapon) == 'string' and GetHashKey(cfg.weapon) or cfg.weapon

    GiveWeaponToPed(ped, hash, cat.ammo or 250, false, switchTo and true or false)
    AddAmmoToPed(ped, hash, cat.ammo or 1)
    if cat.key ~= 'faca' then
        SetPedInfiniteAmmo(ped, true, hash)
        local _, maxClip = GetMaxAmmoInClip(ped, hash, true)
        SetAmmoInClip(ped, hash, maxClip and maxClip > 0 and maxClip or 30)
    end

    if switchTo then
        if not draw then SetCurrentPedWeapon(ped, hash, true) end
        local mult = tonumber(Config.Domination.moveSpeedMultiplier) or tonumber(cat.speedMultiplier) or 1.0
        SetRunSprintMultiplierForPlayer(PlayerId(), mult + 0.0)
        currentSlot = slot
        SendNUIMessage({ action = 'weapon', selected = domSlotToKey(slot), weapon = cfg.weapon })
    end
end

function applySlot(slot)
    giveSlotWeapon(slot, true)
end

drawSeq = 0

function selectSlot(slot)
    if not Zone.active then return end

    local target = slot
    if slot ~= 4 and currentSlot == slot then target = 4 end
    currentSlot = target

    local cat = Config.Domination.getCategoryBySlot(target)
    if not cat then return end

    drawSeq = drawSeq + 1
    local mySeq = drawSeq
    CreateThread(function()
        local ped = PlayerPedId()
        local dict = 'reaction@intimidation@1h'

        RequestAnimDict(dict)
        local t = 0
        while not HasAnimDictLoaded(dict) and t < 200 do Wait(5); t = t + 1 end
        if mySeq ~= drawSeq or not Zone.active then return end

        LocalPlayer.state:set('domHolstering', true, false)
        SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
        if HasAnimDictLoaded(dict) then
            TaskPlayAnim(ped, dict, 'intro', 3.0, 3.0, -1, 48, 0.0, false, false, false)
            SetEntityAnimSpeed(ped, dict, 'intro', 0.8)
            local deadline = GetGameTimer() + 2500
            while mySeq == drawSeq and Zone.active and GetGameTimer() < deadline do
                if GetEntityAnimCurrentTime(ped, dict, 'intro') >= 0.9 then break end
                Wait(0)
            end
        else
            Wait(400)
        end
        if mySeq == drawSeq and Zone.active then
            giveSlotWeapon(target, true)
            SendNUIMessage({ action = 'sfx', cat = 'saque' })
        end
        LocalPlayer.state:set('domHolstering', false, false)
    end)
end

function giveLoadout()
    local ped = PlayerPedId()

    SetPedCanSwitchWeapon(ped, true)
    SetPedCanRagdoll(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, false)
    SetPedDropsWeaponsWhenDead(ped, false)
    SetFadeOutAfterDeath(false)
    SetPedCanBeKnockedOffVehicle(ped, 1)
    SetPlayerCanDoDriveBy(PlayerId(), true)
    SetPedConfigFlag(ped, 122, false)
    SetPedConfigFlag(ped, 184, false)
    SetPedConfigFlag(ped, 35, false)
    if IsPedWearingHelmet(ped) then RemovePedHelmet(ped, true) end

    RemoveAllPedWeapons(ped, true)

    for i = 1, #Config.Domination.categories do
        giveSlotWeapon(Config.Domination.categories[i].slot, false)
    end

    SetEntityMaxHealth(ped, Config.Domination.startHealth)
    SetEntityHealth(ped, Config.Domination.startHealth)
    SetPedArmour(ped, Config.Domination.startArmor)

    currentSlot = 1
    applySlot(1)
end

function publishWeapons()
    local slots = {}
    local order = (DomSettings and DomSettings.hud and DomSettings.hud.hotbar) or { 'fuzil', 'sub', 'pistola', 'faca' }
    for key = 1, 4 do
        local cat = Config.Domination.getCategory(order[key]) or Config.Domination.getCategoryBySlot(key)
        local cfg = cat and weaponCfgFor(cat.key) or nil
        slots[#slots + 1] = {
            slot   = key,
            label  = cfg and cfg.label or (cat and cat.label) or '',
            weapon = cfg and cfg.weapon or nil,
        }
    end
    SendNUIMessage({ action = 'weapons', data = { slots = slots, selected = domSlotToKey(currentSlot) } })
end

applyState = function(state)
    if type(state) ~= 'table' then return end
    Dom.state    = state
    Dom.equipped = state.equipped or Dom.equipped or {}
    Dom.level    = state.level or Dom.level
    Dom.kills    = state.kills or Dom.kills or 0
    Dom.deaths   = state.deaths or Dom.deaths or 0
    SendNUIMessage({ action = 'shop', data = state })
end

function findSpawnZone(zoneId)
    if not zoneId then return nil end
    for i = 1, #Config.Domination.safeZones do
        if Config.Domination.safeZones[i].id == zoneId then
            return Config.Domination.safeZones[i]
        end
    end
    return nil
end

function relocateToZone(zoneId)
    local z = findSpawnZone(zoneId)
    if not z then return end
    spawnZoneId = zoneId
    Zone.id     = z.id
    Zone.label  = z.label
    Zone.center = { x = z.center.x, y = z.center.y, z = z.center.z, w = z.center.w or 0.0 }
    Zone.radius = tonumber(z.radius) or Zone.radius
    teleportToCenter(Zone.center)
    inSafeZone = true
    applyNoPvpFlags()
    sendZoneStatus()
    TriggerServerEvent('domination:relocate', zoneId)
end

function restorePed()
    stopKillcam()
    local ped = PlayerPedId()
    if ped ~= 0 then
        ClearPedTasksImmediately(ped)
        SetEntityVisible(ped, true, false)
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
        ResetEntityAlpha(ped)
    end
    SetPlayerInvincible(PlayerId(), false)
    SetNuiFocus(false, false)
    domDowned = false
    domRevived = false
end
