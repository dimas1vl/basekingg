--[[ HUD do jogador no tracking: godmode + ammo infinito + hotbar.
     Single-player local. Lifecycle: whenEnter → start, whenLeave → stop. ]]

---@return table
local function getCfg()
    return rawget(_G, 'TrackingPlayerHud') or {}
end

---@return table
local function getWeapons()
    local c = getCfg()
    return c.weapons or {}
end

local hudActive            = false
local hudThreadId          = 0
local godmodeThreadId      = 0
local controlBlockThreadId = 0
local currentSlot          = 1

local BLOCKED_CONTROLS = {
    37,                     -- INPUT_SELECT_WEAPON (TAB)
    12, 13, 14, 15, 16, 17, -- weapon wheel scroll/select
    19,                     -- INPUT_CHARACTER_WHEEL
}

---@param slot number
---@return table|nil
local function findWeaponConfig(slot)
    local weapons = getWeapons()
    for i = 1, #weapons do
        if weapons[i].slot == slot then return weapons[i] end
    end
    return nil
end

---@param item table
---@return number
local function getWeaponHash(item)
    if not item or not item.weapon then return 0 end
    return type(item.weapon) == 'string' and GetHashKey(item.weapon) or item.weapon
end

---@param ped number
---@return string | nil, number, number
local function getCurrentWeaponInfo(ped)
    local _, hashOrZero = GetCurrentPedWeapon(ped, true)
    if not hashOrZero or hashOrZero == 0 then return nil, 0, 0 end

    local weaponName
    local weapons = getWeapons()
    for i = 1, #weapons do
        if weapons[i].weapon and GetHashKey(weapons[i].weapon) == hashOrZero then
            weaponName = weapons[i].weapon
            break
        end
    end

    local ammo = GetAmmoInPedWeapon(ped, hashOrZero) or 0
    local _, maxAmmo = GetMaxAmmo(ped, hashOrZero)
    return weaponName, ammo, maxAmmo or 0
end

local function sendHudUpdate()
    if not hudActive then return end
    local ped = PlayerPedId()
    local hp  = math.max(0, GetEntityHealth(ped) - 100)
    local hpMax = GetEntityMaxHealth(ped) - 100
    if hpMax <= 0 then hpMax = 100 end
    local armor = GetPedArmour(ped)

    local weapon, ammo, maxAmmo = getCurrentWeaponInfo(ped)

    local veh       = GetVehiclePedIsIn(ped, false)
    local inVehicle = veh ~= 0
    local speed     = inVehicle and math.floor(GetEntitySpeed(veh) * 3.6 + 0.5) or 0

    SendNUIMessage({ action = 'thudVisible', value = true })
    SendNUIMessage({
        action = 'thud',
        data = {
            hp        = hp,
            hpMax     = hpMax,
            armor     = armor,
            armorMax  = 100,
            ammo      = ammo,
            maxAmmo   = maxAmmo,
            weapon    = weapon,
            inVehicle = inVehicle,
            speed     = speed,
        },
    })
end

local function startHudThread()
    hudThreadId = hudThreadId + 1
    local myId = hudThreadId
    local interval = tonumber(getCfg().hudUpdateMs) or 500
    CreateThread(function()
        while hudActive and myId == hudThreadId do
            sendHudUpdate()
            Wait(interval)
        end
    end)
end

local function startGodmodeLoop()
    godmodeThreadId = godmodeThreadId + 1
    local myId = godmodeThreadId
    CreateThread(function()
        local playerId = PlayerId()
        while hudActive and myId == godmodeThreadId do
            local ped = PlayerPedId()

            SetPlayerInvincible(playerId, true)
            SetEntityInvincible(ped, true)
            SetEntityCanBeDamaged(ped, false)
            SetEntityHealth(ped, GetEntityMaxHealth(ped))
            SetPedArmour(ped, getCfg().startArmor or 100)

            SetPedInfiniteAmmoClip(ped, true)
            local weapons = getWeapons()
            for i = 1, #weapons do
                local hash = getWeaponHash(weapons[i])
                if hash ~= 0 and HasPedGotWeapon(ped, hash, false) then
                    SetPedInfiniteAmmo(ped, true, hash)
                end
            end

            if type(GetAllTrackingVehiclesInstances) == 'function' then
                local instances = GetAllTrackingVehiclesInstances()
                for _, routeInstances in pairs(instances) do
                    for _, inst in pairs(routeInstances) do
                        if not inst.destroyed then
                            if inst.vehicle and DoesEntityExist(inst.vehicle) then
                                SetEntityNoCollisionEntity(inst.vehicle, ped, true)
                                SetEntityNoCollisionEntity(ped, inst.vehicle, true)
                            end
                            if inst.ped and DoesEntityExist(inst.ped) then
                                SetEntityNoCollisionEntity(inst.ped, ped, true)
                                SetEntityNoCollisionEntity(ped, inst.ped, true)
                            end
                        end
                    end
                end
            end

            Wait(500)
        end
    end)
end

local function publishWeaponsConfig()
    local slots = {}
    local weapons = getWeapons()
    for i = 1, #weapons do
        slots[#slots + 1] = {
            slot   = weapons[i].slot,
            label  = weapons[i].label,
            weapon = weapons[i].weapon,
        }
    end
    SendNUIMessage({ action = 'tweapons', data = { slots = slots, selected = currentSlot } })
end

---@param slot number
local function selectSlot(slot)
    if not hudActive then return end
    local item = findWeaponConfig(slot)
    if not item then return end
    local ped = PlayerPedId()
    local hash = getWeaponHash(item)
    if hash == 0 then return end
    if not HasPedGotWeapon(ped, hash, false) then return end

    SetCurrentPedWeapon(ped, hash, true)
    currentSlot = slot

    local mult = tonumber(item.speedMultiplier) or 1.0
    SetRunSprintMultiplierForPlayer(PlayerId(), mult + 0.0)

    SendNUIMessage({ action = 'tweapon', selected = slot, weapon = item.weapon })
end

local function giveLoadout()
    local ped = PlayerPedId()
    RemoveAllPedWeapons(ped, true)
    local weapons = getWeapons()
    for i = 1, #weapons do
        local item = weapons[i]
        local hash = getWeaponHash(item)
        if hash ~= 0 then
            GiveWeaponToPed(ped, hash, item.ammo or 0, false, false)
        end
    end
    currentSlot = 1
    selectSlot(1)
end

local function startControlBlockThread()
    controlBlockThreadId = controlBlockThreadId + 1
    local myId = controlBlockThreadId
    CreateThread(function()
        while hudActive and myId == controlBlockThreadId do
            for i = 1, #BLOCKED_CONTROLS do
                DisableControlAction(0, BLOCKED_CONTROLS[i], true)
            end
            Wait(0)
        end
    end)
end

local function startPlayerHud()
    if hudActive then return end
    hudActive = true

    local ped = PlayerPedId()
    SetEntityMaxHealth(ped, getCfg().startHealth or 200)
    SetEntityHealth(ped, getCfg().startHealth or 200)
    SetPedArmour(ped, getCfg().startArmor or 100)

    giveLoadout()
    publishWeaponsConfig()

    SendNUIMessage({ action = 'thudVisible', value = true })
    startHudThread()
    startGodmodeLoop()
    startControlBlockThread()
end

local function stopPlayerHud()
    if not hudActive then return end
    hudActive = false
    godmodeThreadId      = godmodeThreadId + 1
    hudThreadId          = hudThreadId + 1
    controlBlockThreadId = controlBlockThreadId + 1

    local ped = PlayerPedId()
    SetPlayerInvincible(PlayerId(), false)
    SetEntityInvincible(ped, false)
    SetEntityCanBeDamaged(ped, true)
    SetPedInfiniteAmmoClip(ped, false)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    RemoveAllPedWeapons(ped, true)

    SendNUIMessage({ action = 'thudVisible', value = false })
end

AddEventHandler('multiTracking:whenEnter', startPlayerHud)
AddEventHandler('multiTracking:whenLeave', stopPlayerHud)

CreateThread(function()
    for i = 1, 5 do
        local cmd  = 'tracking_slot_' .. i
        local slot = i
        RegisterCommand('+' .. cmd, function() selectSlot(slot) end, false)
        RegisterCommand('-' .. cmd, function() end, false)
        RegisterKeyMapping('+' .. cmd, ('Slot %d (Tracking)'):format(i), 'keyboard', tostring(i))
    end
end)
