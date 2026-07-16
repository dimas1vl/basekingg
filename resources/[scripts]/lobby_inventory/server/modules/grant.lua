while not Core do Wait(100) end

---@class InventarioGrantModule
InventarioGrant = {}

local VALID_SOURCES = {}
for _, s in ipairs(Config.validSources) do VALID_SOURCES[s] = true end

local function log(level, msg)
    if Core and Core.log then return Core.log(level, ('[inventario:grant] %s'):format(msg)) end
    print(('[inventario:grant] [%s] %s'):format(level, msg))
end

---Grant an item to a user. Idempotent via INSERT ON DUPLICATE KEY UPDATE —
---duplicates silently update source/source_ref and return alreadyOwned=true.
---@param userId number
---@param itemId string
---@param source string  one of Config.validSources
---@param sourceRef? string Optional reference (e.g. lootbox id, admin id)
---@param catalogCache table<string, table>
---@return { ok: boolean, alreadyOwned?: boolean, error?: string }
function InventarioGrant:grant(userId, itemId, source, sourceRef, catalogCache)
    if not userId or type(userId) ~= 'number' then
        return { ok = false, error = 'invalid userId' }
    end
    if type(itemId) ~= 'string' or itemId == '' then
        return { ok = false, error = 'invalid itemId' }
    end
    if not VALID_SOURCES[source] then
        return { ok = false, error = ('invalid source: %s'):format(tostring(source)) }
    end

    local item = catalogCache[itemId]
    if not item then
        return { ok = false, error = 'item not found in catalog' }
    end

    -- Check if already owned BEFORE the insert so we can report it.
    local existing = Sql.single(
        'SELECT 1 AS owned FROM `player_inventory` WHERE `user_id` = ? AND `item_id` = ? LIMIT 1',
        { userId, itemId }
    )
    local alreadyOwned = existing ~= nil

    Sql.execute([[
        INSERT INTO `player_inventory` (`user_id`, `item_id`, `source`, `source_ref`)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE `source` = VALUES(`source`), `source_ref` = VALUES(`source_ref`)
    ]], {
        userId,
        itemId,
        source,
        sourceRef,
    })

    if not alreadyOwned then
        log('info', ('granted %s to user %s (source=%s)'):format(itemId, userId, source))
    end

    return { ok = true, alreadyOwned = alreadyOwned }
end
