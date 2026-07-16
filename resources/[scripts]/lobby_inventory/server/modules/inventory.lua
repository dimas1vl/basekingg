while not Core do Wait(100) end

---@class InventarioInventoryModule
InventarioInventory = {}

local function log(level, msg)
    if Core and Core.log then return Core.log(level, ('[inventario:inventory] %s'):format(msg)) end
    print(('[inventario:inventory] [%s] %s'):format(level, msg))
end

---@param userId number
---@return table<string, table<string, string>>
function InventarioInventory:loadEquipped(userId)

    local appearance = Sql.readAppearance(userId)
    local equipped = appearance.equipped

    if type(equipped) ~= 'table' then return {} end

    return equipped
end

---@param userId number
---@return table<string, boolean>
function InventarioInventory:loadOwnedSet(userId)

    local rows = Sql.query(
        'SELECT `item_id` FROM `player_inventory` WHERE `user_id` = ?',
        { userId }
    ) or {}

    local set = {}

    for i = 1, #rows do set[rows[i].item_id] = true end

    return set
end

---@param userId number
---@param catalogCache table<string, table>
---@return { items: table[], equipped: table<string, table<string, string>> }
function InventarioInventory:getInventory(userId, catalogCache)

    local owned    = self:loadOwnedSet(userId)
    local equipped = self:loadEquipped(userId)

    local items = {}

    for itemId in pairs(owned) do
        local item = catalogCache[itemId]
        if item then
            items[#items + 1] = item
        else
            items[#items + 1] = {
                id          = itemId,
                name        = itemId,
                category    = 'unknown',
                subcategory = 'unknown',
                rarity      = 'common',
                purchasable = false,
                metadata    = {},
            }
            log('warning', ('inventory: orphan item_id=%s for user=%s (kept as placeholder)'):format(itemId, userId))
        end
    end

    table.sort(items, function(a, b) return a.id < b.id end)

    return { items = items, equipped = equipped }
end

---@param userId number
---@param itemId string
---@return boolean
function InventarioInventory:owns(userId, itemId)

    local row = Sql.single(
        'SELECT 1 AS owned FROM `player_inventory` WHERE `user_id` = ? AND `item_id` = ? LIMIT 1',
        { userId, itemId }
    )

    return row ~= nil
end
