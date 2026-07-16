---@param query string
---@param params? any[]
---@return table | nil
function Admin.db.single(query, params)
    return exports['oxmysql']:singleSync(query, params)
end

---@param query string
---@param params? any[]
---@return table
function Admin.db.query(query, params)
    return exports['oxmysql']:querySync(query, params)
end

---Run a write statement (INSERT/UPDATE/DELETE) that does not need an insert id.
---@param query string
---@param params? any[]
---@return any result
function Admin.db.execute(query, params)
    return exports['oxmysql']:querySync(query, params)
end

---@param query string
---@param params? any[]
---@return number insertId
function Admin.db.insert(query, params)
    return exports['oxmysql']:insertSync(query, params)
end

CreateThread(function()
    Wait(2500)
    local ok, err = pcall(function()
        Admin.db.execute([[ALTER TABLE `bans`
            MODIFY COLUMN `expires_at` DATETIME NULL DEFAULT NULL,
            MODIFY COLUMN `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP]])
    end)
    if ok then
        Admin.log('info', 'bans datetime migration applied')
    else
        Admin.log('warning', ('bans datetime migration skipped: %s'):format(tostring(err)))
    end
end)
