while not Core do Wait(100) end

---@class InventarioHooksModule
InventarioHooks = {}

local function log(level, msg)
    if Core and Core.log then return Core.log(level, ('[inventario:hooks] %s'):format(msg)) end
    print(('[inventario:hooks] [%s] %s'):format(level, msg))
end

---Wire connect/drop lifecycle. Hydrates `equippedCache[userId]` on join and
---clears it on drop after a short drain window so any in-flight writes from
---equip/unequip can land before we forget the player.
---@param Inventario table the main API object (used to access caches)
function InventarioHooks:wire(Inventario)
    -- kingg fires 'kingg:playerJoining' after userId is resolved and processed.
    AddEventHandler('kingg:playerJoining', function(userId, src)
        if not userId then return end
        local ok, equipped = pcall(InventarioInventory.loadEquipped, InventarioInventory, userId)
        if not ok then
            log('error', ('hydrate equipped failed for user=%s: %s'):format(userId, tostring(equipped)))
            Inventario.equippedCache[userId] = {}
            return
        end
        Inventario.equippedCache[userId] = equipped or {}
        local total = 0
        for _, slots in pairs(equipped or {}) do
            for _ in pairs(slots) do total = total + 1 end
        end
        log('info', ('hydrated equipped state for user=%s (slots=%d)'):format(userId, total))
    end)

    AddEventHandler('kingg:playerDropped', function(userId)
        if not userId then return end
        -- Short drain window so any pending equip/buy writes complete.
        CreateThread(function()
            Wait(1000)
            Inventario.equippedCache[userId] = nil
        end)
    end)

    -- Client handshake: when ready, send the full equipped payload.
    RegisterNetEvent(Events.READY, function(_payload)
        local src = source
        local userId = Core.getUserId(src)
        if not userId then return end

        local equipped = Inventario.equippedCache[userId]
        if not equipped then
            -- Fallback: hydrate on-demand if hook missed (e.g. resource restart).
            equipped = InventarioInventory:loadEquipped(userId)
            Inventario.equippedCache[userId] = equipped
        end

        -- Resolve item ids to full item objects for the applier.
        local resolved = {}
        for category, slots in pairs(equipped) do
            resolved[category] = {}
            for slot, itemId in pairs(slots) do
                local item = Inventario.catalog[itemId]
                if item then
                    resolved[category][slot] = item
                end
            end
        end

        TriggerClientEvent(Events.APPLY, src, { equipped = resolved })
    end)
end
