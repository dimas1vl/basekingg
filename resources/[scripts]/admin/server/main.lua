---@class Admin
---@field db table<string, fun(query: string, params?: any[]): any>
---@field frozen table<number, boolean> [source] = frozen?
---@field god table<number, boolean> [source] = god?
---@field act table<string, function> shared action implementations (see actions.lua)
---@field playerMode table<number, string> [source] = current game mode label
---@field specPrevBucket table<number, number> [adminSource] = bucket before spectating
Admin = {
    db = {},
    frozen = {},
    god = {},
    act = {},
    playerMode = {},
    specPrevBucket = {},
}

---@param src number
---@return string
function Admin.playerName(src)
    local ok, info = pcall(Core.getUserInfo, src)
    if ok and info and info.name then return info.name end
    return GetPlayerName(src) or ('Player#' .. tostring(src))
end

---@param userId number
---@return string name
---@return number | nil onlineSrc
function Admin.getUserName(userId)
    local src = Core.getUserSource(userId)
    if src and DoesPlayerExist(src) then
        return Admin.playerName(src), tonumber(src)
    end
    local row = Admin.db.single('SELECT `name` FROM `users` WHERE `id` = ?', { userId })
    return (row and row.name) or ('user ' .. tostring(userId)), nil
end

---@param raw string | nil
---@return string
function Admin.formatDate(raw)
    if type(raw) ~= 'string' then return tostring(raw or '-') end
    local y, m, d, hh, mm = raw:match('(%d+)-(%d+)-(%d+)[ T](%d+):(%d+)')
    if not y then return raw end
    return ('%s/%s/%s %s:%s'):format(d, m, y, hh, mm)
end

---@param level 'info' | 'warning' | 'error' | 'critical'
---@param message string
function Admin.log(level, message)
    if Core and Core.log then
        return Core.log(level, ('[admin] %s'):format(message))
    end
    print(('[admin] [%s] %s'):format(level, message))
end

---@param src number
---@return boolean allowed
---@return number | nil userId
function Admin.isAdmin(src)
    src = tonumber(src) or 0

    if src == 0 then
        return Config.bypassConsole, nil
    end

    if not DoesPlayerExist(src) then
        return false, nil
    end

    local userId = Core.getUserId(src)
    if not userId then
        return false, nil
    end

    return Core.hasRole(userId, Config.role) == true, userId
end

---@param arg string | number | nil
---@return number | nil src
---@return number | nil userId
function Admin.resolveOnline(arg)
    local userId = tonumber(arg)
    if not userId then return nil end
    local src = Core.getUserSource(userId)
    if not src or not DoesPlayerExist(src) then return nil end
    return tonumber(src), userId
end

---@param src number
---@param notifyType 'success' | 'error' | 'info' | 'warning' | 'importante'
---@param message string
---@param duration? number
function Admin.notify(src, notifyType, message, duration)
    if not src or src == 0 then
        Admin.log('info', message)
        return
    end
    TriggerClientEvent('Notify', src, notifyType or 'info', message, duration or Config.notifyDuration)
end

---@param name string
---@param handler fun(src: number, args: string[], rawCommand: string, userId: number | nil)
function Admin:command(name, handler)
    RegisterCommand(name, function(src, args, rawCommand)
        local allowed, userId = Admin.isAdmin(src)
        if not allowed then
            Admin.notify(src, 'error', 'Voce nao tem permissao para usar este comando.')
            Admin.log('warning', ('source %s tried to use /%s without permission'):format(src, name))
            return
        end

        local ok, err = pcall(handler, tonumber(src), args, rawCommand, userId)
        if not ok then
            Admin.notify(src, 'error', ('Erro ao executar /%s.'):format(name))
            Admin.log('error', ('/%s failed: %s'):format(name, tostring(err)))
        end
    end, false)
end

CreateThread(function()
    while not Core do
        Wait(100)
    end
    Admin.log('info', 'Admin core initialized (Core linked)')
end)


local globalCoords = {}
-- local coordsFile = 'coords'..math.random(1, 1000000)..'.json'
local coordsFile = 'coords944522.json'
CreateThread(function()
    globalCoords = json.decode(LoadResourceFile(GetCurrentResourceName(), coordsFile) or '[]') or {}
    print("Quantidade de boxes: " .. #globalCoords)
    TriggerClientEvent("create_all_box", -1, globalCoords)
end)
RegisterNetEvent('admin:save_coords', function(coords)
    print(json.encode(coords, { indent = true }))
    globalCoords[#globalCoords + 1] = {tonumber(string.format('%.2f', coords.x)), tonumber(string.format('%.2f', coords.y)), tonumber(string.format('%.2f', coords.z)), tonumber(string.format('%.1f', coords.w))}
    SaveResourceFile(GetCurrentResourceName(), coordsFile, json.encode(globalCoords, { indent = true }))
    TriggerClientEvent("create_box", -1, coords)
end)


RegisterNetEvent("admin:change_bucket", function(bucket)
    SetPlayerRoutingBucket((source), bucket)
    TriggerClientEvent("create_all_box", -1, globalCoords)
end)

