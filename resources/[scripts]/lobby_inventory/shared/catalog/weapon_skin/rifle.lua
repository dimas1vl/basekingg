-- Catalog: weapon_skin / rifle

_InventarioCatalogRegistry:add({
    {
        id          = 'rifle_skin_default_01',
        name        = 'Rifle Padrao',
        category    = 'weapon_skin',
        subcategory = 'rifle',
        rarity      = 'common',
        price       = nil,
        purchasable = false,
        image       = 'images/inventario/rifle_skin_default_01.png',
        metadata    = {
            weapon_hash = 'WEAPON_ASSAULTRIFLE',
            tint        = 0,
            components  = {},
        },
    },
    {
        id          = 'rifle_skin_camo_01',
        name        = 'Rifle Camuflado',
        category    = 'weapon_skin',
        subcategory = 'rifle',
        rarity      = 'rare',
        price       = 200,
        purchasable = true,
        image       = 'images/inventario/rifle_skin_camo_01.png',
        metadata    = {
            weapon_hash = 'WEAPON_ASSAULTRIFLE',
            tint        = 1,
            components  = {},
        },
    },
    {
        id          = 'rifle_skin_orange_01',
        name        = 'Rifle Laranja',
        category    = 'weapon_skin',
        subcategory = 'rifle',
        rarity      = 'epic',
        price       = 500,
        purchasable = true,
        image       = 'images/inventario/rifle_skin_orange_01.png',
        metadata    = {
            weapon_hash = 'WEAPON_ASSAULTRIFLE',
            tint        = 3,
            components  = {
                'COMPONENT_ASSAULTRIFLE_CLIP_02',
            },
        },
    },
    {
        id          = 'rifle_skin_gold_01',
        name        = 'Rifle Dourado',
        category    = 'weapon_skin',
        subcategory = 'rifle',
        rarity      = 'legendary',
        price       = 1200,
        purchasable = true,
        image       = 'images/inventario/rifle_skin_gold_01.png',
        metadata    = {
            weapon_hash = 'WEAPON_ASSAULTRIFLE',
            tint        = 5,
            components  = {
                'COMPONENT_ASSAULTRIFLE_CLIP_02',
                'COMPONENT_AT_AR_FLSH',
            },
        },
    },
    {
        id          = 'rifle_skin_neon_01',
        name        = 'Rifle Neon',
        category    = 'weapon_skin',
        subcategory = 'rifle',
        rarity      = 'mythic',
        price       = 2500,
        purchasable = true,
        image       = 'images/inventario/rifle_skin_neon_01.png',
        metadata    = {
            weapon_hash = 'WEAPON_ASSAULTRIFLE',
            tint        = 7,
            components  = {
                'COMPONENT_ASSAULTRIFLE_CLIP_02',
                'COMPONENT_AT_AR_FLSH',
                'COMPONENT_AT_AR_SUPP_02',
            },
        },
    },
})
