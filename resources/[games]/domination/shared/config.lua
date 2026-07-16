Config = Config or {}

Config.Domination = {
    startHealth = 200,
    startArmor  = 0,
    moveSpeedMultiplier = 1.49,
    defaultRadius = 75.0,
    captureSpeedPerMember = 0, -- 0% por membro

    respawn = {
        default  = 10,
        vip      = 8,
        streamer = 6,
        admin    = 5,
    },
    reviveTime     = 10,
    reviveDistance = 2.0,

    killcam = {
        enabled   = true,
        grayscale = true,
    },

    safeZones = {
        { id = 'pier',   label = 'Pier',   center = vec4(-1579.45, -972.88, 12.02, 300.0), radius = 300.0 },
        { id = 'samir',  label = 'Samir',  center = vec4(1389.12,  -659.97, 77.79, 300.0), radius = 300.0 },
        { id = 'norte',  label = 'Norte',  center = vec4(1148.82,  3064.74, 39.88, 300.0), radius = 300.0 },
        { id = 'paleto', label = 'Paleto', center = vec4(1418.03,  6564.83, 16.36, 200.0), radius = 200.0 },
    },

    locations = {
        { id = 'moto_club_sul',           name = 'Moto Club Sul',           coords = vec4(977.26, -118.54, 73.16, 44.0),     radius = 44.0 },
        { id = 'banco_central',           name = 'Banco Central',           coords = vec4(231.15, 214.90, 105.07, 100.0),    radius = 100.0 },
        { id = 'castelinho',              name = 'Castelinho',              coords = vec4(-76.57, 343.90, 111.45, 80.0),     radius = 80.0 },
        { id = 'mansoes',                 name = 'Mansões',                 coords = vec4(-115.81, 927.53, 234.75, 100.0),   radius = 100.0 },
        { id = 'ls_customs',              name = 'Ls Customs',              coords = vec4(-333.95, -136.99, 38.01, 20.0),    radius = 20.0 },
        { id = 'rockford_plaza',          name = 'Rockford Plaza',          coords = vec4(-180.41, -170.82, 42.62, 42.0),    radius = 60.0 },
        { id = 'gas',                     name = 'Gás',                     coords = vec4(-28.70, -687.16, 31.34, 90.0),     radius = 90.0 },
        { id = 'dp_praca',                name = 'DP Praça',                coords = vec4(449.54, -985.27, 29.69, 40.0),     radius = 40.0 },
        { id = 'ammunation_praca',        name = 'Ammunation Praça',        coords = vec4(16.63, -1106.41, 28.80, 16.0),     radius = 18.0 },
        { id = 'vanilla',                 name = 'Vanilla',                 coords = vec4(132.61, -1305.08, 28.19, 60.0),    radius = 60.0 },
        { id = 'rox',                     name = 'Rox',                     coords = vec4(369.75, -1676.07, 26.31, 60.0),    radius = 60.0 },
        { id = 'ammunation_porto',        name = 'Ammunation Porto',        coords = vec4(816.81, -2157.53, 28.62, 20.0),    radius = 20.0 },
        { id = 'acougue',                 name = 'Açougue',                 coords = vec4(993.57, -2145.33, 28.48, 80.0),    radius = 80.0 },
        { id = 'porto',                   name = 'Porto',                   coords = vec4(978.23, -3034.18, 4.90, 120.0),    radius = 120.0 },
        { id = 'navio',                   name = 'Navio',                   coords = vec4(-163.79, -2372.06, 8.32, 90.0),    radius = 90.0 },
        { id = 'aeroporto_sul',           name = 'Aeroporto Sul',           coords = vec4(-965.91, -2609.03, 12.98, 100.0),  radius = 100.0 },
        { id = 'bloods',                  name = 'Bloods',                  coords = vec4(-1097.61, -1632.67, 3.40, 64.0),   radius = 64.0 },
        { id = 'veneza',                  name = 'Veneza',                  coords = vec4(-1034.11, -1071.73, 3.10, 110.0),  radius = 110.0 },
        { id = 'dp_vespucci',             name = 'DP Vespucci',             coords = vec4(-1128.46, -850.87, 12.52, 30.0),   radius = 30.0 },
        { id = 'estacionamento_praia',    name = 'Estacionamento Praia',    coords = vec4(-2017.39, -348.06, 47.11, 30.0),   radius = 30.0 },
        { id = 'labirinto',               name = 'Labirinto',               coords = vec4(-2275.72, 239.58, 168.60, 100.0),  radius = 100.0 },
        { id = 'fleeca_praia',            name = 'Fleeca Praia',            coords = vec4(-2957.73, 481.56, 14.70, 80.0),    radius = 80.0 },
        { id = 'playboy',                 name = 'Playboy',                 coords = vec4(-1556.17, -34.38, 56.09, 100.0),   radius = 100.0 },
        { id = 'hotel_rosa',              name = 'Hotel Rosa',              coords = vec4(-1321.58, 304.94, 63.66, 100.0),   radius = 100.0 },
        { id = 'estacionamento_vermelho', name = 'Estacionamento Vermelho', coords = vec4(-332.87, -765.38, 32.97, 70.0),    radius = 70.0 },
        { id = 'lixeiro',                 name = 'Lixeiro',                 coords = vec4(-609.94, -1609.49, 25.90, 66.0),   radius = 70.0 },
        { id = 'ls_abandonada',           name = 'Ls Abandonada',           coords = vec4(-1144.39, -1989.86, 12.16, 60.0),  radius = 60.0 },
        { id = 'festa_junina',            name = 'Festa Junina',            coords = vec4(389.79, -356.08, 47.02, 60.0),     radius = 60.0 },
        { id = 'crips',                   name = 'Crips',                   coords = vec4(1275.07, -1721.50, 53.66, 60.0),   radius = 60.0 },
        { id = 'tequilala',               name = 'Tequi-la-la',             coords = vec4(-558.73, 285.67, 81.18, 30.0),     radius = 30.0 },
        { id = 'life_invader',            name = 'Life Invader',            coords = vec4(-1065.34, -244.52, 38.73, 44.0),   radius = 44.0 },
        { id = 'metro',                   name = 'Metro',                   coords = vec4(-825.83, -112.81, 26.96, 40.0),    radius = 40.0 },
        { id = 'auditorio',               name = 'Auditorio',               coords = vec4(738.42, 582.17, 124.92, 140.0),    radius = 140.0 },
        { id = 'maze_arena',              name = 'Maze Arena',              coords = vec4(-253.46, -2020.93, 29.15, 40.0),   radius = 42.0 },
        { id = 'joalheria',               name = 'Joalheria',               coords = vec4(-632.82, -238.57, 37.07, 80.0),    radius = 80.0 },
        { id = 'costureira',              name = 'Costureira',              coords = vec4(717.60, -964.65, 29.40, 26.0),     radius = 26.0 },
        { id = 'rally',                   name = 'Rally',                   coords = vec4(1015.09, 2363.86, 50.67, 112.0),   radius = 112.0 },
        { id = 'presidio',                name = 'Presidio',                coords = vec4(1706.14, 2604.89, 44.56, 100.0),   radius = 100.0 },
        { id = 'yellow_jack',             name = 'Yellow Jack',             coords = vec4(1991.06, 3054.26, 46.21, 60.0),    radius = 60.0 },
        { id = 'cemiterio_aviao',         name = 'Cemitério de Avião',      coords = vec4(2385.53, 3089.76, 47.15, 90.0),    radius = 90.0 },
        { id = 'niobio',                  name = 'Nióbio',                  coords = vec4(3598.58, 3703.29, 28.69, 94.0),    radius = 94.0 },
        { id = 'fazenda_sandy',           name = 'Fazenda Sandy',           coords = vec4(2438.99, 4992.71, 45.06, 100.0),   radius = 100.0 },
        { id = 'motel',                   name = 'Motel',                   coords = vec4(1564.01, 3573.29, 32.70, 74.0),    radius = 74.0 },
        { id = 'motoclub_norte',          name = 'Motoclub Norte',          coords = vec4(73.59, 3710.14, 38.75, 100.0),     radius = 100.0 },
        { id = 'galinheiro',              name = 'Galinheiro',              coords = vec4(-101.60, 6206.44, 30.03, 80.0),    radius = 80.0 },
        { id = 'madeireira',              name = 'Madeireira',              coords = vec4(-567.10, 5343.83, 69.22, 140.0),   radius = 140.0 },
        { id = 'pelados',                 name = 'Pelados',                 coords = vec4(-1118.51, 4923.91, 217.26, 80.0),  radius = 80.0 },
        { id = 'iate',                    name = 'Iate',                    coords = vec4(-1422.02, 6755.75, 4.88, 60.0),    radius = 60.0 },
        { id = 'ilha',                    name = 'Ilha',                    coords = vec4(-2168.89, 5196.79, 16.03, 200.0),  radius = 200.0 },
        { id = 'banco_paleto',            name = 'Banco de Paleto',         coords = vec4(-107.14, 6466.98, 30.63, 20.0),    radius = 20.0 },
        { id = 'fort_zancudo',            name = 'Fort Zancudo',            coords = vec4(-2141.15, 3251.33, 31.81, 100.0),  radius = 100.0 },
        { id = 'ammunation_paleto',       name = 'Ammunation de Paleto',    coords = vec4(-353.78, 6105.38, 30.44, 60.0),    radius = 60.0 },
        { id = 'mergulhador',             name = 'Mergulhador',             coords = vec4(2748.22, 1552.38, 23.50, 160.0),   radius = 160.0 },
        { id = 'dp_palomino',             name = 'Dp Palomino',             coords = vec4(2504.09, -383.81, 93.12, 80.0),    radius = 80.0 },
        { id = 'vinhedo',                 name = 'Vinhedo',                 coords = vec4(-1879.59, 2073.99, 140.00, 160.0), radius = 160.0 },
        { id = 'fazenda',                 name = 'Fazenda',                 coords = vec4(1431.35, 1117.30, 113.23, 100.0),  radius = 100.0 },
        { id = 'observatorio',            name = 'Observatorio',            coords = vec4(-425.71, 1123.37, 324.85, 100.0),  radius = 100.0 },
    },

    zoneTypes = {
        { key = 'comum',      label = 'Comum',      tag = nil,               blipColor = 5, marker = { 255, 230, 0,  150 }, captureSeconds = 120, rewardXp = 150, rewardMoney = 140, cooldown = 300, rewardInterval = 5 },
        { key = 'oculta',     label = 'Oculta',     tag = 'Oculta',          blipColor = 3, marker = { 40,  130, 255, 150 }, captureSeconds = 120, rewardXp = 150, rewardMoney = 140, cooldown = 300, rewardInterval = 5 },
        { key = 'oculta_xp2', label = 'Oculta XP2', tag = 'Verde',           blipColor = 2, marker = { 60,  230, 90,  150 }, captureSeconds = 120, rewardXp = 300, rewardMoney = 140, cooldown = 300, rewardInterval = 5 },
        { key = 'bandeira',   label = 'Bandeira',   tag = 'Bandeira',        blipColor = 8, marker = { 255, 80,  200, 150 }, captureSeconds = 120, rewardXp = 200, rewardMoney = 200, cooldown = 300, rewardInterval = 5 },
        { key = 'times',      label = 'Times',      tag = 'Times (Premium)', blipColor = 7, marker = { 160, 80,  255, 150 }, captureSeconds = 120, rewardXp = 200, rewardMoney = 500, cooldown = 300, rewardInterval = 5 },
    },

    zoneLimits = {
        times    = 3,
        bandeira = 3,
    },

    level = {
        xpPerLevel     = 1000,
        xpPerKill      = 100,
        maxLevel       = 100,
        killCooldownMs = 15000,
        maxKillsPerMin = 20,
    },

    categories = {
        { key = 'fuzil',   slot = 1, label = 'FUZIL',   ammo = 250 },
        { key = 'sub',     slot = 2, label = 'SUB',     ammo = 250 },
        { key = 'pistola', slot = 3, label = 'PISTOLA', ammo = 150 },
        { key = 'faca',    slot = 4, label = 'FACA',    ammo = 1, speedMultiplier = 1.49 },
    },

    weapons = {

        fuzil = {
            { id = 'bullpup',             label = 'BULLPUP RIFLE',       weapon = 'WEAPON_BULLPUPRIFLE',       icon = 'bullpup-rifle-icon',       level = 1,  price = 0,      default = true },
            { id = 'advanced',            label = 'ADVANCED RIFLE',      weapon = 'WEAPON_ADVANCEDRIFLE',      icon = 'advanced-rifle-icon',      level = 1,  price = 100    },
            { id = 'special_carbine',     label = 'SPECIAL CARBINE',     weapon = 'WEAPON_SPECIALCARBINE',     icon = 'special-carbine-icon',     level = 20, price = 12000  },
            { id = 'compact',             label = 'COMPACT RIFLE',       weapon = 'WEAPON_COMPACTRIFLE',       icon = 'compact-rifle-icon',       level = 30, price = 20000  },
            { id = 'carbine_mk2',         label = 'CARBINE RIFLE MK2',   weapon = 'WEAPON_CARBINERIFLE_MK2',   icon = 'carbine-rifle-mk2-icon',   level = 40, price = 35000  },
            { id = 'bullpup_mk2',         label = 'BULLPUP RIFLE MK2',   weapon = 'WEAPON_BULLPUPRIFLE_MK2',   icon = 'bullpup-rifle-mk2-icon',   level = 60, price = 75000  },
            { id = 'special_carbine_mk2', label = 'SPECIAL CARBINE MK2', weapon = 'WEAPON_SPECIALCARBINE_MK2', icon = 'special-carbine-mk2-icon', level = 80, price = 150000 },
        },

        sub = {
            { id = 'micro_smg',      label = 'MICRO SMG',      weapon = 'WEAPON_MICROSMG',      icon = 'micro-smg-icon',      level = 1,  price = 0,      default = true },
            { id = 'mini_smg',       label = 'MINI SMG',       weapon = 'WEAPON_MINISMG',       icon = 'mini-smg-icon',       level = 1,  price = 100   },
            { id = 'smg',            label = 'SMG',            weapon = 'WEAPON_SMG',           icon = 'smg-icon',            level = 15, price = 8000  },
            { id = 'combat_pdw',     label = 'COMBAT PDW',     weapon = 'WEAPON_COMBATPDW',     icon = 'combat-pdw-icon',     level = 25, price = 18000 },
            { id = 'assault_smg',    label = 'ASSAULT SMG',    weapon = 'WEAPON_ASSAULTSMG',    icon = 'assault-smg-icon',    level = 35, price = 30000 },
            { id = 'machine_pistol', label = 'MACHINE PISTOL', weapon = 'WEAPON_MACHINEPISTOL', icon = 'machine-pistol-icon', level = 45, price = 42000 },
            { id = 'tactical_smg',   label = 'TACTICAL SMG',   weapon = 'WEAPON_TACTICALSMG',   icon = 'tactical-smg-icon',   level = 60, price = 80000 },
            { id = 'smg_mk2',        label = 'SMG MK2',        weapon = 'WEAPON_SMG_MK2',       icon = 'smg-mk2-icon',        level = 80, price = 150000 },
        },

        pistola = {
            { id = 'pistol_mk2',      label = 'PISTOL MK2',      weapon = 'WEAPON_PISTOL_MK2',     icon = 'pistol-mk2-icon',      level = 1,  price = 0,     default = true },
            { id = 'ceramic',         label = 'CERAMIC PISTOL',  weapon = 'WEAPON_CERAMICPISTOL',  icon = 'ceramic-pistol-icon',  level = 1,  price = 100  },
            { id = 'vintage',         label = 'VINTAGE PISTOL',  weapon = 'WEAPON_VINTAGEPISTOL',  icon = 'vintage-pistol-icon',  level = 10, price = 6000 },
            { id = 'heavy_pistol',    label = 'HEAVY PISTOL',    weapon = 'WEAPON_HEAVYPISTOL',    icon = 'heavy-pistol-icon',    level = 20, price = 12000 },
            { id = 'appistol',        label = 'AP PISTOL',       weapon = 'WEAPON_APPISTOL',       icon = 'appistol-icon',        level = 30, price = 20000 },
            { id = 'pistol50',        label = 'PISTOL .50',      weapon = 'WEAPON_PISTOL50',       icon = 'pistol.50-icon',       level = 40, price = 35000 },
            { id = 'marksman_pistol', label = 'MARKSMAN PISTOL', weapon = 'WEAPON_MARKSMANPISTOL', icon = 'marksman-pistol-icon', level = 55, price = 60000 },
            { id = 'heavy_revolver',  label = 'HEAVY REVOLVER',  weapon = 'WEAPON_HEAVYREVOLVER',  icon = 'heavy-revolver-icon',  level = 70, price = 100000 },
            { id = 'navy_revolver',   label = 'NAVY REVOLVER',   weapon = 'WEAPON_NAVYREVOLVER',   icon = 'navy-revolver-icon',   level = 90, price = 250000 },
            { id = 'perico',          label = 'PERICO PISTOL',   weapon = 'WEAPON_PERICOPISTOL',   icon = 'perico-pistol-icon',   level = 100, price = 400000 },
        },

        faca = {
            { id = 'knife',        label = 'FACA',              weapon = 'WEAPON_KNIFE',        icon = 'knife-icon',        level = 1,  price = 0,     default = true },
            { id = 'knuckle',      label = 'SOCO INGLÊS',       weapon = 'WEAPON_KNUCKLE',      icon = 'knuckles-icon',     level = 1,  price = 100  },
            { id = 'hatchet',      label = 'MACHADINHA',        weapon = 'WEAPON_HATCHET',      icon = 'hatchet-icon',      level = 15, price = 8000 },
            { id = 'battle_axe',   label = 'MACHADO DE GUERRA', weapon = 'WEAPON_BATTLEAXE',    icon = 'battle-axe-icon',   level = 30, price = 20000 },
            { id = 'hammer',       label = 'MARTELO',           weapon = 'WEAPON_HAMMER',       icon = 'hammer-icon',       level = 45, price = 40000 },
            { id = 'stone_hatchet', label = 'MACHADO DE PEDRA', weapon = 'WEAPON_STONE_HATCHET', icon = 'stone-hatchet-icon', level = 70, price = 100000 },
            { id = 'candy_cane',   label = 'BENGALA DOCE',      weapon = 'WEAPON_CANDYCANE',    icon = 'candy-cane-icon',   level = 100, price = 300000 },
        },
    },
}

Config.Domination.flag = {
    model      = 'prop_flag_ls',
    returnMs   = 30000,
    bone       = 24818,
    offset     = { x = 0.0, y = -0.22, z = 0.0 },
    rot        = { x = 0.0, y = 0.0,  z = 0.0 },
    pickupDist = 2.5,
}

Config.Domination.vehicleImageBase = ''

Config.Domination.vehicleCategories = {
    { key = 'gratis',         label = 'GRATIS'         },
    { key = 'booster',        label = 'BOOSTER'        },
    { key = 'vips',           label = 'VIPS'           },
    { key = 'semi_blindados', label = 'SEMI BLINDADOS' },
    { key = 'blindados',      label = 'BLINDADOS'      },
    { key = 'streamer',       label = 'STREAMER'       },
    { key = 'exclusivos',     label = 'EXCLUSIVOS'     },
}

Config.Domination.vehicles = {
    gratis = {
        { id = 'apocalipse', label = 'APOCALIPSE', model = 'manchez',   image = 'apocalipse' },
        { id = 'contender',  label = 'CONTENDER',  model = 'contender', image = 'contender'  },
        { id = 'kuruma',     label = 'KURUMA',     model = 'kuruma',    image = 'kuruma'     },
        { id = 'outlaw',     label = 'OUTLAW',     model = 'outlaw',    image = 'outlaw'     },
        { id = 'terminus',   label = 'TERMINUS',   model = 'terminus',  image = 'terminus'   },
    },
    booster = {
        { id = 'sultan',   label = 'SULTAN',   model = 'sultan',    image = 'sultan',   level = 5     },
        { id = 'elegy',    label = 'ELEGY',    model = 'elegy2',    image = 'elegy',    level = 15    },
        { id = 'comet',    label = 'COMET',    model = 'comet2',    image = 'comet',    price = 8000  },
        { id = 'sentinel', label = 'SENTINEL', model = 'sentinel3', image = 'sentinel', price = 15000 },
    },
    vips = {
        { id = 'dominator', label = 'DOMINATOR', model = 'dominator3', image = 'dominator', requires = 'vip' },
        { id = 'banshee',   label = 'BANSHEE',   model = 'banshee2',   image = 'banshee',   requires = 'vip' },
        { id = 'zentorno',  label = 'ZENTORNO',  model = 'zentorno',   image = 'zentorno',  requires = 'vip' },
    },
    semi_blindados = {
        { id = 'kuruma_b', label = 'KURUMA BLINDADO', model = 'kuruma2', image = 'kuruma_blindado', price = 25000 },
        { id = 'baller',   label = 'BALLER',          model = 'baller5', image = 'baller',          level = 30    },
        { id = 'schafter', label = 'SCHAFTER',        model = 'schafter5', image = 'schafter',      price = 35000 },
    },
    blindados = {
        { id = 'insurgent',  label = 'INSURGENT',  model = 'insurgent3', image = 'insurgent',  price = 60000 },
        { id = 'nightshark', label = 'NIGHTSHARK', model = 'nightshark', image = 'nightshark', requires = 'vip' },
        { id = 'kuruma_arm', label = 'KURUMA ARMOR', model = 'kuruma2',  image = 'kuruma_armor', price = 90000 },
    },
    streamer = {
        { id = 'tyrant',  label = 'TYRANT',  model = 'tyrant',  image = 'tyrant',  requires = 'streamer' },
        { id = 'krieger', label = 'KRIEGER', model = 'krieger', image = 'krieger', requires = 'streamer' },
    },
    exclusivos = {
        { id = 'vigilante', label = 'VIGILANTE', model = 'vigilante',  image = 'vigilante', requires = 'exclusive' },
        { id = 'oppressor', label = 'OPPRESSOR', model = 'oppressor2', image = 'oppressor', requires = 'exclusive' },
    },
}

Config.Domination.team = {
    maxMembers   = 10,
    nameMinLen   = 3,
    nameMaxLen   = 24,

    roleCaps = {
        gerente    = 1,
        sublider   = 2,
        recrutador = 3,
    },

    roleRank = {
        lider      = 5,
        gerente    = 4,
        sublider   = 3,
        recrutador = 2,
        membro     = 1,
    },

    roleLabels = {
        lider      = 'LÍDER',
        gerente    = 'GERENTE',
        sublider   = 'SUB LÍDER',
        recrutador = 'RECRUTADOR',
        membro     = 'MEMBRO',
    },
}

---@return number level
function Config.Domination.levelFromXp(xp)
    local per = Config.Domination.level.xpPerLevel
    local lvl = math.floor((tonumber(xp) or 0) / per) + 1
    local maxL = Config.Domination.level.maxLevel or 100
    if lvl > maxL then lvl = maxL end
    if lvl < 1 then lvl = 1 end
    return lvl
end

---@param categoryKey string
---@return table|nil
function Config.Domination.getCategory(categoryKey)
    for i = 1, #Config.Domination.categories do
        if Config.Domination.categories[i].key == categoryKey then
            return Config.Domination.categories[i]
        end
    end
    return nil
end

---@param categoryKey string
---@return table|nil
function Config.Domination.getCategoryBySlot(slot)
    for i = 1, #Config.Domination.categories do
        if Config.Domination.categories[i].slot == slot then
            return Config.Domination.categories[i]
        end
    end
    return nil
end

---@param weaponId string
---@param categoryKey? string limita a busca a uma categoria
---@return table|nil, string|nil
function Config.Domination.findWeapon(weaponId, categoryKey)
    local cats = Config.Domination.weapons
    if categoryKey then
        local list = cats[categoryKey]
        if not list then return nil, nil end
        for i = 1, #list do
            if list[i].id == weaponId then return list[i], categoryKey end
        end
        return nil, nil
    end
    for catKey, list in pairs(cats) do
        for i = 1, #list do
            if list[i].id == weaponId then return list[i], catKey end
        end
    end
    return nil, nil
end

---@param categoryKey string
---@return table|nil
function Config.Domination.getDefaultWeapon(categoryKey)
    local list = Config.Domination.weapons[categoryKey]
    if not list then return nil end
    for i = 1, #list do
        if list[i].default then return list[i] end
    end
    return list[1]
end

---@param vehId string
---@param categoryKey? string
---@return table|nil, string|nil
function Config.Domination.findVehicle(vehId, categoryKey)
    local cats = Config.Domination.vehicles
    if categoryKey then
        local list = cats[categoryKey]
        if not list then return nil, nil end
        for i = 1, #list do
            if list[i].id == vehId then return list[i], categoryKey end
        end
        return nil, nil
    end
    for catKey, list in pairs(cats) do
        for i = 1, #list do
            if list[i].id == vehId then return list[i], catKey end
        end
    end
    return nil, nil
end

---@param key string
---@return table|nil
function Config.Domination.findZoneType(key)
    local list = Config.Domination.zoneTypes
    for i = 1, #list do
        if list[i].key == key then return list[i] end
    end
    return nil
end

---@param assignment table<string,string>
---@return table[]
function Config.Domination.buildDominationZones(assignment)
    local out  = {}
    local locs = Config.Domination.locations
    for i = 1, #locs do
        local loc = locs[i]
        local typeKey = assignment and assignment[loc.id]
        local t = typeKey and Config.Domination.findZoneType(typeKey) or nil
        if t then
            out[#out + 1] = {
                id             = loc.id,
                label          = loc.name or loc.id,
                type           = t.key,
                tag            = t.tag,
                center         = loc.coords,
                radius         = loc.radius or Config.Domination.defaultRadius or 200.0,
                blipColor      = t.blipColor,
                marker         = t.marker,
                captureSeconds = t.captureSeconds or 30,
                rewardXp       = t.rewardXp or 0,
                rewardMoney    = t.rewardMoney or 0,
                rewardInterval = t.rewardInterval or 5,
                cooldown       = t.cooldown or 0,
            }
        end
    end
    return out
end

Config.Domination.dominationZones = {}
