-- NUI bridge. The lobby NUI calls https://lobby_inventory/<event>; these callbacks
-- delegate to the awaiting RPC client and respond with the server payload.
--
-- The cb(...) MUST be called even on failure or the React fetch hangs.

local function safeRpc(method, ...)
    local args = { ... }
    local ok, result = pcall(function()
        return RPC[method](table.unpack(args))
    end)
    if not ok then
        print(('[inventario] RPC %s failed: %s'):format(method, tostring(result)))
        return nil
    end
    return result
end

RegisterNUICallback('getMyInventory', function(_, cb)
    local data = safeRpc('getMyInventory')
    cb(data or { items = {}, equipped = {} })
end)

RegisterNUICallback('getMyEquipped', function(_, cb)
    local data = safeRpc('getMyEquipped')
    cb(data or {})
end)

RegisterNUICallback('getCatalog', function(data, cb)
    local filter = (type(data) == 'table') and data or {}
    local list = safeRpc('getCatalog', filter)
    cb(list or {})
end)

RegisterNUICallback('equipItems', function(data, cb)
    local itemIds = (type(data) == 'table' and type(data.itemIds) == 'table') and data.itemIds or {}
    local res = safeRpc('equipItems', itemIds)
    cb(res or { ok = false, err = 'rpc_failed' })
end)

RegisterNUICallback('unequipSlots', function(data, cb)
    local slots = (type(data) == 'table' and type(data.slots) == 'table') and data.slots or {}
    local res = safeRpc('unequipSlots', slots)
    cb(res or { ok = false, err = 'rpc_failed' })
end)

RegisterNUICallback('buyItem', function(data, cb)
    local itemId = (type(data) == 'table') and data.itemId or nil
    if not itemId or itemId == '' then
        return cb({ ok = false, err = 'missing_item_id' })
    end
    local res = safeRpc('buyItem', itemId)
    cb(res or { ok = false, err = 'rpc_failed' })
end)
