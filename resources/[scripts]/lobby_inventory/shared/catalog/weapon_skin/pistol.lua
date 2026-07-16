-- Catalog: weapon_skin / pistol
-- Skin only mutates tint and component attachments of the SAME weapon_hash
-- (no MK2 swap per v1 rules).

_InventarioCatalogRegistry:add({
    {
        id          = 'pistol_skin_default_01',
        name        = 'Pistola Padrao',
        category    = 'weapon_skin',
        subcategory = 'pistol',
        rarity      = 'common',
        price       = nil,
        purchasable = false,
        image       = 'images/inventario/pistol_skin_default_01.png',
        metadata    = {
            weapon_hash = 'WEAPON_PISTOL',
            tint        = 0,
            components  = {},
        },
    },
    {
        id          = 'pistol_skin_green_01',
        name        = 'Pistola Verde',
        category    = 'weapon_skin',
        subcategory = 'pistol',
        rarity      = 'rare',
        price       = 150,
        purchasable = true,
        image       = 'images/inventario/pistol_skin_green_01.png',
        metadata    = {
            weapon_hash = 'WEAPON_PISTOL',
            tint        = 1,
            components  = {},
        },
    },
    {
        id          = 'pistol_skin_gold_01',
        name        = 'Pistola Dourada',
        category    = 'weapon_skin',
        subcategory = 'pistol',
        rarity      = 'epic',
        price       = 400,
        purchasable = true,
        image       = 'images/inventario/pistol_skin_gold_01.png',
        metadata    = {
            weapon_hash = 'WEAPON_PISTOL',
            tint        = 2,
            components  = {
                'COMPONENT_PISTOL_CLIP_02',
            },
        },
    },
    {
        id          = 'pistol_skin_platinum_01',
        name        = 'Pistola Platinada',
        category    = 'weapon_skin',
        subcategory = 'pistol',
        rarity      = 'legendary',
        price       = 1000,
        purchasable = true,
        image       = 'images/inventario/pistol_skin_platinum_01.png',
        metadata    = {
            weapon_hash = 'WEAPON_PISTOL',
            tint        = 5,
            components  = {
                'COMPONENT_PISTOL_CLIP_02',
                'COMPONENT_AT_PI_FLSH',
            },
        },
    },
    {
        id          = 'pistol_skin_neon_01',
        name        = 'Pistola Neon',
        category    = 'weapon_skin',
        subcategory = 'pistol',
        rarity      = 'mythic',
        price       = 2200,
        purchasable = true,
        image       = 'images/inventario/pistol_skin_neon_01.png',
        metadata    = {
            weapon_hash = 'WEAPON_PISTOL',
            tint        = 7,
            components  = {
                'COMPONENT_PISTOL_CLIP_02',
                'COMPONENT_AT_PI_FLSH',
                'COMPONENT_AT_PI_SUPP_02',
            },
        },
    },
})
