while not Core do
    Wait(100)
end

local ONLINE_ACTIONS = {
    tpto = true,
    tptome = true,
    spec = true,
    freeze = true,
    god = true,
    setarlobby = true,
    kick = true,
}

---Build the online players list for the panel.
---@return table[]
local function buildPlayers()
    local list = {}
    for _, ps in ipairs(GetPlayers()) do
        local src = tonumber(ps)
        if src and DoesPlayerExist(src) then
            local okId, userId = pcall(Core.getUserId, src)
            local info = Core.getUserInfo(src)
            if okId and userId then
                list[#list + 1] = {
                    src = src,
                    userId = userId,
                    name = (info and info.name) or GetPlayerName(src) or ('Player#' .. src),
                    role = (info and info.role) or 'user',
                    xp = (info and info.xp) or 0,
                    gems = (info and info.gems) or 0,
                    premium = (info and info.premium) or 0,
                    mode = Admin.getPlayerMode(src),
                }
            end
        end
    end
    table.sort(list, function(a, b) return a.userId < b.userId end)
    return list
end

---Resolve the Inventario export, returning nil if the resource is unavailable.
---@return table | nil
local function getInventarioApi()
    local ok, api = pcall(function() return exports['lobby_inventory']:GetInventario() end)
    if not ok or not api then return nil end
    return api
end

RPC:bind({
    getPlayers = function()
        local src = source
        if not Admin.isAdmin(src) then return {} end
        local ok, result = pcall(buildPlayers)
        if not ok then
            Admin.log('error', ('getPlayers failed: %s'):format(tostring(result)))
            return {}
        end
        return result
    end,
    getBans = function()
        local src = source
        if not Admin.isAdmin(src) then return {} end
        local ok, result = pcall(function() return Admin.bans:list() end)
        if not ok then
            Admin.log('error', ('getBans failed: %s'):format(tostring(result)))
            return {}
        end
        return result
    end,
    getInventarioCatalog = function(filter)
        local src = source
        if not Admin.isAdmin(src) then return {} end
        local api = getInventarioApi()
        if not api then return {} end
        filter = type(filter) == 'table' and filter or {}
        local ok, result = pcall(function()
            return api:getCatalog({
                category = filter.category,
                rarity = filter.rarity,
                purchasable = filter.purchasable,
                search = filter.search,
            })
        end)
        if not ok then
            Admin.log('error', ('getInventarioCatalog failed: %s'):format(tostring(result)))
            return {}
        end
        return result or {}
    end,
    getPlayerInventario = function(targetId)
        local src = source
        if not Admin.isAdmin(src) then return { items = {}, equipped = {} } end
        local userId = tonumber(targetId)
        if not userId then return { items = {}, equipped = {} } end
        local api = getInventarioApi()
        if not api then return { items = {}, equipped = {} } end
        local ok, result = pcall(function() return api:getInventory(userId) end)
        if not ok then
            Admin.log('error', ('getPlayerInventario failed: %s'):format(tostring(result)))
            return { items = {}, equipped = {} }
        end
        return result or { items = {}, equipped = {} }
    end,
})

RegisterNetEvent('net.admin:panelAction', function(data)
    local src = source
    local allowed = Admin.isAdmin(src)
    if not allowed then
        return Admin.notify(src, 'error', 'Voce nao tem permissao.')
    end
    if type(data) ~= 'table' or not data.action then return end

    local action = data.action
    local targetId = tonumber(data.targetId)
    if not targetId then
        return Admin.notify(src, 'error', 'Alvo invalido.')
    end

    if ONLINE_ACTIONS[action] then
        local targetSrc = Core.getUserSource(targetId)
        if not targetSrc or not DoesPlayerExist(targetSrc) then
            return Admin.notify(src, 'error', 'Jogador nao esta online.')
        end
        targetSrc = tonumber(targetSrc)

        if action == 'kick' then
            Admin.act.kick(src, targetSrc, data.reason)
        elseif action == 'spec' then
            Admin.act.spectate(src, targetSrc)
        else
            Admin.act[action](src, targetSrc)
        end
        return
    end

    if action == 'unban' then
        Admin.act.unban(src, targetId)
    elseif action == 'setRole' then
        Admin.act.setRole(src, targetId, data.role)
    elseif action == 'setStat' then
        Admin.act.setStat(src, targetId, data.field, data.value)
    elseif action == 'grantInventario' then
        Admin.act.grantInventario(src, targetId, data.itemId)
    elseif action == 'revokeInventario' then
        Admin.act.revokeInventario(src, targetId, data.itemId)
    else
        Admin.notify(src, 'error', 'Acao desconhecida.')
    end
end)

Admin:command('admin', function(src)
    TriggerClientEvent('admin:panel:open', src)
end)

Admin.log('info', 'Admin panel module loaded')
