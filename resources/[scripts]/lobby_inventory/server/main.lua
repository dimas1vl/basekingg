while not Core do Wait(100) end

---@class Inventario
---@field catalog table<string, table>   in-memory catalog (itemId -> item)
---@field equippedCache table<number, table<string, table<string, string>>> per-user equipped cache
Inventario = {
    catalog        = {},
    equippedCache  = {},
}

local function log(level, msg)
    if Core and Core.log then return Core.log(level, ('[inventario] %s'):format(msg)) end
    print(('[inventario] [%s] %s'):format(level, msg))
end

-- ----------------------------------------------------------------------------
-- Public API (matches the contract in ARQUITETURA.md)
-- ----------------------------------------------------------------------------

---@param userId number
---@param itemId string
---@param source string
---@param sourceRef? string
---@return { ok: boolean, alreadyOwned?: boolean, error?: string }
function Inventario:grant(userId, itemId, source, sourceRef)
    return InventarioGrant:grant(userId, itemId, source, sourceRef, self.catalog)
end

---@param userId number
---@param itemId string
---@return { ok: boolean, error?: string, unequipped?: { category: string, slot: string }[] }
function Inventario:revoke(userId, itemId)
    return InventarioRevoke:revoke(userId, itemId, self.equippedCache)
end

---@param userId number
---@param itemId string
---@return { ok: boolean, error?: string, category?: string, slot?: string }
function Inventario:equip(userId, itemId)
    return InventarioEquip:equip(userId, itemId, self.catalog, self.equippedCache)
end

---@param userId number
---@param category string
---@param slot string
---@return { ok: boolean, error?: string }
function Inventario:unequip(userId, category, slot)
    return InventarioEquip:unequip(userId, category, slot, self.equippedCache)
end

---@param userId number
---@return { items: table[], equipped: table<string, table<string, string>> }
function Inventario:getInventory(userId)
    return InventarioInventory:getInventory(userId, self.catalog)
end

---@param userId number
---@return table<string, table<string, string>>
function Inventario:getEquipped(userId)
    local cached = self.equippedCache[userId]
    if cached then return cached end
    return InventarioInventory:loadEquipped(userId)
end

---@param opts? { category?: string, subcategory?: string, rarity?: string, purchasable?: boolean, search?: string }
---@return table[]
function Inventario:getCatalog(opts)
    return InventarioCatalog:filter(self.catalog, opts)
end

---@param userId number
---@param itemId string
---@return { ok: boolean, newBalance?: number, error?: string, alreadyOwned?: boolean }
function Inventario:buy(userId, itemId)
    return InventarioShop:buy(userId, itemId, self.catalog)
end

---@return { label: string, path: string, enabled: boolean }
function Inventario:getNavbarEntry()
    return {
        label   = Config.navbar.label,
        path    = Config.navbar.path,
        enabled = Config.navbar.enabled,
    }
end

-- ----------------------------------------------------------------------------
-- RPC bindings (NUI <-> server, namespace net.inventario:*)
-- ----------------------------------------------------------------------------

RPC:bind({
    getMyInventory = function()
        local src = source
        local userId = Core.getUserId(src)
        if not userId then return { items = {}, equipped = {} } end
        return Inventario:getInventory(userId)
    end,

    getCatalog = function(opts)
        return Inventario:getCatalog(opts)
    end,

    getMyEquipped = function()
        local src = source
        local userId = Core.getUserId(src)
        if not userId then return {} end
        return Inventario:getEquipped(userId)
    end,

    equipItems = function(itemIds)
        local src = source
        local userId = Core.getUserId(src)
        if not userId then return { ok = false, error = 'no user' } end
        if type(itemIds) ~= 'table' then return { ok = false, error = 'invalid payload' } end

        local results = {}
        local allOk = true
        for i = 1, #itemIds do
            local r = Inventario:equip(userId, itemIds[i])
            results[i] = { itemId = itemIds[i], ok = r.ok, error = r.error, category = r.category, slot = r.slot }
            if not r.ok then allOk = false end
        end
        return { ok = allOk, results = results }
    end,

    unequipSlots = function(slots)
        local src = source
        local userId = Core.getUserId(src)
        if not userId then return { ok = false, error = 'no user' } end
        if type(slots) ~= 'table' then return { ok = false, error = 'invalid payload' } end

        local results = {}
        local allOk = true
        for i = 1, #slots do
            local entry = slots[i] or {}
            local r = Inventario:unequip(userId, entry.category, entry.slot)
            results[i] = { category = entry.category, slot = entry.slot, ok = r.ok, error = r.error }
            if not r.ok then allOk = false end
        end
        return { ok = allOk, results = results }
    end,

    buyItem = function(itemId)
        local src = source
        local userId = Core.getUserId(src)
        if not userId then return { ok = false, error = 'no user' } end
        return Inventario:buy(userId, itemId)
    end,
})

-- ----------------------------------------------------------------------------
-- Boot: wait for Core + oxmysql, then load catalog and wire hooks.
-- ----------------------------------------------------------------------------

CreateThread(function()
    while not Core do Wait(100) end
    while GetResourceState('oxmysql') ~= 'started' do Wait(100) end
    -- Give utils/sql.lua a beat to run DDL.
    Wait(750)

    local ok, cache = pcall(function() return InventarioCatalog:loadAndSync() end)
    if not ok then
        log('error', ('catalog load failed: %s'):format(tostring(cache)))
        Inventario.catalog = {}
    else
        Inventario.catalog = cache
    end

    InventarioHooks:wire(Inventario)
    log('info', 'inventario module ready')

    -- Rehydrate any already-connected players (resource restart in dev).
    for _, ps in ipairs(GetPlayers()) do
        local src = tonumber(ps)
        if src and DoesPlayerExist(src) then
            local okId, userId = pcall(Core.getUserId, src)
            if okId and userId and not Inventario.equippedCache[userId] then
                local okEq, equipped = pcall(InventarioInventory.loadEquipped, InventarioInventory, userId)
                if okEq then
                    Inventario.equippedCache[userId] = equipped or {}
                end
            end
        end
    end
end)

-- ----------------------------------------------------------------------------
-- Export
-- ----------------------------------------------------------------------------

exports('GetInventario', function()
    return Inventario
end)
