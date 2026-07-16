while not GM do Wait(0) end

local RESOURCE = GetCurrentResourceName()

local CHEST_TYPES = { 'RIFLE', 'SUB', 'HEALTH', 'AMMO', 'GRENADES' }

local CHEST_LOOT = {
    RIFLE = {
        { 'WEAPON_ASSAULTRIFLE', 1 },
        { 'WEAPON_CARBINERIFLE', 1 },
        { 'WEAPON_SPECIALCARBINE', 1 },
    },

    SUB = {
        { 'WEAPON_PISTOL_MK2', 1 },
        { 'WEAPON_MICROSMG', 1 },
        { 'WEAPON_MACHINEPISTOL', 1 },
        { 'WEAPON_APPISTOL', 1 },
        { 'WEAPON_PUMPSHOTGUN', 1 },
        { 'WEAPON_ASSAULTSMG', 1 },
    },

    HEALTH = {
        { 'HEALTH_STANDARD', 3 },
        { 'ARMOUR_STANDARD', 2 },
    },

    AMMO = {
        { 'WEAPON_AMMO', 60 },
        { 'WEAPON_AMMO', 90 },
        { 'WEAPON_AMMO', 120 },
    },

    GRENADES = {
        { 'WEAPON_SMOKEGRENADE', 2 },
    },
}

local SPAWN_DATA = gLootCoords

local HASH_TO_ITEM = {}

for itemName, def in pairs(GItems) do

    if def.model then
        HASH_TO_ITEM[GetHashKey(def.model)] = itemName
    end
end

---@class ChestEntry
---@field type string
---@field coords number[]

---Resolve um único baú on-demand a partir de (seed, idx). Sem estado global, sem iterar todos os pontos.
---@param seed number
---@param idx number
---@return ChestEntry | nil
local function getChest(seed, idx)

    local entry = SPAWN_DATA[idx]

    if not entry then return nil end

    if LootRng.spawnRoll(seed, idx) >= Config.BR.loot.chestSpawnChance then
        return nil
    end

    local x, y, z = entry[1], entry[2], entry[3]

    local sz = Config.BR.safezone
    local cx, cy = sz.initialCenter.x, sz.initialCenter.y
    local dx, dy = x - cx, y - cy
    local r2 = sz.initialRadius * sz.initialRadius

    if (dx * dx + dy * dy) >= r2 then
        return nil
    end

    local chestType = CHEST_TYPES[LootRng.typeIndex(seed, idx, #CHEST_TYPES)]

    return { type = chestType, coords = { x, y, z } }
end

GM:on('matchStarted', function(match)

    match:setData('openedChests', {})
    match:setData('pickups', {})
    match:setData('nextPickupId', 1)
end)

GM:registerNetEvent('chest.open', function(match, src, chestIndex)

    print(('[loot] chest.open: src=%d chestIndex=%s'):format(src, tostring(chestIndex)))

    local openedChests = match:getData('openedChests') or {}

    if openedChests[chestIndex] then
        print(('[loot] chest.open: chest %s already opened'):format(tostring(chestIndex)))
        return
    end

    openedChests[chestIndex] = true
    match:setData('openedChests', openedChests)

    match:emitClients('chest.opened', chestIndex)

    local seed = match:getData('seed')

    if not seed then
        print(('[loot] chest.open: seed is nil for match %d'):format(match.id))
        return
    end

    local chestEntry = getChest(seed, chestIndex)

    if not chestEntry then
        print(('[loot] chest.open: chestIndex %s NOT FOUND (no spawn or out of safezone)'):format(tostring(chestIndex)))
        return
    end

    local chestType = chestEntry.type
    local chestCoords = chestEntry.coords

    if not CHEST_LOOT[chestType] then
        print(('[loot] chest.open: no loot table for type %s'):format(chestType))
        return
    end

    local lootPool = CHEST_LOOT[chestType]
    local loot = lootPool[LootRng.lootIndex(seed, chestIndex, #lootPool)]
    local itemName = loot[1]
    local itemAmount = loot[2]

    local itemDef = GItems[itemName]

    if not itemDef or not itemDef.model then
        print(('[loot] chest.open: no model for item %s'):format(itemName))
        return
    end

    local modelHash = GetHashKey(itemDef.model)
    local pickups = match:getData('pickups') or {}
    local nextId = match:getData('nextPickupId') or 1
    local dropCoords = { chestCoords[1], chestCoords[2], chestCoords[3] + 1.0 }

    pickups[nextId] = { hash = modelHash, amount = itemAmount, coords = dropCoords, fromChest = true }

    match:setData('pickups', pickups)
    match:setData('nextPickupId', nextId + 1)

    match:emitClients('pickup.created', nextId, modelHash, dropCoords)

    print(('[loot] chest.open: dropped %s x%d as pickup #%d at chest %d (model=%s hash=%s coords=%.1f,%.1f,%.1f)'):format(
        itemName, itemAmount, nextId, chestIndex, itemDef.model, tostring(modelHash),
        dropCoords[1], dropCoords[2], dropCoords[3]
    ))

    log('info', ('match %d: chest %d (%s) opened by src=%d, dropped %s x%d as pickup #%d'):format(
        match.id, chestIndex, chestType, src, itemName, itemAmount, nextId
    ))

    local ammoName = GetWeaponAmmo(itemName)
    if ammoName then
        local ammoDef = GItems[ammoName]
        local ammoHash = GetHashKey(ammoDef.model)
        local ammoCoords = { chestCoords[1] + 0.4, chestCoords[2], chestCoords[3] + 1.0 }
        local ammoId = match:getData('nextPickupId') or (nextId + 1)

        pickups[ammoId] = { hash = ammoHash, amount = 30, coords = ammoCoords }

        match:setData('pickups', pickups)
        match:setData('nextPickupId', ammoId + 1)

        match:emitClients('pickup.created', ammoId, ammoHash, ammoCoords)
    end
end)

GM:registerNetEvent('pickup.add', function(match, src, pickupHash, amount, coords)

    local pickups = match:getData('pickups') or {}
    local nextId = match:getData('nextPickupId') or 1

    pickups[nextId] = { hash = pickupHash, amount = amount, coords = coords }

    match:setData('pickups', pickups)
    match:setData('nextPickupId', nextId + 1)

    match:emitClients('pickup.created', nextId, pickupHash, coords)
end)

GM:registerNetEvent('pickup.take', function(match, src, pickupId)

    local pickups = match:getData('pickups') or {}

    if not pickups[pickupId] then return end

    local pickup = pickups[pickupId]
    local fromChest = pickup.fromChest == true

    pickups[pickupId] = nil
    match:setData('pickups', pickups)

    match:emitClients('pickup.taken', pickupId)

    local itemName = HASH_TO_ITEM[pickup.hash]

    if not itemName then return end

    local giveAmount = math.min(pickup.amount, GetItemMax(itemName))

    TriggerClientEvent(('net.%s:pickup.loot'):format(RESOURCE), src, itemName, giveAmount, fromChest)
end)

GM:registerNetEvent('inventory.update', function(match, src)
end)
