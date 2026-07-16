-- /admin panel client: opens the focused NUI and bridges its data/actions to the
-- server (RPC for reads, a net event for action buttons).

RegisterNetEvent('admin:panel:open', function()
    Admin:openNui('openPanel')
end)

-- Online players list (RPC awaits the server response).
RegisterNUICallback('getPlayers', function(_, cb)
    local players = RPC.getPlayers()
    cb(players or {})
end)

-- Banned players list.
RegisterNUICallback('getBans', function(_, cb)
    local bans = RPC.getBans()
    cb(bans or {})
end)

-- Per-player action buttons (tp, pull, spec, freeze, god, lobby, kick, role, stats, unban).
RegisterNUICallback('panelAction', function(data, cb)
    if type(data) == 'table' and data.action then
        TriggerServerEvent('net.admin:panelAction', data)
    end
    cb({ ok = true })
end)

-- Inventario catalog (admin tab). Filter payload comes from the React side.
RegisterNUICallback('getInventarioCatalog', function(data, cb)
    local filter = (type(data) == 'table') and data or {}
    local ok, list = pcall(function() return RPC.getInventarioCatalog(filter) end)
    cb((ok and list) or {})
end)

-- Player inventory (Skins modal on PlayerCard). Body is { targetId }.
RegisterNUICallback('getPlayerInventario', function(data, cb)
    local targetId = (type(data) == 'table') and tonumber(data.targetId) or tonumber(data)
    if not targetId then
        return cb({ items = {}, equipped = {} })
    end
    local ok, inv = pcall(function() return RPC.getPlayerInventario(targetId) end)
    cb((ok and inv) or { items = {}, equipped = {} })
end)
