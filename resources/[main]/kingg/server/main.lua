---@class Core
---@field users_src table<number, number>
---@field src_users table<number, number>
---@field users_info table<number, UserRow>
---@field exports table<string, function>
Core = {
    users_src = {}, -- (map) [source] = user_id
    src_users = {}, -- (map) [user_id] = source
    users_info = {}, -- (map) [user_id] = UserRow
    exports = {},
}

Core.log = function(level, message)
    if log then return log(level, message) end
    print(('[%s] %s'):format(tostring(level or 'info'), tostring(message or '')))
end

_G.devMode = GetConvarInt('sv_devmode', 0) == 1

---@class UserRow
---@field id number
---@field xp number
---@field gems number
---@field premium number
---@field crew_id number
---@field role string
---@field banner number
---@field badges table
---@field wins number
---@field loss number
---@field kills number
---@field deaths number
---@field name string
---@field gender 'male' | 'female' | nil
---@field birthdate string | nil
---@field appearance table | nil
function Core:processUserInfo(info)
    assert(info.id, 'User id is required')
    local ok, prettyBadges = pcall(json.decode, info.badges or '[]')
    if not ok then
        prettyBadges = {}
    end
    info.badges = prettyBadges

    if info.appearance then
        local okApp, prettyApp = pcall(json.decode, info.appearance)
        info.appearance = okApp and prettyApp or nil
    end

    self.users_info[info.id] = info
    log('info', ('User %s info processed'):format(info.id))
end

---@param userId number
---@return number | nil
function Core.getUserSource(userId)
    assert(userId, '(getUserSource) User id is required')
    return Core.src_users[tonumber(userId)]
end

---@param userId number
---@param fields table<string, any>
---@return boolean
function Core.updateUserInfo(userId, fields)
    local info = Core.users_info[userId]
    if not info then return false end
    for k, v in pairs(fields) do
        info[k] = v
    end
    return true
end

---Reloads the user row from the database and re-processes it into users_info cache.
---@param userId number
---@return UserRow | nil
function Core.reloadUserInfo(userId)
    assert(userId, '(reloadUserInfo) User id is required')
    local row = Core.single('SELECT * FROM `users` WHERE `id` = ?', { userId })
    if not row then return nil end
    Core:processUserInfo(row)
    return Core.users_info[userId]
end

---@param src number
---@return string
function Core.getUserName(src)
    local info = Core.getUserInfo(src)
    return info and info.name or GetPlayerName(tostring(src)) or ('Player %d'):format(src)
end

---@param src number
---@return UserRow | nil
function Core.getUserInfo(src)
    local userId = Core.getUserId(src)
    if not userId then return nil end
    return Core.users_info[userId]
end

---@param src number
---@return number
function Core.getUserId(src)
    src = tonumber(src)
    assert(DoesPlayerExist(src), '(getUserId) Player not found')
    if not Core.users_src[src] then
        -- search with identifiers
        local identifiers = GetPlayerIdentifiers(src)
        for i = 1, #identifiers do
            if identifiers[i]:sub(1,3) == 'ip:' then
                goto continue
            end
            local identifier = identifiers[i]
            local result = Core.single('SELECT user_id FROM identifiers WHERE identifier = ?', { identifier })
            if result then
                Core.users_src[src] = result.user_id
                break
            end
            ::continue::
        end
    end
    return Core.users_src[src]
end

local DISCORD_URL = 'https://discord.gg/KINGG'
local DISCORD_LABEL = 'discord.gg/KINGG'

---@param expires_at string | nil
---@return string
local function formatBanExpiry(expires_at)
    if type(expires_at) ~= 'string' then return 'Indefinido' end
    local y, m, d, hh, mm = expires_at:match('(%d+)-(%d+)-(%d+)[ T](%d+):(%d+)')
    if not y then return expires_at end
    if tonumber(y) >= 2037 then return 'Permanente' end
    return ('%s/%s/%s às %s:%s'):format(d, m, y, hh, mm)
end

---Build the AdaptiveCard shown on the connection screen for banned players.
---@param userId number
---@param ban_row table
---@return string json
local function buildBanCard(userId, ban_row)
    local reason = (ban_row.reason and ban_row.reason ~= '') and ban_row.reason or 'Não informado'
    local card = {
        type = 'AdaptiveCard',
        ['$schema'] = 'http://adaptivecards.io/schemas/adaptive-card.json',
        version = '1.3',
        body = {
            {
                type = 'Container',
                style = 'attention',
                bleed = true,
                items = {
                    {
                        type = 'TextBlock',
                        text = 'VOCÊ ESTÁ BANIDO',
                        weight = 'Bolder',
                        size = 'ExtraLarge',
                        color = 'Light',
                        horizontalAlignment = 'Center',
                        wrap = true,
                    },
                },
            },
            {
                type = 'TextBlock',
                text = 'Você está banido do servidor.',
                size = 'Medium',
                horizontalAlignment = 'Center',
                spacing = 'Medium',
                wrap = true,
            },
            {
                type = 'FactSet',
                spacing = 'Medium',
                facts = {
                    { title = 'Seu ID:', value = tostring(userId) },
                    { title = 'Motivo:', value = reason },
                    { title = 'Expira:', value = formatBanExpiry(ban_row.expires_at) },
                },
            },
            {
                type = 'TextBlock',
                text = ('Entre em nosso **%s** caso tenha dúvidas.'):format(DISCORD_LABEL),
                horizontalAlignment = 'Center',
                spacing = 'Medium',
                wrap = true,
            },
        },
        actions = {
            { type = 'Action.OpenUrl', title = 'Entrar no Discord', url = DISCORD_URL },
        },
    }
    return json.encode(card)
end

AddEventHandler('playerConnecting', function(playerName, _, deferrals)
    local source = source
    deferrals.defer()
    Wait(0)

    deferrals.update('[kinGG] Verificando informações...')

    local ok, userId = pcall(Core.getUserId, source)
    if not ok then
        log('error', 'Error getting user id: ' .. userId)
        deferrals.done('Erro ao verificar informações')
        return
    end
    if not userId then
        log('info', ('New player created: %s'):format(source))
        deferrals.update('[kinGG] Parece que você é novo por aqui...')
        userId = Core.Insert('INSERT INTO `users`(name) VALUES (?)', { playerName:sub(1, 150) })
        if type(userId) ~= 'number' then
            log('error', 'Error creating user: ' .. json.encode(userId))
            deferrals.done('Erro ao criar usuário')
            return
        end
        log('info', ('User created: %s'):format(userId))
        local identifiers = GetPlayerIdentifiers(source)
        for i = 1, #identifiers do
            if identifiers[i]:sub(1,3) == 'ip:' then
                goto continue
            end
            local identifier = identifiers[i]
            Core.Insert('INSERT INTO `identifiers`(user_id, identifier) VALUES (?, ?)', { userId, identifier })
            ::continue::
        end
    end

    local ban_row = Core.single('SELECT * FROM `bans` WHERE `user_id` = ? AND NOW() < `expires_at`', { userId })
    if ban_row then
        log('info', ('Player %s is banned by %s for %s'):format(userId, ban_row.staff_id, ban_row.reason))
        deferrals.presentCard(buildBanCard(userId, ban_row))
        return
    end

    local allow_row = Core.single('SELECT `allowed` FROM `users` WHERE `id` = ?', { userId })
    local allowedVal = allow_row and allow_row.allowed
    if not (allowedVal == true or allowedVal == 1 or allowedVal == '1') then
        log('info', ('^3[whitelist]^7 ID %s (%s) sem autorizacao (allowed != 1), bloqueado'):format(userId, playerName))
        deferrals.done(('[kinGG] Acesso restrito a IDs autorizados.\n\nSeu ID e: %d.'):format(userId))
        return
    end

    Core.users_src[tonumber(source)] = userId
    Core.src_users[userId] = tonumber(source)
    local user_info = Core.single('SELECT * FROM `users` WHERE `id` = ?', { userId })
    if user_info then
        Core:processUserInfo(user_info)
    end
    deferrals.done()
end)

AddEventHandler('playerJoining', function(old_src)
    local new_src = source
    SetPlayerRoutingBucket(new_src, new_src)
    log('info', ('Player %s joined the server (old: %s)'):format(new_src, old_src))
    old_src = tonumber(old_src)
    new_src = tonumber(new_src)
    assert(Core.users_src[old_src], 'Player not found')

    Core.users_src[new_src] = Core.users_src[old_src]
    Core.src_users[Core.users_src[old_src]] = old_src
    Core.users_src[old_src] = nil
    Core.src_users[Core.users_src[new_src]] = new_src

    TriggerEvent('kingg:playerJoining', Core.users_src[new_src], new_src)
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    local userId = Core.getUserId(src)
    if not userId then
        return
    end
    Core.users_src[tonumber(src)] = nil
    Core.src_users[userId] = nil
    Core.users_info[userId] = nil
    log('info', ('Player dropped (userId=%s, reason=%s)'):format(src, userId, reason))
    TriggerEvent('kingg:playerDropped', userId, src)
end)

Core.log = log
---@param functions string[]
---@return Core
function Core:buildExports(functions)
    for _, func in pairs(functions) do
        self.exports[func] = function(...)
            return Core[func](...)
        end
    end
    return self
end



CreateThread(function()
    while not Core.log do
        Core.log = log
        Wait(100)
    end
    Core:buildExports({
        'getUserId',
        'getUserSource',
        'getUserName',
        'getUserInfo',
        'updateUserInfo',
        'reloadUserInfo',
        'hasRole',
        'getUserFriends',
        'acceptFriendRequest',
        'removeFriend',
        'sendFriendRequest',
        'getPendingFriendRequests',
        'getUserByName',
        'declineFriendRequest',
        'log',
        'addPlayerToQueue',
        'removePlayerFromQueue',
        'getQueueSize',
        'getQueuePlayers',
        'clearQueue',
        'buildSquadGroups',
        'resolveMatchKeys',
        'allocateBucket',
        'releaseBucket',
        'getNextSafeZone',
        'getNextFinalSafeZone',
        -- 'getPlayerName',
        -- 'getPlayerIdentifier',
        -- 'getUserClan',
    })

    -- TEMPORARIO ( PARA NAO PRECISAR FICAR RELOGANDO PARA ENSURAR )
    for _, src in pairs(GetPlayers()) do
        src = tonumber(src)
        if not src or not DoesPlayerExist(src) then goto continue end

        local ok, userId = pcall(Core.getUserId, src)
        if not ok or not userId then
            log('warn', ('(rehydrate) skip src=%s reason=%s'):format(src, ok and 'no userId' or tostring(userId)))
            goto continue
        end

        Core.users_src[src] = userId
        Core.src_users[userId] = src

        local user_info = Core.single('SELECT * FROM `users` WHERE `id` = ?', { userId })
        if user_info then
            Core:processUserInfo(user_info)
        end

        TriggerEvent('kingg:playerJoining', userId, src)
        log('info', ('(rehydrate) player src=%s userId=%s'):format(src, userId))

        ::continue::
    end
end)


exports('GetCore', function()
    if not next(Core.exports) then
        local startTime = GetGameTimer()
        while not next(Core.exports) do
            Wait(100)
        end
        local endTime = GetGameTimer()
        print(('^2Core exports built in %.2f ms^7'):format(endTime - startTime))
    end
    return Core.exports
end)