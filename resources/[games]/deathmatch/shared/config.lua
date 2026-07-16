Config = Config or {}

Config.Deathmatch = {
    mode = 'Treinamento',

    endingMs       = 8000,
    scoreLimit     = 30,
    mapTimeLimitMs = 2 * 60 * 1000,
    mapEndShowMs   = 6000,

    respawnDelayMs    = 1000,
    spawnProtectionMs = 2500,

    zoneOutsideRespawnMs = 1500,

    ---@class DMMap
    ---@field name string
    ---@field pvpCenter vector4
    ---@field zone { enabled: boolean, radius: number }
    ---@field spawnPoints vector4[]
    ---@field ipls string[] | nil       Lista opcional de IPLs pra carregar quando entrar nesse mapa.
    variants = {

        ['Mata-Mata Fuzil'] = {
            label = 'FUZIL',
            weapons = {
                { slot = 1, weapon = 'WEAPON_SPECIALCARBINE',   ammo = 250, label = 'SPECIAL CARBINE'    },
                { slot = 2, weapon = 'WEAPON_ASSAULTRIFLE',     ammo = 250, label = 'ASSAULT RIFLE'      },
                { slot = 3, weapon = 'WEAPON_CARBINERIFLE', ammo = 250, label = 'CARBINE RIFLE MK2'  },
                { slot = 4, weapon = 'WEAPON_PISTOL_MK2',       ammo = 250, label = 'PISTOL MK2'         },
                { slot = 5, weapon = 'WEAPON_MICROSMG',         ammo = 250, label = 'MICRO SMG'          },
                { slot = 6, weapon = 'WEAPON_MACHINEPISTOL',    ammo = 250, label = 'MACHINE PISTOL'     },
                { slot = 7, weapon = 'WEAPON_APPISTOL',         ammo = 250, label = 'AP PISTOL'          },
                { slot = 8, weapon = 'WEAPON_ASSAULTSMG',       ammo = 250, label = 'ASSAULT SMG'        },
            },
            ---@type DMMap[]
            maps = {
                {
                    name      = 'GOLF',
                    pvpCenter = vec4(-3453.43, -5763.60, 418.64, 215.7),
                    zone      = { enabled = true, radius = 350.0 },
                    spawnPoints = {
                        vec4(-3681.93, -5617.96, 425.65, 61.7),
                        vec4(-3611.21, -5600.38, 427.92, 321.1),
                        vec4(-3511.28, -5574.59, 433.69, 280.8),
                        vec4(-3470.80, -5714.10, 421.44, 211.7),
                        vec4(-3373.45, -5757.49, 418.74, 240.6),
                        vec4(-3431.62, -5872.92, 410.92, 158.8),
                        vec4(-3345.91, -5858.15, 411.15, 248.4),
                        vec4(-3264.03, -5839.87, 408.79, 277.5),
                        vec4(-3400.28, -5893.07, 410.15, 128.9),
                        vec4(-3500.71, -5688.43, 424.96, 29.3),
                    },
                },
                {
                    name      = 'PREFEITURA',
                    pvpCenter = vec4(2505.05786, -384.014832, 93.4112549, 0.0),
                    zone      = { enabled = true, radius = 250.0 },
                    ipls      = { 'vdg_matamataprefeitura' },
                    ityps     = { 'vdg_muroprefeitura' },
                    spawnPoints = {
                        vec4(2503.187,    -442.530273,  92.2869,    1.8),
                        vec4(2457.86523,  -384.357849,  92.676445,  89.6),
                        vec4(2464.92871,  -349.327881,  92.2986755, 130.9),
                        vec4(2504.536,    -334.080933,  92.31924,   179.4),
                        vec4(2522.50171,  -350.246674,  93.4402161, 207.4),
                        vec4(2477.9082,   -384.271881,  93.71126,   89.5),
                        vec4(2483.854,    -417.4967,    93.0288544, 32.3),
                        vec4(2483.794,    -350.87085,   93.06159,   147.3),
                    },
                },
            },
        },

        ['Mata-Mata Pistola'] = {
            label = 'PISTOLA',
            weapons = {
                { slot = 1, weapon = 'WEAPON_PISTOL_MK2',         ammo = 150, label = 'PISTOL'         },
            },
            ---@type DMMap[]
            maps = {
                {
                    name      = 'MANSAO',
                    pvpCenter = vec4(-3829.53271, -268.087738, 181.854263, 0.0),
                    zone      = { enabled = true, radius = 150.0 },
                    spawnPoints = {
                        vec4(-3766.88672, -282.2045,    181.1864,    282.7),
                        vec4(-3762.60083, -240.404785,  181.97438,   247.5),
                        vec4(-3805.73047, -210.50029,   181.627136,  202.5),
                        vec4(-3876.51465, -268.414948,  185.31897,    89.6),
                        vec4(-3842.73315, -335.089,     188.667175,   11.1),
                        vec4(-3876.48486, -344.013855,  188.667175,   31.7),
                        vec4(-3850.73926, -294.963623,  186.712646,   38.3),
                    },
                },
                {
                    name      = 'FACULDADE',
                    pvpCenter = vec4(-1733.92065, 156.844177, 63.6409569, 0.0),
                    zone      = { enabled = true, radius = 100.0 },
                    ipls      = { 'hei_bh1_29', 'hei_bh1_29_strm_0', 'vdg_arenafaculpistol' },
                    spawnPoints = {
                        vec4(-1756.9707,  183.970078,  63.64099,    139.6),
                        vec4(-1719.12329, 132.029739,  63.641,      329.2),
                        vec4(-1712.27039, 165.620834,  63.6859779,  247.9),
                        vec4(-1753.42822, 137.834824,  63.7358131,   45.7),
                        vec4(-1737.02063, 173.581848,  63.7358,     169.5),
                        vec4(-1737.3833,  143.405472,  63.73333,     14.4),
                    },
                },
            },
        },

    },

    startHealth = 200,
    startArmor  = 100,

    hudUpdateMs = 500,

    scoreboardKeyMapping = {
        command = 'dm_stats',
        label   = 'Scoreboard Mata-Mata',
        key     = 'TAB',
    },
}

---@param subMode string | nil
---@return table[] weapons
function Config.Deathmatch:weaponsFor(subMode)
    if subMode and self.variants and self.variants[subMode] then
        return self.variants[subMode].weapons or {}
    end
    return {}
end

---@param subMode string | nil
---@return DMMap[] maps
function Config.Deathmatch:mapsFor(subMode)
    if subMode and self.variants and self.variants[subMode] then
        return self.variants[subMode].maps or {}
    end
    return {}
end

---@param subMode string | nil
---@param index integer 1-indexed; wraps around
---@return DMMap | nil
function Config.Deathmatch:mapAt(subMode, index)
    local maps = self:mapsFor(subMode)
    if #maps == 0 then return nil end
    local n = #maps
    local i = ((index - 1) % n) + 1
    return maps[i]
end

---@param subMode string | nil
---@return integer
function Config.Deathmatch:mapCount(subMode)
    return #self:mapsFor(subMode)
end
