while not Core do Wait(100) end

---@class InventarioEquipModule
InventarioEquip = {}

local function log(level, msg)
    if Core and Core.log then return Core.log(level, ('[inventario:equip] %s'):format(msg)) end
    print(('[inventario:equip] [%s] %s'):format(level, msg))
end

local COMPONENT_SLOT_BY_ID = {}
for name, id in pairs(COMPONENT_MAP or {}) do COMPONENT_SLOT_BY_ID[id] = name end

local PROP_SLOT_BY_ID = {}
for name, id in pairs(PROP_MAP or {}) do PROP_SLOT_BY_ID[id] = name end

---@param item table
---@return string | nil
local function clothesSlotName(item)

    local m = item.metadata or {}

    if m.kind == 'component' then return COMPONENT_SLOT_BY_ID[m.slot_id] end
    if m.kind == 'prop'      then return PROP_SLOT_BY_ID[m.slot_id]      end

    return nil
end

---@param item table
---@return string
local function nonClothesSlot(item)

    local m = item.metadata or {}

    if item.category == 'weapon_skin'  then return tostring(m.weapon_hash or m.weapon or '_') end
    if item.category == 'vehicle_skin' then return tostring(m.vehicle_model or m.model or '_') end
    if item.category == 'parachute'    then return '_' end

    return tostring(m.slot_id or '_')
end

---@param appearance table
---@param category string
---@return number
local function countEquippedInCategory(appearance, category)

    local slots = appearance.equipped and appearance.equipped[category]

    if type(slots) ~= 'table' then return 0 end

    local n = 0

    for _ in pairs(slots) do n = n + 1 end

    return n
end

---@param userId number
---@param itemId string
---@param catalogCache table<string, table>
---@param equippedCache table
---@return { ok: boolean, error?: string, category?: string, slot?: string }
function InventarioEquip:equip(userId, itemId, catalogCache, equippedCache)

    local item = catalogCache[itemId]

    if not item then return { ok = false, error = 'item_not_found' } end

    local owns = Sql.single(
        'SELECT 1 AS owned FROM `player_inventory` WHERE `user_id` = ? AND `item_id` = ? LIMIT 1',
        { userId, itemId }
    )

    if not owns then return { ok = false, error = 'not_owned' } end

    local appearance = Sql.readAppearance(userId)

    appearance.equipped = appearance.equipped or {}
    appearance.equipped[item.category] = appearance.equipped[item.category] or {}

    local slot

    if item.category == 'clothes' then

        slot = clothesSlotName(item)

        if not slot then return { ok = false, error = 'invalid_clothes_slot' } end

        local m = item.metadata or {}

        appearance.clothes = appearance.clothes or {}
        appearance.clothes[slot] = { m.drawable or 0, m.texture or 0, m.palette or 0 }
    else
        slot = nonClothesSlot(item)
    end

    local cap = (Config and Config.maxEquippedPerCategory) or 64
    local currentlyEquippedHere = appearance.equipped[item.category][slot]

    if not currentlyEquippedHere and countEquippedInCategory(appearance, item.category) >= cap then
        return { ok = false, error = 'max_equipped_reached' }
    end

    appearance.equipped[item.category][slot] = itemId

    Sql.writeAppearance(userId, appearance)

    if equippedCache[userId] then
        equippedCache[userId][item.category] = equippedCache[userId][item.category] or {}
        equippedCache[userId][item.category][slot] = itemId
    end

    local src = Core.getUserSource and Core.getUserSource(userId) or nil

    if src then
        TriggerClientEvent('inventario:applyOne', src, {
            category = item.category,
            slot     = slot,
            item     = item,
        })
    end

    log('info', ('equip user=%s item=%s -> %s/%s'):format(userId, itemId, item.category, slot))

    return { ok = true, category = item.category, slot = slot }
end

---@param userId number
---@param category string
---@param slot string
---@param equippedCache table
---@return { ok: boolean, error?: string }
function InventarioEquip:unequip(userId, category, slot, equippedCache)

    local appearance = Sql.readAppearance(userId)

    if not (appearance.equipped and appearance.equipped[category] and appearance.equipped[category][slot]) then
        return { ok = true }
    end

    appearance.equipped[category][slot] = nil

    if category == 'clothes' and appearance.clothes then
        appearance.clothes[slot] = nil
    end

    Sql.writeAppearance(userId, appearance)

    if equippedCache[userId] and equippedCache[userId][category] then
        equippedCache[userId][category][slot] = nil
    end

    local src = Core.getUserSource and Core.getUserSource(userId) or nil

    if src then
        TriggerClientEvent('inventario:unapplyOne', src, {
            category = category,
            slot     = slot,
        })
    end

    log('info', ('unequip user=%s %s/%s'):format(userId, category, slot))

    return { ok = true }
end
