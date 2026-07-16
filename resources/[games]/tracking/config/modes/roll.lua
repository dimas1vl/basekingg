--[[
    Configuração do modo "roll" do MultiTracking:
    lista de animações de combat roll disponíveis e zonas de tracking.
]]

MultitrackingModeRollAnimations = {
    ["move_strafe@roll_fps"] = {
        "combatroll_fwd_p1_00",
        "combatroll_fwd_p1_90",
        "combatroll_bwd_p1_180",
        "combatroll_fwd_p1_135",
        "combatroll_fwd_p1_45",
        "combatroll_bwd_p1_135",
    },
}

MultitrackingModeRollZones = {
    menuCategory = "roll",
    zones = {
        roll1 = {
            label = "Tracking de Rolamento 1",
            heading = 70.0,
            animations = MultitrackingModeRollAnimations,
            radiusSpawnConfig = {
                center = vector3(-1915.98, 3301.4, 32.99),
                radius = 180.0,
            },
            zoneNuiShow = {
                center = vector3(-1915.98, 3301.4, 32.99),
                radius = 10.0,
            },
            points = {
                from = {
                    vector3(-1914.5,  3296.04, 32.99),
                    vector3(-1911.45, 3301.83, 32.99),
                },
                to = {
                    vector3(-1914.67, 3303.6, 32.99),
                    vector3(-1918.34, 3298.3, 32.99),
                },
            },
        },
        roll2 = {
            label = "Tracking de Rolamento 2",
            heading = 250.0,
            animations = MultitrackingModeRollAnimations,
            radiusSpawnConfig = {
                center = vector3(-1907.62, 3296.18, 32.99),
                radius = 180.0,
            },
            zoneNuiShow = {
                center = vector3(-1907.62, 3296.18, 32.99),
                radius = 10.0,
            },
            points = {
                from = {
                    vector3(-1914.04, 3293.55, 32.99),
                    vector3(-1908.47, 3303.39, 32.99),
                },
                to = {
                    vector3(-1900.65, 3298.75, 32.99),
                    vector3(-1906.19, 3289.17, 32.99),
                },
            },
        },
    },
}
