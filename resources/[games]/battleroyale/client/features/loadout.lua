local Loadout = Game.module('loadout')

local REVIVE_DICT = Config.BR.anims.revive

local SMOKE_RADIUS = 4.0
local THROWN_WEAPONS = { [GetHashKey('WEAPON_SMOKEGRENADE')] = true }

gInventory = {}
gActiveItem = nil
gCurrentWeapon = nil
gCurrentAmmoClip = 0
gCurrentAmmoMax = 0

local invOpen = false
local ammoCache = {}
local lastInvSync = 0
local weaponCooldown = 0
local cancelling = false
local armourHidden = false

local smokePositions = {}

local gBusy = false
Core._busy = function() return gBusy end
Core._setBusy = function(v) gBusy = v end

local function playAnim(dict, anim, dur)
    Game.requestAsset(dict, 'anim')
    TaskPlayAnim(PlayerPedId(), dict, anim, 8.0, -8.0, dur, 32 + 16, 0, false, false, false)
end

local function stopAnim()
    ClearPedTasks(PlayerPedId())
end

local NAME_BY_HASH = {}
for itemKey, _ in pairs(GItems) do
    NAME_BY_HASH[GetHashKey(itemKey)] = itemKey
end
for _, extra in ipairs({
    'WEAPON_KNIFE', 'WEAPON_UNARMED', 'GADGET_PARACHUTE',
}) do
    NAME_BY_HASH[GetHashKey(extra)] = extra
end

local function invSlots()
    local i = 0
    return function()
        if i < Config.BR.inventory.slots then
            i = i + 1
            return tostring(i), gInventory[tostring(i)]
        end
    end
end

function getItemAmount(itemName)
    local amt = 0
    for _, v in pairs(gInventory) do
        if v.index == itemName then amt = amt + v.amount end
    end
    return amt
end

function getFreeSpace(itemName)
    local total, slots = 0, 0
    for _, data in invSlots() do
        if not data then slots = slots + 1
        elseif data.index == itemName then total = total + data.amount end
    end
    if slots == 0 and total == 0 then return 0 end
    return GetItemMax(itemName) - total
end

local function removeItem(itemName, amount)
    if not GItems[itemName] then return false end
    for slot, data in pairs(gInventory) do
        if data.index == itemName then
            if amount > data.amount then
                amount = amount - data.amount
                gInventory[slot] = nil
            else
                data.amount = data.amount - amount
                if data.amount <= 0 then gInventory[slot] = nil end
                updateInventory()
                return true
            end
        end
    end
    updateInventory()
    return false
end

function giveItem(itemName, amount, ammo)
    if amount <= 0 or not GItems[itemName] then return false end
    for _, data in pairs(gInventory) do
        if data.index == itemName then
            if data.amount >= GetItemMax(itemName) then
                data.amount = GetItemMax(itemName)
                updateInventory()
                return false
            end
            data.amount = data.amount + amount
            updateInventory()
            return true
        end
    end
    for slotStr, data in invSlots() do
        if not data then
            gInventory[slotStr] = { index = itemName, name = GItems[itemName].name, amount = amount }
            if gInventory[slotStr].amount >= GetItemMax(itemName) then
                gInventory[slotStr].amount = GetItemMax(itemName)
            end
            updateInventory()
            return true
        end
    end
    return false
end

local function getItemByHash(hash)
    for _, v in pairs(gInventory) do
        if GetHashKey(v.index) == hash then return v end
    end
end

local function getItemByType(t)
    for _, v in pairs(gInventory) do
        if GItems[v.index].type == t then return v end
    end
end

local function buildNuiItems()
    local items = {}
    for i = 1, Config.BR.inventory.slots do
        local data = gInventory[tostring(i)]
        if data then
            items[i] = {
                name = data.index,
                label = GItems[data.index] and GItems[data.index].name or data.name,
                quantity = data.amount,
                image = data.index,
            }
        else
            items[i] = false
        end
    end
    return items
end

function updateInventory()
    local slots = {}
    for i = 1, Config.BR.inventory.slots do
        local data = gInventory[tostring(i)]
        if data then
            slots[i] = { name = data.index, amount = data.amount, image = data.index }
        else
            slots[i] = false
        end
    end
    SendNUIMessage({ action = 'hud:hotbar', data = { slots = slots } })
    exports.inventory:SetItems(buildNuiItems())
    if lastInvSync > GetGameTimer() then return end
    lastInvSync = GetGameTimer() + 2000
    Game.session:send('inventory.update')
end

local function canUseInVehicle(name)
    return GItems[name] and GItems[name].useInVehicle
end

local function removeWeapon()
    local ped = PlayerPedId()
    gCurrentWeapon = nil
    gCurrentAmmoClip = 0
    gCurrentAmmoMax = 0
    RemoveAllPedWeapons(ped, true, false)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.15)
    SendNUIMessage({ action = 'hud:weapon', data = {} })
    SendNUIMessage({ action = 'hud:update', data = { activeSlot = 0 } })
end

local function putWeaponHands(weaponName)
    local ped = PlayerPedId()
    local itemAmmo = GetWeaponAmmo(weaponName)
    local amount = getItemAmount(itemAmmo)
    local weaponHash = GetHashKey(weaponName)
    local isVehWeapon = canUseInVehicle(weaponName)

    if not IsPedReloading(ped) then
        if weaponCooldown > GetGameTimer() then return end
    end
    weaponCooldown = GetGameTimer() + 450

    if weaponName == gCurrentWeapon then return removeWeapon() end
    removeWeapon()
    gCurrentWeapon = weaponName

    GiveWeaponToPed(ped, weaponHash, amount, false, true)
    SetCurrentPedWeapon(ped, weaponHash, true)
    SetPedAmmo(ped, weaponHash, amount)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)

    Wait(250)
    if not ammoCache[weaponHash] then
        ammoCache[weaponHash] = math.min(amount, GetMaxAmmoInClip(ped, weaponHash))
    end
    SetAmmoInClip(ped, weaponHash, ammoCache[weaponHash])
    RefillAmmoInstantly(ped)

    Citizen.CreateThread(function()
        local dbgPrevInVeh = false
        local dbgPrevEquipped = nil
        while Game.session:active() do
            if gCurrentWeapon ~= weaponName then break end
            SetPlayerCanDoDriveBy(PlayerId(), true)
            if Core.prone() or Core.layingDown() then return removeWeapon() end
            local inVeh = IsPedInAnyVehicle(ped) or GetVehiclePedIsEntering(ped) ~= 0
            local shooting = IsPedShooting(ped)
            local equipped = GetSelectedPedWeapon(ped)
            local _, clip = GetAmmoInClip(ped, weaponHash)

            if inVeh ~= dbgPrevInVeh or equipped ~= dbgPrevEquipped then
                print(('[loadout] state %s | inVeh=%s equipped=%s weapon=%s clip=%s ammoCache=%s invAmmo=%s'):format(
                    weaponName, tostring(inVeh), tostring(equipped), tostring(weaponHash),
                    tostring(clip), tostring(ammoCache[weaponHash]), tostring(getItemAmount(itemAmmo))
                ))
                dbgPrevInVeh = inVeh
                dbgPrevEquipped = equipped
            end

            if equipped == weaponHash and not inVeh and clip < ammoCache[weaponHash] then
                local spent = ammoCache[weaponHash] - clip
                local beforeInv = getItemAmount(itemAmmo)
                removeItem(itemAmmo, spent)
                ammoCache[weaponHash] = clip
                print(('[loadout] DEDUCT %s | spent=%d clip=%d->%d ammoCache=%d invAmmo=%d->%d invVeh=%s'):format(
                    weaponName, spent, ammoCache[weaponHash] + spent, clip, ammoCache[weaponHash],
                    beforeInv, getItemAmount(itemAmmo), tostring(inVeh)
                ))
            end

            local totalAmmo = getItemAmount(itemAmmo)
            SetPedAmmo(ped, weaponHash, totalAmmo)

            local isGrenadeGrp = THROWN_WEAPONS[equipped]
            local grenadeItem = getItemByType('GRENADE')

            if grenadeItem then
                local gh = GetHashKey(grenadeItem.index)
                if inVeh then
                    if HasPedGotWeapon(ped, gh) then RemoveWeaponFromPed(ped, gh) end
                elseif not HasPedGotWeapon(ped, gh) then
                    GiveWeaponToPed(ped, gh, grenadeItem.amount, false, false)
                end
            end

            if isGrenadeGrp and not inVeh then
                local eqItem = getItemByHash(equipped)
                if eqItem and GItems[eqItem.index].type == 'GRENADE' then
                    while GetSelectedPedWeapon(ped) ~= weaponHash do Wait(0) end
                    removeItem(eqItem.index, 1)
                end
            end

            if equipped ~= weaponHash then
                if inVeh then
                    if not isVehWeapon then SetCurrentPedWeapon(ped, 'WEAPON_UNARMED', true) end
                else
                    SetCurrentPedWeapon(ped, weaponHash, true)
                end
            end

            if clip ~= ammoCache[weaponHash] and not inVeh then
                if IsPedReloading(ped) then ammoCache[weaponHash] = clip end
            end

            local ammoData = { current = clip, max = totalAmmo - clip }
            if inVeh then
                if not isVehWeapon then
                    local minA = math.min(totalAmmo, GetMaxAmmoInClip(ped, weaponHash))
                    if ammoCache[weaponHash] ~= minA then ammoCache[weaponHash] = minA end
                elseif clip ~= 0 then
                    if clip ~= ammoCache[weaponHash] then ammoCache[weaponHash] = clip end
                end
                ammoData = { current = ammoCache[weaponHash], max = totalAmmo - ammoCache[weaponHash] }
            end
            gCurrentAmmoClip = ammoData.current
            gCurrentAmmoMax = ammoData.max
            SendNUIMessage({ action = 'hud:weapon', data = { index = weaponName, ammo = ammoData } })
            Wait(0)
        end
    end)
end

local function putThrowablesHands(weaponName)
    local ped = PlayerPedId()
    local amount = getItemAmount(weaponName)
    local weaponHash = GetHashKey(weaponName)
    if not amount or amount <= 0 then return removeWeapon() end
    if not IsPedReloading(ped) then
        if weaponCooldown > GetGameTimer() or IsPedInAnyVehicle(ped) or Core.prone() or Core.layingDown() then return end
    end
    weaponCooldown = GetGameTimer() + 450
    if weaponName == gCurrentWeapon then return removeWeapon() end
    removeWeapon()
    gCurrentWeapon = weaponName

    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    SetCurrentPedWeapon(ped, weaponHash, true)
    GiveWeaponToPed(ped, weaponHash, amount, false, true)

    gCurrentAmmoClip = 1
    gCurrentAmmoMax = amount
    SendNUIMessage({ action = 'hud:weapon', data = { index = weaponName, ammo = { current = 1, max = amount } } })

    Citizen.CreateThread(function()
        while Game.session:active() do
            if gCurrentWeapon ~= weaponName then break end
            if Core.prone() or IsPedInAnyVehicle(ped) or Core.layingDown() then return removeWeapon() end
            if IsPedShooting(ped) then
                removeItem(weaponName, 1)
                local newAmt = getItemAmount(weaponName)
                gCurrentAmmoClip = 1
                gCurrentAmmoMax = newAmt
                SendNUIMessage({ action = 'hud:weapon', data = { index = weaponName, ammo = { current = 1, max = newAmt } } })
                if newAmt <= 0 then return removeWeapon() end
            end
            Wait(0)
        end
    end)
end

---@param label string
---@param duration number
---@param onComplete fun(ped: number)
local function consumeTimedItem(label, duration, onComplete)

    local ped = PlayerPedId()

    if GetEntityHealth(ped) <= 100 then return end

    gBusy = true
    gActiveItem = true
    playAnim('amb@world_human_clipboard@male@base', 'base', duration)
    closeInventory()

    Game.ui.holdAction({
        label = label,
        duration = duration,
        type = 'medkit',
        key = 'F6',
        check = function()
            return not gActiveItem or Game.session:currentPhase() ~= MatchState.STARTED
        end,
        done = function()
            gActiveItem = nil
            gBusy = false
            stopAnim()
            onComplete(PlayerPedId())
        end,
        fail = function()
            gActiveItem = nil
            gBusy = false
            stopAnim()
        end,
    })
end

local ITEM_ACTIONS = {
    ARMOUR_STANDARD = function()
        local cfgInv = Config.BR.inventory
        if GetPedArmour(PlayerPedId()) >= cfgInv.armourCap then return end
        armourActive = true
        consumeTimedItem('USANDO COLETE', cfgInv.useTime, function(ped)
            if GetEntityHealth(ped) > 100 then
                removeItem('ARMOUR_STANDARD', 1)
                SetPedArmour(ped, cfgInv.armourCap)
            end
            armourActive = false
        end)
    end,

    HEALTH_STANDARD = function()

        local cfgInv = Config.BR.inventory
        local ped = PlayerPedId()
        local health = GetEntityHealth(ped)

        if health >= cfgInv.maxHealth or health <= 100 then return end

        healingActive = true

        local propHash = GetHashKey('v_ret_ta_firstaid')

        RequestModel(propHash)

        while not HasModelLoaded(propHash) do
            Wait(10)
        end

        Game.requestAsset('amb@world_human_clipboard@male@idle_a', 'anim')
        TaskPlayAnim(ped, 'amb@world_human_clipboard@male@idle_a', 'idle_c', 3.0, 3.0, -1, 32 + 16, 0, false, false, false)

        local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, -5.0)
        local prop = CreateObject(propHash, coords.x, coords.y, coords.z, true, true, true)
        SetEntityCollision(prop, false, false)
        AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 60309), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        SetEntityAsMissionEntity(prop, true, true)
        SetModelAsNoLongerNeeded(propHash)

        gBusy = true
        gActiveItem = true
        closeInventory()

        Game.ui.holdAction({
            label = 'USANDO BANDAGEM',
            duration = cfgInv.useTime,
            type = 'medkit',
            key = 'F6',
            check = function()
                return not gActiveItem or Game.session:currentPhase() ~= MatchState.STARTED
            end,
            done = function()

                local p = PlayerPedId()

                if DoesEntityExist(prop) then DeleteObject(prop) end

                ClearPedTasks(p)

                if GetEntityHealth(p) > 100 then
                    local heal = math.min(cfgInv.maxHealth - health, cfgInv.healPerUse)
                    removeItem('HEALTH_STANDARD', 1)
                    SetEntityHealth(p, health + heal)
                    ClearPedBloodDamage(p)
                end

                healingActive = false
                gActiveItem = nil
                gBusy = false
            end,
            fail = function()

                if DoesEntityExist(prop) then DeleteObject(prop) end

                ClearPedTasks(PlayerPedId())
                healingActive = false
                gActiveItem = nil
                gBusy = false
            end,
        })
    end,

    PARACHUTE = function()
        local ped = PlayerPedId()
        if HasPedGotWeapon(ped, GetHashKey('GADGET_PARACHUTE'), false) then return end
        playAnim('clothingshirt', 'try_shirt_positive_d', 3000)
        consumeTimedItem('EQUIPANDO PARAQUEDAS', 3000, function(p)
            GiveWeaponToPed(p, GetHashKey('GADGET_PARACHUTE'), 1, false, true)
            removeItem('PARACHUTE', 1)
        end)
    end,

    WEAPON_SMOKEGRENADE = function() putThrowablesHands('WEAPON_SMOKEGRENADE') end,
    WEAPON_ASSAULTSMG = function() putWeaponHands('WEAPON_ASSAULTSMG') end,
    WEAPON_MICROSMG = function() putWeaponHands('WEAPON_MICROSMG') end,
    WEAPON_MACHINEPISTOL = function() putWeaponHands('WEAPON_MACHINEPISTOL') end,
    WEAPON_APPISTOL = function() putWeaponHands('WEAPON_APPISTOL') end,
    WEAPON_PUMPSHOTGUN = function() putWeaponHands('WEAPON_PUMPSHOTGUN') end,
    WEAPON_PISTOL_MK2 = function() putWeaponHands('WEAPON_PISTOL_MK2') end,
    WEAPON_ASSAULTRIFLE = function() putWeaponHands('WEAPON_ASSAULTRIFLE') end,
    WEAPON_SPECIALCARBINE = function() putWeaponHands('WEAPON_SPECIALCARBINE') end,
    WEAPON_CARBINERIFLE = function() putWeaponHands('WEAPON_CARBINERIFLE') end,
}

local function useItem(itemName)
    if GItems[itemName] and getItemAmount(itemName) > 0 and ITEM_ACTIONS[itemName] then
        ITEM_ACTIONS[itemName]()
    end
end

local function disableKeys()
    local ped = PlayerPedId()
    DisableControlAction(0, 25, true)
    DisableControlAction(0, 199, true)
    DisableControlAction(0, 200, true)
    DisablePlayerFiring(ped, true)
end

function closeInventory()
    if invOpen then
        invOpen = false
        SetCursorLocation(0.5, 0.5)
        exports.inventory:Hide()
    end
end

function dropItems()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    for slot, data in pairs(gInventory) do
        if data.index ~= 'PARACHUTE' then
            local modelHash = GetItemModel(data.index)
            if modelHash then
                Game.session:send('pickup.add', modelHash, data.amount, {
                    pos.x + (math.random() * 2 - 1), pos.y + (math.random() * 2 - 1), pos.z + 1
                })
            end
        end
        gInventory[slot] = nil
    end
    RemoveAllPedWeapons(ped, true)
    GiveWeaponToPed(PlayerPedId(), GetHashKey('WEAPON_KNIFE'), -1, false, true)
end

local function resetInventory()
    removeWeapon()
    closeInventory()
    gBusy = false
    local ped = PlayerPedId()
    SetPedArmour(ped, 0)
    ClearPedBloodDamage(ped)
    RemoveAllPedWeapons(ped, true, false)
    armourHidden = false
    gInventory = {}
    ammoCache = {}
end



-- Event handlers

AddEventHandler('inventory:close', closeInventory)

AddEventHandler('inventory:useItem', function(data)
    local slot = tostring(data.slot + 1)
    if gInventory[slot] and not gBusy then
        if Game.combat.status() == Status.STANDING and Game.session:currentPhase() == MatchState.STARTED then
            useItem(gInventory[slot].index)
        end
    end
end)

AddEventHandler('inventory:moveItem', function(data)
    local slot = tostring(data.slot + 1)
    local amount = data.quantity
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped) or IsPedClimbing(ped) then return end
    if gInventory[slot] then
        if amount > gInventory[slot].amount then amount = gInventory[slot].amount end
        local idx = gInventory[slot].index
        if idx == 'PARACHUTE' then return end
        local modelHash = GetItemModel(idx)
        if not modelHash then return end
        if removeItem(idx, amount) then
            local pos = GetEntityCoords(ped) + vec(0, 0, 1)
            Game.session:send('pickup.add', modelHash, amount, { pos.x, pos.y, pos.z })
        end
    end
    removeWeapon()
    updateInventory()
end)

AddEventHandler('inventory:swapSlots', function(data)
    local from = tostring(data.from + 1)
    local to = tostring(data.to + 1)
    removeWeapon()
    if gInventory[from] then
        if gInventory[to] and gInventory[from].index == gInventory[to].index then
            gInventory[to].amount = gInventory[to].amount + gInventory[from].amount
            gInventory[from] = nil
        else
            local tmp = gInventory[from]
            gInventory[from] = gInventory[to]
            gInventory[to] = tmp
        end
    end
    updateInventory()
end)

-- Commands

RegisterCommand('openBackpack', function()
    if gActiveItem or IsPauseMenuActive() then return end
    if Game.session:currentPhase() ~= MatchState.STARTED then return end
    if Game.combat.status() ~= Status.STANDING then return end
    if not Game.session:active() then return end
    if not invOpen then
        invOpen = true
        SetCursorLocation(0.5, 0.5)
        exports.inventory:Show(buildNuiItems())
        Citizen.CreateThread(function()
            while invOpen do disableKeys(); Wait(0) end
        end)
        SetPauseMenuActive(true)
    else
        closeInventory()
    end
end)

RegisterCommand('kingg:cancel', function()
    if cancelling then
        if IsPedReloading(PlayerPedId()) then return end
    end
    cancelling = true
    if gActiveItem then
        gActiveItem = nil
        stopAnim()
        Game.ui.send('hud:action', { visible = false, type = nil, text = '', cancelKey = '', progress = 0 })
        gBusy = false
    end
    if not gBusy then
        if IsEntityPlayingAnim(PlayerPedId(), REVIVE_DICT, 'idle_a', 3) then
            stopAnim()
        end
    end
    SetTimeout(Config.BR.inventory.cancelCooldown, function() cancelling = false end)
end)

RegisterCommand('kingg:bind', function(_, args)
    local slot = args[1]
    if invOpen or gActiveItem or IsPauseMenuActive() then return end
    if Game.session:currentPhase() == MatchState.STARTED and Game.combat.status() == Status.STANDING then
        if gInventory[slot] and not gBusy and not IsPedReloading(PlayerPedId()) then
            SendNUIMessage({ action = 'hud:update', data = { activeSlot = tonumber(slot) } })
            useItem(gInventory[slot].index)
        end
    end
end)

RegisterCommand('inventory:drop.weapon', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped) or IsPedClimbing(ped) then return end
    if Game.session:currentPhase() ~= MatchState.STARTED then return end
    local _, currentHash = GetCurrentPedWeapon(ped)
    if currentHash == GetHashKey('WEAPON_UNARMED') or currentHash == GetHashKey('WEAPON_KNIFE') then return end
    local itemIndex = nil
    for k, _ in pairs(GItems) do
        if GetHashKey(k) == currentHash then itemIndex = k end
    end
    if not itemIndex then return end
    local modelHash = GetItemModel(itemIndex)
    if not modelHash then return end
    removeWeapon()
    removeItem(itemIndex, 1)
    local pos = GetEntityCoords(ped)
    Game.session:send('pickup.add', modelHash, 1, { pos.x, pos.y, pos.z + 1 })
    updateInventory()
end)

RegisterKeyMapping('kingg:bind 1', 'Slot 1', 'keyboard', '1')
RegisterKeyMapping('kingg:bind 2', 'Slot 2', 'keyboard', '2')
RegisterKeyMapping('kingg:bind 3', 'Slot 3', 'keyboard', '3')
RegisterKeyMapping('kingg:bind 4', 'Slot 4', 'keyboard', '4')
RegisterKeyMapping('kingg:bind 5', 'Slot 5', 'keyboard', '5')
RegisterKeyMapping('openBackpack', 'Abrir Inventario', 'keyboard', 'TAB')
RegisterKeyMapping('kingg:cancel', 'Cancelar Acao', 'keyboard', 'F6')
RegisterKeyMapping('inventory:drop.weapon', 'Soltar Arma', 'keyboard', 'Q')

-- Active item key block
CreateThread(function()
    while true do
        local sleep = 600
        if gActiveItem then sleep = 0; disableKeys() end
        Wait(sleep)
    end
end)



-- Knife management during match
Game.session:listen('phaseChange', function(newState)
    if newState == MatchState.STARTED then
        updateInventory()
        SendNUIMessage({ action = 'hud:weapon', data = {} })
        Wait(3000)
        while Game.session:currentPhase() == MatchState.STARTED do
            local ped = PlayerPedId()
            local paraState = GetPedParachuteState(ped)
            local equipped = GetSelectedPedWeapon(ped)
            DisableControlAction(0, 14, true)
            DisableControlAction(0, 15, true)
            DisableControlAction(0, 16, true)
            DisableControlAction(0, 17, true)
            DisableControlAction(0, 37, true)
            HudForceWeaponWheel(false)
            SendNUIMessage({ action = 'inventory.chute', data = HasPedGotWeapon(ped, GetHashKey('GADGET_PARACHUTE')) })
            if paraState ~= 0 and paraState ~= 1 and paraState ~= 2 and paraState ~= 3
               and not IsPedFalling(ped) and not IsPedInParachuteFreeFall(ped) then
                if equipped == GetHashKey('WEAPON_UNARMED') then
                    GiveWeaponToPed(PlayerPedId(), GetHashKey('WEAPON_KNIFE'), -1, false, true)
                end
            end
            Wait(0)
        end
    end
end)

RegisterCommand('stateArmour', function()
    if Game.session:currentPhase() ~= MatchState.STARTED then return end
    local ped = PlayerPedId()
    armourHidden = not armourHidden
    SetPedComponentVariation(ped, 9, armourHidden and 1 or 0, 0, 1)
end)

-- Smoke system
Game.session:onNet('smoke.create', function(coords)
    local smoke = Config.BR.smoke
    local SCALE = smoke.scale
    local DURATION = smoke.duration
    local FADE_IN = smoke.fadeIn
    local FADE_OUT = smoke.fadeOut
    local hash = GetHashKey('kingg_smoke_01')
    local pos = vec3(coords[1], coords[2], coords[3])

    smokePositions[#smokePositions + 1] = pos
    local h = Game.requestAsset(hash)
    if not h then return end

    local obj = CreateObjectNoOffset(h, coords[1], coords[2], coords[3], false, false, false)
    SetEntityAlpha(obj, 0, false)
    SetEntityLodDist(obj, 500)
    local rv, fv, uv, position = GetEntityMatrix(obj)
    SetEntityMatrix(obj, rv * SCALE, fv * SCALE, uv * SCALE, position)

    Citizen.CreateThread(function()
        local t0 = GetGameTimer()
        while DoesEntityExist(obj) and GetGameTimer() - t0 < FADE_IN do
            SetEntityAlpha(obj, math.floor(255 * ((GetGameTimer() - t0) / FADE_IN)), false)
            Wait(1)
        end
        SetEntityAlpha(obj, 255, false)
    end)

    Citizen.CreateThread(function()
        local t0 = GetGameTimer()
        local fadeStart = 0
        local fading = false
        while DoesEntityExist(obj) do
            local el = GetGameTimer() - t0
            if not fading and el >= DURATION then fading = true; fadeStart = GetGameTimer() end
            if fading then
                local fe = GetGameTimer() - fadeStart
                SetEntityAlpha(obj, math.floor(255 * (1 - fe / FADE_OUT)), false)
                if fe >= FADE_OUT then break end
            end
            if el >= DURATION + FADE_OUT then break end
            Wait(1)
        end
        if DoesEntityExist(obj) then DeleteEntity(obj) end
        for i, p in ipairs(smokePositions) do
            if p == pos then table.remove(smokePositions, i); break end
        end
    end)
end)

-- Session events
Game.session:listen('ended', resetInventory)

Game.session:onNet('pickup.loot', function(itemName, amount)
    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    giveItem(itemName, amount)
end)

Game.session:onNet('items.drop', dropItems)


-- Exports
exports('GiveItem', giveItem)
exports('GetFreeSpace', getFreeSpace)
exports('GetItemAmount', getItemAmount)
exports('DropItems', dropItems)
