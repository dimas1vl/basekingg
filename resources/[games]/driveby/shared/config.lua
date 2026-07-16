Config = Config or {}

Config.DriveBy = {
    mode    = 'Treinamento',
    subMode = 'Drive-Bye',

    vehicle = {
        model          = 'Addon001',
        primaryColor   = 0,
        secondaryColor = 0,
        locked         = true,
        engineOn       = true,
    },

    weapons = {
        { slot = 1, weapon = 'WEAPON_PISTOL_MK2',     ammo = 240, label = 'PISTOL MK2'     },
        { slot = 2, weapon = 'WEAPON_APPISTOL',       ammo = 240, label = 'AP PISTOL'      },
        { slot = 3, weapon = 'WEAPON_MICROSMG',       ammo = 240, label = 'MICRO SMG'      },
        { slot = 4, weapon = 'WEAPON_MACHINEPISTOL',  ammo = 240, label = 'MACHINE PISTOL' },
    },

    endingMs    = 8000,
    scoreLimit  = 25,
    timeLimitMs = 10 * 60 * 1000,

    respawnDelayMs    = 1500,
    spawnProtectionMs = 3000,

    startHealth = 200,
    startArmor  = 100,

    hudUpdateMs = 500,

    spawnPoints = {
        { coords = vec3(1276.34, 3091.43, 40.81), heading = 343.0 },
        { coords = vec3(1118.28, 3097.36, 40.40), heading = 165.1 },
        { coords = vec3(1352.18, 3087.89, 40.53), heading = 165.1 },
        { coords = vec3(1417.37, 3066.23, 43.13), heading = 165.1 },
        { coords = vec3(1423.72, 3245.96, 38.54), heading = 165.1 },
        { coords = vec3(1076.09, 3029.11, 41.16), heading = 165.1 },
    },

    pvpCenter = vec4(1276.34, 3091.43, 40.81, 343.0),
    zone = {
        enabled       = true,
        radius        = 300.0,
        outsideKillMs = 1500,
    },

    scoreboardKeyMapping = {
        command = 'db_stats',
        label   = 'Scoreboard Drive-By',
        key     = 'TAB',
    },
}
