-- apply_weapon_skin.lua
-- Self-only weapon skin applier (v1: no network sync to other clients).
-- Equipped slot key = weapon_hash (string form, e.g. "WEAPON_PISTOL").

---@param ped number
---@param weaponHash number
local function applyWeaponSkin(ped, weaponHash)
    if not ped or ped == 0 or not weaponHash or weaponHash == 0 then return end
    if not HasPedGotWeapon(ped, weaponHash, false) then return end

    local equipped = Inventario.equipped.weapon_skin
    if not equipped then return end

    -- Find equipped item matching this weapon hash.
    local item
    for slotKey, it in pairs(equipped) do
        if it and it.metadata then
            local mh = it.metadata.weapon_hash
            local slotHash
            if type(slotKey) == 'number' then
                slotHash = slotKey
            else
                slotHash = tonumber(slotKey) or GetHashKey(slotKey)
            end
            local metaHash = mh and (type(mh) == 'number' and mh or GetHashKey(mh)) or nil
            if slotHash == weaponHash or metaHash == weaponHash then
                item = it
                break
            end
        end
    end
    if not item then return end

    local m = item.metadata
    local tint = tonumber(m.tint) or 0
    SetPedWeaponTintIndex(ped, weaponHash, tint)

    if type(m.components) == 'table' then
        for _, comp in ipairs(m.components) do
            local compHash = type(comp) == 'number' and comp or GetHashKey(comp)
            if compHash and compHash ~= 0 then
                GiveWeaponComponentToPed(ped, weaponHash, compHash)
            end
        end
    end
end

Inventario:register('weapon_skin', { spawn = true }, function(ctx, item)
    local ped = ctx and ctx.ped or PlayerPedId()
    if not ped or ped == 0 or not item or not item.metadata then return end
    local wh = item.metadata.weapon_hash
    if not wh then return end
    local hash = type(wh) == 'number' and wh or GetHashKey(wh)
    applyWeaponSkin(ped, hash)
end)

-- Reapply when kingg/DM/BR notifies us a weapon was given.
RegisterNetEvent('kingg:player:weaponGiven', function(weaponHash)
    if not weaponHash then return end
    local hash = type(weaponHash) == 'number' and weaponHash or GetHashKey(weaponHash)
    applyWeaponSkin(PlayerPedId(), hash)
end)

-- Reapply all skins after respawn (weapon entities are recreated).
RegisterNetEvent('kingg:player:spawned', function()
    local ped = PlayerPedId()
    local equipped = Inventario.equipped.weapon_skin or {}
    for slotKey, item in pairs(equipped) do
        local hash
        if type(slotKey) == 'number' then
            hash = slotKey
        else
            hash = tonumber(slotKey) or GetHashKey(slotKey)
        end
        if (not hash or hash == 0) and item and item.metadata and item.metadata.weapon_hash then
            local mh = item.metadata.weapon_hash
            hash = type(mh) == 'number' and mh or GetHashKey(mh)
        end
        if hash and hash ~= 0 then
            applyWeaponSkin(ped, hash)
        end
    end
end)

-- Lightweight detection of weapon swap (so newly-selected weapon gets the skin
-- in case events were missed). 250ms tick is cheap.
CreateThread(function()
    local lastWeapon = 0
    while true do
        Wait(250)
        local ped = PlayerPedId()
        if ped and ped ~= 0 then
            local ok, current = GetCurrentPedWeapon(ped, true)
            if ok and current and current ~= 0 and current ~= lastWeapon then
                lastWeapon = current
                local equipped = Inventario.equipped.weapon_skin
                if equipped and next(equipped) ~= nil then
                    applyWeaponSkin(ped, current)
                end
            end
        end
    end
end)

-- Exposed for sync.lua so unapplyOne can reset tint to 0.
---@param ped number
---@param item table
function Inventario_resetWeaponSkin(ped, item)
    if not ped or ped == 0 or not item or not item.metadata then return end
    local wh = item.metadata.weapon_hash
    if not wh then return end
    local hash = type(wh) == 'number' and wh or GetHashKey(wh)
    if HasPedGotWeapon(ped, hash, false) then
        SetPedWeaponTintIndex(ped, hash, 0)
        if type(item.metadata.components) == 'table' then
            for _, comp in ipairs(item.metadata.components) do
                local compHash = type(comp) == 'number' and comp or GetHashKey(comp)
                if compHash and compHash ~= 0 then
                    RemoveWeaponComponentFromPed(ped, hash, compHash)
                end
            end
        end
    end
end
