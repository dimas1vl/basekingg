-- sync.lua
-- Net events from server + lifecycle hooks. Owns the handshake (inventario:ready).

local function safeApplyOne(category, item)
    local applier = Inventario.appliers[category]
    if not applier or not item then return end
    Inventario:applyOne(category, item, { ped = PlayerPedId() })
end

local function resetSlot(category, item)
    if not item then return end
    if category == 'clothes' and Inventario_resetClothes then
        Inventario_resetClothes(PlayerPedId(), item)
    elseif category == 'weapon_skin' and Inventario_resetWeaponSkin then
        Inventario_resetWeaponSkin(PlayerPedId(), item)
    elseif category == 'parachute' and Inventario_resetParachute then
        Inventario_resetParachute()
    elseif category == 'vehicle_skin' then
        -- v1: vehicle skin is tied to a specific vehicle entity; nothing to
        -- "unapply" on the player. The stateBag will simply not be set on the
        -- next vehicle entry.
    end
end

-- Server pushes full equipped state (initial join, after batch equip/unequip).
RegisterNetEvent('inventario:apply', function(payload)
    payload = payload or {}
    Inventario.equipped = payload.equipped or {}
    Inventario.ready = true
    Inventario:runPhase('spawn', { ped = PlayerPedId() })
end)

-- Server pushes a single item add (e.g. admin grant + autoEquip).
RegisterNetEvent('inventario:applyOne', function(p)
    if not p or not p.category or p.slot == nil then return end
    Inventario.equipped[p.category] = Inventario.equipped[p.category] or {}
    Inventario.equipped[p.category][p.slot] = p.item
    safeApplyOne(p.category, p.item)
end)

-- Server pushes a single item removal.
RegisterNetEvent('inventario:unapplyOne', function(p)
    if not p or not p.category or p.slot == nil then return end
    local slots = Inventario.equipped[p.category]
    if not slots then return end
    local item = slots[p.slot]
    slots[p.slot] = nil
    if next(slots) == nil then
        Inventario.equipped[p.category] = nil
    end
    if item then
        resetSlot(p.category, item)
    end
end)

-- Handshake: tell server we're ready to receive inventario state.
-- Fires once after the resource boots; can be re-emitted by gamemodes via 'inventario:requestReady'.
local function sendReady(phase)
    TriggerServerEvent('inventario:ready', { phase = phase or 'spawn' })
end

CreateThread(function()
    -- Small initial delay so lobby/kingg has time to finish appearance apply.
    Wait(500)
    sendReady('spawn')
end)

RegisterNetEvent('inventario:requestReady', function(phase)
    sendReady(phase or 'spawn')
end)

-- Reapply everything on respawn (death, gamemode change, etc). If we never
-- received initial state, redo the handshake instead.
RegisterNetEvent('kingg:player:spawned', function()
    if Inventario.ready then
        Inventario:runPhase('spawn', { ped = PlayerPedId() })
    else
        sendReady('spawn')
    end
end)
