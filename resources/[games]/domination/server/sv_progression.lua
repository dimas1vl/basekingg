DomCfg = Config.Domination

---@param userId number
---@return number xp
---@return number money
function loadProgress(userId)
    local row = Sql.single('SELECT `xp`, `money` FROM `domination_progress` WHERE `user_id` = ?', { userId })
    if not row then
        Sql.execute('INSERT IGNORE INTO `domination_progress` (`user_id`, `xp`, `money`) VALUES (?, 0, 0)', { userId })
        return 0, 0
    end
    return tonumber(row.xp) or 0, tonumber(row.money) or 0
end

function markDirty(session)
    if session then session.dirty = true end
end

function flushProgress(session)
    if not session or not session.userId or not session.dirty then return end
    Sql.execute(
        'INSERT INTO `domination_progress` (`user_id`, `xp`, `money`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `xp` = ?, `money` = ?',
        { session.userId, session.xp or 0, session.money or 0, session.xp or 0, session.money or 0 }
    )
    session.dirty = false
end

function flushAllProgress()
    local list = {}
    for _, s in pairs(sessions) do list[#list + 1] = s end
    for i = 1, #list do flushProgress(list[i]) end
end

CreateThread(function()
    while true do
        Wait(300000)
        flushAllProgress()
    end
end)

---@param userId number
---@return table<string, boolean> set de weapon_id possuídos (compras)
function loadOwned(userId)
    local owned = {}
    local rows = Sql.query('SELECT `weapon_id` FROM `domination_weapons` WHERE `user_id` = ?', { userId })
    if rows then
        for i = 1, #rows do owned[rows[i].weapon_id] = true end
    end
    return owned
end

---@param userId number
---@return table<string, string> category -> weapon_id salvo
function loadLoadout(userId)
    local map = {}
    local rows = Sql.query('SELECT `category`, `weapon_id` FROM `domination_loadout` WHERE `user_id` = ?', { userId })
    if rows then
        for i = 1, #rows do map[rows[i].category] = rows[i].weapon_id end
    end
    return map
end

function sessionOwns(session, weaponCfg)
    if not weaponCfg then return false end
    if weaponCfg.default or (tonumber(weaponCfg.price) or 0) <= 0 then return true end
    return session.owned[weaponCfg.id] == true
end

function resolveEquipped(session, savedLoadout)
    local equipped = {}
    for i = 1, #DomCfg.categories do
        local cat = DomCfg.categories[i]
        local chosenId = savedLoadout[cat.key]
        local cfg = chosenId and (select(1, DomCfg.findWeapon(chosenId, cat.key))) or nil
        if not cfg or not sessionOwns(session, cfg) then
            cfg = DomCfg.getDefaultWeapon(cat.key)
        end
        equipped[cat.key] = cfg and cfg.id or nil
    end
    return equipped
end

function getGems(src)
    local s = sessions[src]
    return s and (tonumber(s.money) or 0) or 0
end

function respawnMsFor(src)
    local r = DomCfg.respawn or {}
    local secs = tonumber(r.default) or 10
    local ok, info = pcall(Core.getUserInfo, src)
    if ok and info then
        if info.role == 'admin' and r.admin then secs = r.admin
        elseif info.role == 'streamer' and r.streamer then secs = r.streamer
        elseif (tonumber(info.premium) or 0) > 0 and r.vip then secs = r.vip end
    end
    return math.floor((tonumber(secs) or 10) * 1000)
end

function buildState(src, session)
    local per   = DomCfg.level.xpPerLevel
    local xp    = session.xp or 0
    local level = DomCfg.levelFromXp(xp)
    session.level = level

    local categories = {}
    for i = 1, #DomCfg.categories do
        local cat  = DomCfg.categories[i]
        local list = DomCfg.weapons[cat.key] or {}
        local weapons = {}
        for j = 1, #list do
            local w = list[j]
            local owned = sessionOwns(session, w)
            weapons[#weapons + 1] = {
                id       = w.id,
                label    = w.label,
                icon     = w.icon,
                level    = w.level,
                price    = w.price,
                owned    = owned,
                equipped = session.equipped[cat.key] == w.id,
                locked   = (not owned) and (level < w.level),
            }
        end
        categories[#categories + 1] = {
            key     = cat.key,
            label   = cat.label,
            slot    = cat.slot,
            weapons = weapons,
        }
    end

    return {
        level       = level,
        xp          = xp,
        xpPerLevel  = per,
        xpIntoLevel = (level >= (DomCfg.level.maxLevel or 100)) and per or (xp % per),
        gems        = getGems(src),
        respawnMs   = respawnMsFor(src),
        kills       = session.kills or 0,
        deaths      = session.deaths or 0,
        equipped    = session.equipped,
        categories  = categories,
    }
end

function pushState(src)
    local session = sessions[src]
    if not session then return end
    TriggerClientEvent('domination:state', src, buildState(src, session))
end
