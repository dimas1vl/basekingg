--[[
    Configuração das zonas do modo "area" do MultiTracking:
    cada zona define centro de spawn, zona de exibição de NUI e
    pares de pontos (from/to) para o tracking.
]]

MultitrackingModeAreaZones = {
    menuCategory = "area",
    zones = {
        areaZancudo = {
            label = "Tracking de Spawn",
            heading = 70.0,
            radiusSpawnConfig = {
                center = vector3(-1926.63, 3281.72, 32.99),
                radius = 180.0,
            },
            zoneNuiShow = {
                center = vector3(-1926.63, 3281.72, 32.99),
                radius = 20.0,
            },
            points = {
                from = {
                    vector3(-1919.29, 3268.84, 32.99),
                    vector3(-1911.59, 3282.0,  32.99),
                },
                to = {
                    vector3(-1933.64, 3294.84, 32.99),
                    vector3(-1941.45, 3281.76, 32.99),
                },
            },
        },
        areaSamirMontain = {
            label = "Tracking de Spawn",
            heading = 70.0,
            radiusSpawnConfig = {
                center = vector3(-3414.3, -3057.4, 323.6),
                radius = 180.0,
            },
            zoneNuiShow = {
                center = vector3(-3414.3, -3057.4, 323.6),
                radius = 20.0,
            },
            points = {
                from = {
                    vector3(-3414.3,  -3057.4,  323.6),
                    vector3(-3414.24, -3050.48, 323.6),
                },
                to = {
                    vector3(-3424.48, -3050.44, 323.6),
                    vector3(-3425.01, -3057.61, 323.6),
                },
            },
        },
    },
}
