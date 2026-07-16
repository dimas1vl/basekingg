---@class InventarioConfig
---@field role string Role required for admin/inventario management
---@field maxEquippedPerCategory number Cap of equipped slots per category
---@field validCategories string[] Categories accepted by the catalog/loader
---@field validRarities string[] Allowed rarities for catalog items
---@field validSources string[] Allowed sources for grant operations
---@field navbar { label: string, path: string, enabled: boolean } NUI navbar entry
---@field currency string users column used as in-game currency
Config = {
    role = 'admin',

    maxEquippedPerCategory = 64,

    validCategories = {
        'clothes',
        'weapon_skin',
        'vehicle_skin',
        'parachute',
    },

    validRarities = {
        'common',
        'rare',
        'epic',
        'legendary',
        'mythic',
    },

    validSources = {
        'shop',
        'lootbox',
        'event',
        'reward',
        'admin',
        'migration',
        'system',
    },

    navbar = {
        label = 'INVENTARIO',
        path = '/inventory',
        enabled = true,
    },

    currency = 'gems',
}

-- Component & prop slot maps used by clothes catalog and applier.
-- Exposed to the lobby resource via exports('GetClothesMaps', ...) (client side).
COMPONENT_MAP = {
    face          = 0,
    mask          = 1,
    hair          = 2,
    torsos        = 3,
    legs          = 4,
    bags          = 5,
    shoes         = 6,
    accessories   = 7,
    undershirts   = 8,
    body_armor    = 9,
    decals        = 10,
    tops          = 11,
}

PROP_MAP = {
    hats     = 0,
    glasses  = 1,
    ears     = 2,
    watches  = 6,
    bracelet = 7,
}
