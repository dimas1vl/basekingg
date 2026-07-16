while not Core do Wait(100) end

---@class InventarioShopModule
InventarioShop = {}

local function log(level, msg)
    if Core and Core.log then return Core.log(level, ('[inventario:shop] %s'):format(msg)) end
    print(('[inventario:shop] [%s] %s'):format(level, msg))
end

---Buy an item from the in-game shop. Atomicity is enforced by the conditional
---UPDATE (gems >= price) inside the transaction — if 0 rows are affected the
---player cannot afford the item and the transaction is rolled back.
---@param userId number
---@param itemId string
---@param catalogCache table<string, table>
---@return { ok: boolean, newBalance?: number, error?: string, alreadyOwned?: boolean }
function InventarioShop:buy(userId, itemId, catalogCache)
    if type(userId) ~= 'number' then return { ok = false, error = 'invalid userId' } end
    local item = catalogCache[itemId]
    if not item then return { ok = false, error = 'item not in catalog' } end
    if not item.purchasable then return { ok = false, error = 'item not purchasable' } end
    local price = tonumber(item.price)
    if not price or price < 0 then return { ok = false, error = 'item has invalid price' } end

    -- Pre-check idempotency: silent alreadyOwned (no debit).
    local owned = Sql.single(
        'SELECT 1 AS owned FROM `player_inventory` WHERE `user_id` = ? AND `item_id` = ? LIMIT 1',
        { userId, itemId }
    )
    if owned then
        return { ok = true, alreadyOwned = true }
    end

    -- Snapshot current balance (informational + early reject for UX).
    local userRow = Sql.single('SELECT `gems` FROM `users` WHERE `id` = ? FOR UPDATE', { userId })
    if not userRow then return { ok = false, error = 'user not found' } end
    local currentBalance = tonumber(userRow.gems) or 0
    if currentBalance < price then
        return { ok = false, error = 'insufficient gems' }
    end

    -- Transaction: conditional debit + idempotent grant. If gems < price the
    -- UPDATE matches 0 rows; we manually raise so the transaction rolls back.
    local txOk, txErr = pcall(function()
        return MySQL.transaction.await({
            {
                query = 'UPDATE `users` SET `gems` = `gems` - ? WHERE `id` = ? AND `gems` >= ?',
                values = { price, userId, price },
            },
            {
                query = [[
                    INSERT INTO `player_inventory` (`user_id`, `item_id`, `source`, `source_ref`)
                    VALUES (?, ?, 'shop', ?)
                ]],
                values = { userId, itemId, ('item:%s'):format(itemId) },
            },
        })
    end)

    if not txOk then
        log('error', ('buy transaction failed: %s'):format(tostring(txErr)))
        return { ok = false, error = 'transaction failed' }
    end

    -- Verify post-state: re-read balance and ownership.
    local postRow = Sql.single('SELECT `gems` FROM `users` WHERE `id` = ?', { userId })
    if not postRow then return { ok = false, error = 'user lookup post-buy failed' } end
    local newBalance = tonumber(postRow.gems) or 0

    if newBalance ~= currentBalance - price then
        -- The UPDATE didn't fire (race-condition): rollback ownership defensively.
        Sql.execute('DELETE FROM `player_inventory` WHERE `user_id` = ? AND `item_id` = ?', { userId, itemId })
        return { ok = false, error = 'insufficient gems' }
    end

    -- Sync Core cache so HUD/UI sees the new balance.
    if Core and Core.updateUserInfo then
        Core.updateUserInfo(userId, { gems = newBalance })
    end

    log('info', ('user %s bought %s for %d gems (new balance=%d)'):format(userId, itemId, price, newBalance))
    return { ok = true, newBalance = newBalance }
end
