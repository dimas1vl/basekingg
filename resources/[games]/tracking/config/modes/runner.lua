--[[
    Configuração do modo "runner" do MultiTracking:
    zonas onde o ped corre por uma rota (from -> to) com raio de spawn.
]]

MultitrackingModeRunnerZones = {
    menuCategory = "runner",
    zones = {
        zancudoRunner = {
            label = "Tracking de Corrida",
            radiusSpawnConfig = {
                center = vector3(-1906.58, 3314.78, 32.99),
                radius = 180.0,
            },
            zoneNuiShow = {
                center = vector3(-1906.58, 3314.78, 32.99),
                radius = 20.0,
            },
            points = {
                from = {
                    vector3(-1899.69, 3301.86, 32.99),
                    vector3(-1891.99, 3314.82, 32.99),
                },
                to = {
                    vector3(-1914.05, 3327.84, 32.99),
                    vector3(-1921.66, 3314.77, 32.99),
                },
            },
        },
        runnerSamirMontain = {
            label = "Tracking de Corrida",
            radiusSpawnConfig = {
                center = vector3(1442.85, -656.2, 99.88),
                radius = 180.0,
            },
            zoneNuiShow = {
                center = vector3(1442.85, -656.2, 99.88),
                radius = 80.0,
            },
            points = {
                from = {
                    vector3(1434.82, -644.64, 92.57),
                    vector3(1434.15, -661.11, 95.79),
                },
                to = {
                    vector3(1395.02, -662.0, 79.91),
                    vector3(1395.88, -654.15, 79.19),
                },
            },
        },
        runnerSamirMontain2 = {
            label = "Tracking de Corrida",
            radiusSpawnConfig = {
                center = vector3(1442.85, -656.2, 99.88),
                radius = 180.0,
            },
            zoneNuiShow = {
                center = vector3(1442.85, -656.2, 99.88),
                radius = 80.0,
            },
            points = {
                from = {
                    vector3(1422.84, -671.1, 87.29),
                    vector3(1439.25, -689.88, 86.43),
                },
                to = {
                    vector3(1466.97, -676.11, 106.11),
                    vector3(1462.81, -662.91, 109.3),
                },
            },
        },
        runnerSamir3 = {
            label = "Tracking de Corrida 3",
            radiusSpawnConfig = {
                center = vector3(1442.85, -656.2, 99.88),
                radius = 180.0,
            },
            zoneNuiShow = {
                center = vector3(1442.85, -656.2, 99.88),
                radius = 80.0,
            },
            points = {
                from = {
                    vector3(1353.1,  -838.1, 94.45),
                    vector3(1368.99, -862.02, 98.99),
                },
                to = {
                    vector3(1440.61, -857.2, 111.04),
                    vector3(1445.08, -828.67, 109.47),
                },
            },
        },
        runnerSamir4 = {
            label = "Tracking de Corrida 4",
            radiusSpawnConfig = {
                center = vector3(1442.85, -656.2, 99.88),
                radius = 180.0,
            },
            zoneNuiShow = {
                center = vector3(1442.85, -656.2, 99.88),
                radius = 80.0,
            },
            points = {
                from = {
                    vector3(1504.79, -792.65, 108.81),
                    vector3(1486.71, -779.96, 105.0),
                },
                to = {
                    vector3(1437.11, -849.61, 111.91),
                    vector3(1442.18, -858.86, 110.21),
                },
            },
        },
        runnerSamir5 = {
            label = "Tracking de Corrida 5",
            radiusSpawnConfig = {
                center = vector3(1442.85, -656.2, 99.88),
                radius = 180.0,
            },
            zoneNuiShow = {
                center = vector3(1442.85, -656.2, 99.88),
                radius = 80.0,
            },
            points = {
                from = {
                    vector3(1477.99, -634.22, 111.71),
                    vector3(1464.74, -638.76, 104.58),
                },
                to = {
                    vector3(1474.92, -701.43, 92.28),
                    vector3(1495.56, -698.06, 100.66),
                },
            },
        },
        arena1 = {
            label = "Tracking de Corrida 6",
            radiusSpawnConfig = {
                center = vector3(-3387.72, -3037.11, 323.6),
                radius = 80.0,
            },
            zoneNuiShow = {
                center = vector3(-3387.72, -3037.11, 323.6),
                radius = 80.0,
            },
            points = {
                from = {
                    vector3(-3387.76, -3035.47, 323.6),
                    vector3(-3387.47, -3035.66, 323.6),
                },
                to = {
                    vector3(-3435.28, -3032.35, 323.6),
                    vector3(-3435.24, -3034.35, 323.6),
                },
            },
        },
        arena2 = {
            label = "Tracking de Corrida 7",
            radiusSpawnConfig = {
                center = vector3(-3392.03, -3067.19, 323.6),
                radius = 80.0,
            },
            zoneNuiShow = {
                center = vector3(-3392.03, -3067.19, 323.6),
                radius = 80.0,
            },
            points = {
                from = {
                    vector3(-3392.03, -3067.19, 323.6),
                    vector3(-3395.78, -3067.16, 323.6),
                },
                to = {
                    vector3(-3396.38, -3082.47, 323.6),
                    vector3(-3393.23, -3082.66, 323.6),
                },
            },
        },
        arena3 = {
            label = "Tracking de Corrida 8",
            radiusSpawnConfig = {
                center = vector3(-3409.87, -3037.74, 323.6),
                radius = 80.0,
            },
            zoneNuiShow = {
                center = vector3(-3409.87, -3037.74, 323.6),
                radius = 80.0,
            },
            points = {
                from = {
                    vector3(-3409.87, -3037.74, 323.6),
                    vector3(-3412.72, -3038.74, 323.6),
                },
                to = {
                    vector3(-3412.58, -3054.24, 323.6),
                    vector3(-3409.91, -3054.73, 323.6),
                },
            },
        },
        fazenda1 = {
            label = "Tracking de Corrida 9",
            radiusSpawnConfig = {
                center = vector3(6200.91, 3395.85, 761.62),
                radius = 80.0,
            },
            zoneNuiShow = {
                center = vector3(6200.91, 3395.85, 761.62),
                radius = 80.0,
            },
            points = {
                from = {
                    vector3(6200.91, 3395.85, 761.62),
                    vector3(6199.56, 3395.72, 761.62),
                },
                to = {
                    vector3(6199.21, 3359.26, 761.62),
                    vector3(6200.86, 3358.21, 761.62),
                },
            },
        },
        fazenda2 = {
            label = "Tracking de Corrida 10",
            radiusSpawnConfig = {
                center = vector3(6227.27, 3395.29, 761.62),
                radius = 80.0,
            },
            zoneNuiShow = {
                center = vector3(6227.27, 3395.29, 761.62),
                radius = 80.0,
            },
            points = {
                from = {
                    vector3(6227.27, 3395.29, 761.62),
                    vector3(6227.45, 3393.6,  761.62),
                },
                to = {
                    vector3(6237.93, 3394.31, 761.62),
                    vector3(6238.44, 3396.4,  761.62),
                },
            },
        },
        predio1 = {
            label = "Tracking de Corrida 11",
            radiusSpawnConfig = {
                center = vector3(122.87, -873.51, 134.76),
                radius = 80.0,
            },
            zoneNuiShow = {
                center = vector3(122.87, -873.51, 134.76),
                radius = 80.0,
            },
            points = {
                from = {
                    vector3(116.08, -879.53, 134.76),
                    vector3(115.0,  -879.06, 134.76),
                },
                to = {
                    vector3(111.73, -888.15, 134.76),
                    vector3(113.59, -888.91, 134.76),
                },
            },
        },
        predio2 = {
            label = "Tracking de Corrida 11",
            radiusSpawnConfig = {
                center = vector3(122.87, -873.51, 134.76),
                radius = 80.0,
            },
            zoneNuiShow = {
                center = vector3(122.87, -873.51, 134.76),
                radius = 80.0,
            },
            points = {
                from = {
                    vector3(122.87, -873.51, 134.76),
                    vector3(123.31, -872.43, 134.76),
                },
                to = {
                    vector3(100.72, -858.34, 134.76),
                    vector3(98.65,  -861.31, 134.76),
                },
            },
        },
    },
}
