---@class InventarioEvents
---@field READY string Client -> server handshake when player is ready to receive inventario
---@field APPLY string Server -> client: apply full equipped state
---@field APPLY_ONE string Server -> client: apply a single item update
---@field UNAPPLY_ONE string Server -> client: unapply a single slot
---@field PLAYER_SPAWNED string Generic gamemode -> inventario (client local)
---@field PLAYER_WEAPON_GIVEN string Generic gamemode -> inventario (client local)
---@field PLAYER_VEHICLE_ENTERED string Generic gamemode -> inventario (client local)
---@field PLAYER_PRE_PARACHUTE_GIVE string Generic gamemode -> inventario (client local)
Events = {
    -- Net (client <-> server)
    READY        = 'inventario:ready',
    APPLY        = 'inventario:apply',
    APPLY_ONE    = 'inventario:applyOne',
    UNAPPLY_ONE  = 'inventario:unapplyOne',

    -- Client-local generic gameplay events (emitted by kingg/DM/BR)
    PLAYER_SPAWNED            = 'kingg:player:spawned',
    PLAYER_WEAPON_GIVEN       = 'kingg:player:weaponGiven',
    PLAYER_VEHICLE_ENTERED    = 'kingg:player:vehicleEntered',
    PLAYER_PRE_PARACHUTE_GIVE = 'kingg:player:preParachuteGive',
}
