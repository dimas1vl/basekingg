-- apply_parachute.lua
-- Parachute tints. Equipped 'parachute' uses a single conventional slot '_'.

local PARACHUTE_HASH = GetHashKey('GADGET_PARACHUTE')

---@return table | nil
local function getEquippedParachute()
    local equipped = Inventario.equipped.parachute
    if not equipped then return nil end
    return equipped._ or equipped[next(equipped) or false]
end

---@param item table
local function applyParachuteTints(item)
    if not item or not item.metadata then return end
    local m = item.metadata
    local playerId = PlayerId()

    SetPlayerParachuteTintIndex(playerId, tonumber(m.tint) or 0)
    SetPlayerReserveParachuteTintIndex(playerId, tonumber(m.reserve_tint) or 0)
    SetPlayerParachutePackTintIndex(playerId, tonumber(m.pack_tint) or 0)
end

Inventario:register('parachute', { spawn = true }, function(_, item)
    applyParachuteTints(item)
end)

-- Pre-give hook fires BEFORE GiveWeaponToPed(GADGET_PARACHUTE) so the tint sticks.
RegisterNetEvent('kingg:player:preParachuteGive', function()
    local item = getEquippedParachute()
    if not item then return end
    applyParachuteTints(item)
end)

-- Safety net: if the parachute was given after the pre-give hook, the
-- weaponGiven event also lets us reapply tints.
RegisterNetEvent('kingg:player:weaponGiven', function(weaponHash)
    if not weaponHash then return end
    local hash = type(weaponHash) == 'number' and weaponHash or GetHashKey(weaponHash)
    if hash ~= PARACHUTE_HASH then return end
    local item = getEquippedParachute()
    if not item then return end
    applyParachuteTints(item)
end)

-- Reset helper used by sync.lua on unapplyOne.
function Inventario_resetParachute()
    local playerId = PlayerId()
    SetPlayerParachuteTintIndex(playerId, 0)
    SetPlayerReserveParachuteTintIndex(playerId, 0)
    SetPlayerParachutePackTintIndex(playerId, 0)
end
