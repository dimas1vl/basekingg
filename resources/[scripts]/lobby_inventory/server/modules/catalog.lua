while not Core do Wait(100) end

---@class InventarioCatalogModule
InventarioCatalog = {}

local VALID_CATEGORIES = {}
for _, c in ipairs(Config.validCategories) do VALID_CATEGORIES[c] = true end

local VALID_RARITIES = {}
for _, r in ipairs(Config.validRarities) do VALID_RARITIES[r] = true end

local function log(level, msg)
    if Core and Core.log then return Core.log(level, ('[inventario:catalog] %s'):format(msg)) end
    print(('[inventario:catalog] [%s] %s'):format(level, msg))
end

---Validate a catalog item shape. Returns ok, err.
---@param item table
---@return boolean
---@return string | nil
local function validate(item)
    if type(item) ~= 'table' then return false, 'not a table' end
    if type(item.id) ~= 'string' or item.id == '' then return false, 'missing id' end
    if type(item.name) ~= 'string' or item.name == '' then return false, 'missing name' end
    if type(item.category) ~= 'string' or not VALID_CATEGORIES[item.category] then
        return false, ('invalid category: %s'):format(tostring(item.category))
    end
    if type(item.subcategory) ~= 'string' or item.subcategory == '' then return false, 'missing subcategory' end
    if type(item.rarity) ~= 'string' or not VALID_RARITIES[item.rarity] then
        return false, ('invalid rarity: %s'):format(tostring(item.rarity))
    end
    if type(item.metadata) ~= 'table' then return false, 'missing metadata' end
    if item.purchasable and not item.price then
        return false, 'purchasable item without price'
    end
    return true
end

---Load all catalog items from the shared registry, validate them, upsert to DB
---and populate the in-memory cache. Items present in DB but absent from Lua
---are marked enabled=0 (soft delete preserves player ownership references).
---@return table<string, table> cache
function InventarioCatalog:loadAndSync()
    local cache = {}
    local seenIds = {}
    local valid = {}

    local raw = (_InventarioCatalogRegistry and _InventarioCatalogRegistry.items) or {}
    for i = 1, #raw do
        local item = raw[i]
        local ok, err = validate(item)
        if not ok then
            log('warning', ('catalog item rejected at index %d: %s (id=%s)'):format(i, tostring(err), tostring(item and item.id)))
        else
            if seenIds[item.id] then
                log('warning', ('duplicated catalog item id ignored: %s'):format(item.id))
            else
                seenIds[item.id] = true
                valid[#valid + 1] = item
                cache[item.id] = item
            end
        end
    end

    -- Batch upsert.
    for i = 1, #valid do
        local item = valid[i]
        local mdJson = json.encode(item.metadata or {})
        Sql.execute([[
            INSERT INTO `cosmetic_items` (`id`, `name`, `category`, `subcategory`, `rarity`, `price`, `purchasable`, `image`, `metadata`, `enabled`)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
            ON DUPLICATE KEY UPDATE
                `name`        = VALUES(`name`),
                `category`    = VALUES(`category`),
                `subcategory` = VALUES(`subcategory`),
                `rarity`      = VALUES(`rarity`),
                `price`       = VALUES(`price`),
                `purchasable` = VALUES(`purchasable`),
                `image`       = VALUES(`image`),
                `metadata`    = VALUES(`metadata`),
                `enabled`     = 1
        ]], {
            item.id,
            item.name,
            item.category,
            item.subcategory,
            item.rarity,
            item.price,
            item.purchasable and 1 or 0,
            item.image,
            mdJson,
        })
    end

    -- Soft-disable items that exist in DB but not in Lua (preserves FKs).
    local existing = Sql.query('SELECT `id` FROM `cosmetic_items` WHERE `enabled` = 1', {})
    if existing then
        local disabled = 0
        for i = 1, #existing do
            local id = existing[i].id
            if not seenIds[id] then
                Sql.execute('UPDATE `cosmetic_items` SET `enabled` = 0 WHERE `id` = ?', { id })
                disabled = disabled + 1
            end
        end
        if disabled > 0 then
            log('info', ('soft-disabled %d orphan catalog items'):format(disabled))
        end
    end

    log('info', ('catalog loaded: %d items'):format(#valid))
    return cache
end

---Filter the in-memory catalog cache. Returns an array of matching items.
---@param cache table<string, table>
---@param opts? { category?: string, rarity?: string, purchasable?: boolean, subcategory?: string, search?: string }
---@return table[]
function InventarioCatalog:filter(cache, opts)
    opts = opts or {}
    local out = {}
    local needle = opts.search and string.lower(opts.search) or nil

    for _, item in pairs(cache) do
        local include = true
        if opts.category and item.category ~= opts.category then include = false end
        if include and opts.subcategory and item.subcategory ~= opts.subcategory then include = false end
        if include and opts.rarity and item.rarity ~= opts.rarity then include = false end
        if include and opts.purchasable ~= nil and (item.purchasable and true or false) ~= (opts.purchasable and true or false) then
            include = false
        end
        if include and needle and not string.find(string.lower(item.name or ''), needle, 1, true)
            and not string.find(string.lower(item.id or ''), needle, 1, true) then
            include = false
        end
        if include then out[#out + 1] = item end
    end

    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end
