while not Core do Wait(100) end

---@class InventarioRevokeModule
InventarioRevoke = {}

local function log(level, msg)
    if Core and Core.log then return Core.log(level, ('[inventario:revoke] %s'):format(msg)) end
    print(('[inventario:revoke] [%s] %s'):format(level, msg))
end

---@param userId number
---@param itemId string
---@param equippedCache table<number, table<string, table<string, string>>>
---@return { ok: boolean, error?: string, unequipped?: { category: string, slot: string }[] }
function InventarioRevoke:revoke(userId, itemId, equippedCache)

    if type(userId) ~= 'number' then return { ok = false, error = 'invalid userId' } end
    if type(itemId) ~= 'string' or itemId == '' then return { ok = false, error = 'invalid itemId' } end

    local appearance = Sql.readAppearance(userId)
    local unequipped = {}

    if type(appearance.equipped) == 'table' then

        for category, slots in pairs(appearance.equipped) do

            if type(slots) == 'table' then

                for slot, equippedItemId in pairs(slots) do

                    if equippedItemId == itemId then
                        slots[slot] = nil
                        if category == 'clothes' and appearance.clothes then
                            appearance.clothes[slot] = nil
                        end
                        unequipped[#unequipped + 1] = { category = category, slot = slot }
                    end
                end
            end
        end

        if #unequipped > 0 then
            Sql.writeAppearance(userId, appearance)
        end
    end

    local userCache = equippedCache[userId]
    local src = Core.getUserSource and Core.getUserSource(userId) or nil

    for i = 1, #unequipped do

        local u = unequipped[i]

        if userCache and userCache[u.category] then
            userCache[u.category][u.slot] = nil
        end

        if src and DoesPlayerExist(src) then
            TriggerClientEvent('inventario:unapplyOne', src, {
                category = u.category,
                slot     = u.slot,
            })
        end
    end

    Sql.execute(
        'DELETE FROM `player_inventory` WHERE `user_id` = ? AND `item_id` = ?',
        { userId, itemId }
    )

    log('info', ('revoked %s from user %s (unequipped=%d)'):format(itemId, userId, #unequipped))

    return { ok = true, unequipped = unequipped }
end
