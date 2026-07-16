---@class BanInfo
---@field user_id number
---@field reason string
---@field staff_id number
---@field created_at string
---@field expires_at string
---@field staff_name string | nil
---@field target_name string | nil

---@class Bans
local Bans = {}

---@param userId number Target user id
---@param staffId number | nil Admin user id (nil for console)
---@param days number Duration in days; 0 means permanent
---@param reason string
---@return boolean ok
function Bans:create(userId, staffId, days, reason)
    if not userId then return false end
    reason = (reason ~= nil and reason ~= '') and tostring(reason):sub(1, 255) or 'Sem motivo'
    days = tonumber(days) or 0

    local expiresExpr, params
    if days <= 0 then
        expiresExpr = '?'
        params = { userId, reason, staffId or 0, Config.permanentBanDate, reason, staffId or 0, Config.permanentBanDate }
    else
        expiresExpr = 'DATE_ADD(NOW(), INTERVAL ? DAY)'
        params = { userId, reason, staffId or 0, days, reason, staffId or 0, days }
    end

    Admin.db.execute(([[
        INSERT INTO `bans` (`user_id`, `reason`, `staff_id`, `created_at`, `expires_at`)
        VALUES (?, ?, ?, NOW(), %s)
        ON DUPLICATE KEY UPDATE
            `reason` = ?, `staff_id` = ?, `created_at` = NOW(), `expires_at` = %s
    ]]):format(expiresExpr, expiresExpr), params)

    Admin.log('info', ('user %s banned by staff %s for "%s" (days=%s)'):format(userId, staffId or 0, reason, days))
    return true
end

---@param userId number
---@return boolean removed True when a ban row existed and was removed
function Bans:remove(userId)
    if not userId then return false end
    local existing = Admin.db.single('SELECT `user_id` FROM `bans` WHERE `user_id` = ?', { userId })
    if not existing then return false end

    Admin.db.execute('DELETE FROM `bans` WHERE `user_id` = ?', { userId })
    Admin.log('info', ('ban removed for user %s'):format(userId))
    return true
end

---@param userId number
---@return BanInfo | nil
function Bans:get(userId)
    if not userId then return nil end
    return Admin.db.single([[
        SELECT
            b.`user_id`, b.`reason`, b.`staff_id`, b.`created_at`, b.`expires_at`,
            s.`name` AS staff_name,
            t.`name` AS target_name
        FROM `bans` b
        LEFT JOIN `users` s ON s.`id` = b.`staff_id`
        LEFT JOIN `users` t ON t.`id` = b.`user_id`
        WHERE b.`user_id` = ?
    ]], { userId })
end

---@return table[]
function Bans:list()
    local rows = Admin.db.query([[
        SELECT
            b.`user_id`, b.`reason`, b.`staff_id`, b.`created_at`, b.`expires_at`,
            s.`name` AS staff_name,
            t.`name` AS target_name
        FROM `bans` b
        LEFT JOIN `users` s ON s.`id` = b.`staff_id`
        LEFT JOIN `users` t ON t.`id` = b.`user_id`
        ORDER BY b.`created_at` DESC
    ]]) or {}

    local out = {}
    for i = 1, #rows do
        local r = rows[i]
        local permanent = type(r.expires_at) == 'string' and r.expires_at >= Config.permanentBanDate
        out[#out + 1] = {
            userId = r.user_id,
            name = r.target_name or ('user ' .. tostring(r.user_id)),
            reason = r.reason or 'Sem motivo',
            staffId = r.staff_id,
            staffName = r.staff_name or ('id ' .. tostring(r.staff_id)),
            createdAt = Admin.formatDate(r.created_at),
            expiresAt = permanent and 'Permanente' or Admin.formatDate(r.expires_at),
            permanent = permanent,
        }
    end
    return out
end

Admin.bans = Bans
