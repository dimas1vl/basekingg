---@class ItemDef
---@field max number
---@field name string
---@field slotType string | nil
---@field type string
---@field pickup string
---@field ammo string | nil
---@field useInVehicle boolean | nil

---@type table<string, ItemDef>
GItems = {
    ARMOUR_STANDARD = {
        max = 5,
        name = 'Colete',
        slotType = 'Quinary',
        type = 'ARMOUR',
        pickup = 'PICKUP_ARMOUR_STANDARD',
        model = 'prop_armour_pickup',
    },

    HEALTH_STANDARD = {
        max = 5,
        name = 'Bandagem',
        slotType = 'Quaternary',
        type = 'HEALTH',
        model = 'prop_ld_health_pack',
    },

    PARACHUTE = {
        max = 1,
        name = 'Paraquedas',
        type = 'PARACHUTE',
        pickup = 'WEAPON',
    },

    WEAPON_SMOKEGRENADE = {
        max = 3,
        name = 'GRANADA DE FUMAÇA',
        slotType = 'Quinary',
        type = 'GRENADE',
        model = 'w_ex_grenadesmoke',
    },

    WEAPON_ASSAULTSMG = {
        max = 1,
        name = 'MTAR-21',
        slotType = 'Secondary',
        type = 'SMG',
        ammo = 'WEAPON_AMMO',
        model = 'w_sb_assaultsmg',
    },

    WEAPON_MICROSMG = {
        max = 1,
        name = 'MICRO UZI',
        slotType = 'Secondary',
        type = 'SMG',
        useInVehicle = true,
        ammo = 'WEAPON_AMMO',
        model = 'w_sb_microsmg',
    },

    WEAPON_MACHINEPISTOL = {
        max = 1,
        name = 'TEC-9',
        slotType = 'Secondary',
        type = 'PISTOL',
        useInVehicle = true,
        ammo = 'WEAPON_AMMO',
        model = 'w_sb_compactsmg',
    },

    WEAPON_APPISTOL = {
        max = 1,
        name = 'AP Pistol',
        slotType = 'Secondary',
        type = 'PISTOL',
        useInVehicle = true,
        ammo = 'WEAPON_AMMO',
        model = 'w_pi_appistol',
    },

    WEAPON_PUMPSHOTGUN = {
        max = 1,
        name = 'SHOTGUN',
        slotType = 'Secondary',
        type = 'SHOTGUN',
        ammo = 'WEAPON_AMMO',
        model = 'w_sg_pumpshotgun',
    },

    WEAPON_PISTOL_MK2 = {
        max = 1,
        name = 'FN FIVE-SEVEN',
        slotType = 'Secondary',
        type = 'PISTOL',
        useInVehicle = true,
        ammo = 'WEAPON_AMMO',
        model = 'w_pi_pistolmk2',
    },

    WEAPON_ASSAULTRIFLE = {
        max = 1,
        name = 'AK-103',
        slotType = 'Primary',
        type = 'RIFLE',
        ammo = 'WEAPON_AMMO',
        model = 'w_ar_assaultrifle',
    },

    WEAPON_SPECIALCARBINE = {
        max = 1,
        name = 'G36C',
        slotType = 'Primary',
        type = 'RIFLE',
        ammo = 'WEAPON_AMMO',
        model = 'w_ar_specialcarbine',
    },

    WEAPON_CARBINERIFLE = {
        max = 1,
        name = 'M4A1',
        slotType = 'Primary',
        type = 'RIFLE',
        ammo = 'WEAPON_AMMO',
        model = 'w_ar_carbinerifle',
    },

    WEAPON_AMMO = {
        max = 500,
        name = 'Munição de Arma',
        slotType = 'Tertiary',
        type = 'AMMO',
        model = 'prop_ld_ammo_pack_01',
    },
}


---@param itemName string
---@return number
function GetItemMax(itemName)

    return GItems[itemName] and GItems[itemName].max or 500
end

---@param itemName string
---@return string | nil
function GetWeaponAmmo(itemName)

    return GItems[itemName] and GItems[itemName].ammo
end

---@param itemName string
---@return number | nil
function GetItemModel(itemName)

    local def = GItems[itemName]
    return def and def.model and GetHashKey(def.model) or nil
end
