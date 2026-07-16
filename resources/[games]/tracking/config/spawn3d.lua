--[[
    Configura zonas de spawn 3D do MultiTracking: painéis físicos,
    zonas de spawn principais e zonas extras (veículo) condicionadas
    pelo convar multiTrackingVehicleModeEnabled. Faz merge final em
    MultitrackingSpawnZones.
]]

local resourceName = GetCurrentResourceName()
local imagesBaseUrl = string.format("https://cfx-nui-%s/images/", resourceName)
local serverIdentifier = GetConvar("serverIdentifier", "KINGG")

local function imageUrl(name)
    return string.format("%s%s.png", imagesBaseUrl, name)
end

MultitrackingSpawn3dPanelsLocations = {
    {
        startCds = vector3(-1926.3,  3333.02, 32.95),
        endCds   = vector3(-1936.21, 3316.67, 32.95),
        panelSide = 1,
        spawnDirection = "BA",
    },
    {
        startCds = vector3(150.62, -976.81, 30.09),
        endCds   = vector3(178.63, -990.55, 30.09),
        panelSide = 1,
        spawnDirection = "AB",
    },
    {
        startCds = vector3(1376.07, -746.72, 67.23),
        endCds   = vector3(1381.42, -727.27, 67.23),
        panelSide = 1,
        spawnDirection = "BA",
    },
    {
        startCds = vector3(766.91, 6512.8,  25.69),
        endCds   = vector3(729.69, 6521.87, 27.27),
        panelSide = 1,
        spawnDirection = "BA",
    },
    {
        startCds = vector3(504.34, 6547.19, 27.22),
        endCds   = vector3(468.0,  6552.7,  26.99),
        panelSide = -1,
        spawnDirection = "BA",
    },
    {
        startCds = vector3(1467.55, 3180.4,  40.4),
        endCds   = vector3(1420.84, 3167.38, 40.42),
        panelSide = 1,
        spawnDirection = "BA",
    },
    {
        startCds = vector3(1005.88, 2395.42, 51.37),
        endCds   = vector3(988.25,  2391.96, 51.87),
        panelSide = -1,
        spawnDirection = "BA",
    },
    {
        startCds = vector3(-2186.36, 2633.62, 1.02),
        endCds   = vector3(-2163.81, 2632.36, 1.07),
        panelSide = -1,
        spawnDirection = "AB",
    },
    {
        startCds = vector3(-3463.85, -3027.82, 323.6),
        endCds   = vector3(-3464.66, -3066.98, 323.6),
        panelSide = 1,
        spawnDirection = "BA",
    },
    {
        startCds = vector3(6198.98, 3338.61, 761.62),
        endCds   = vector3(6226.85, 3337.69, 761.62),
        panelSide = 1,
        spawnDirection = "BA",
    },
    {
        startCds = vector3(113.17, -889.46, 134.76),
        endCds   = vector3(75.93,  -875.93, 134.76),
        panelSide = -1,
        spawnDirection = "BA",
    },
}

-- Zonas habilitadas apenas se o modo de veículos estiver ativo
local vehicleZones = {
    {
        name = "zancudo_aquatic",
        centerZoneCds = vector3(-2386.67, 2572.25, 1.07),
        radius = 400.0,
        label = "ZANCUDO - Barcos",
        spawns = {
            vector3(-2176.38, 2653.87, 2.93),
        },
        spawn3d = {
            index = "zancudoAquatic",
            imageUrl = imageUrl("zancudoBarcos"),
            description = "ZANCUDO - Barcos",
        },
    },
    {
        name = "square",
        centerZoneCds = vector3(154.35, -999.23, 29.35),
        radius = 300.0,
        label = "PRAÇA - Carros",
        spawns = {
            vector3(158.82, -998.08, 29.33),
            vector3(137.66, -993.51, 29.35),
        },
        spawn3d = {
            index = "square",
            imageUrl = imageUrl("praca"),
            description = "PRAÇA - Carros",
        },
    },
    {
        name = "sandy_bike",
        centerZoneCds = vector3(1048.19, 2396.84, 52.08),
        radius = 200.0,
        label = "SANDY - Motos",
        spawns = {
            vector3(998.95, 2416.43, 51.18),
        },
        spawn3d = {
            index = "sandyBike",
            imageUrl = imageUrl("sandyMotos"),
            description = "SANDY - Motos",
        },
    },
    {
        name = "sandy_airport",
        centerZoneCds = vector3(1495.62, 3186.33, 40.37),
        radius = 400.0,
        label = "SANDY - Helicópteros",
        spawns = {
            vector3(1430.36, 3150.12, 41.01),
        },
        spawn3d = {
            index = "sandyAirport",
            imageUrl = imageUrl("sandyHelicopteros"),
            description = "SANDY - Helicópteros",
        },
    },
}

-- Zonas sempre habilitadas
local baseZones = {
    {
        name = "zancudo",
        centerZoneCds = vector3(-1970.24, 3321.57, 32.95),
        radius = 300.0,
        label = "ZANCUDO",
        spawns = {
            vector3(-1928.85, 3308.64, 32.95),
        },
        spawn3d = {
            index = "zancudo",
            imageUrl = imageUrl("zancudo"),
            description = "ZANCUDO",
        },
    },
    {
        name = "samirMountain",
        centerZoneCds = vector3(1371.77, -740.02, 67.23),
        radius = 600.0,
        label = "SAMIR - Montanha",
        spawns = {
            vector3(1371.77, -740.02, 67.23),
        },
        spawn3d = {
            index = "samir",
            imageUrl = imageUrl("samir"),
            description = "SAMIR - Montanha",
        },
    },
    {
        name = "arena1",
        centerZoneCds = vector3(-3454.67, -3053.91, 323.6),
        radius = 600.0,
        label = "ARENA",
        spawns = {
            vector3(-3454.67, -3053.91, 323.6),
        },
        spawn3d = {
            index = "arena1",
            imageUrl = imageUrl(serverIdentifier == "NEXT" and "arena_next" or "arena_kingg"),
            description = "ARENA",
        },
    },
    {
        name = "fazenda",
        centerZoneCds = vector3(6216.18, 3342.51, 761.62),
        radius = 600.0,
        label = "FAZENDA",
        spawns = {
            vector3(6216.18, 3342.51, 761.62),
        },
        spawn3d = {
            index = "fazenda",
            imageUrl = imageUrl(serverIdentifier == "NEXT" and "fazenda_next" or "fazenda_kingg"),
            description = "FAZENDA",
        },
    },
    {
        name = "predio",
        centerZoneCds = vector3(81.8, -864.47, 134.76),
        radius = 600.0,
        label = "PREDIO",
        spawns = {
            vector3(81.8, -864.47, 134.76),
        },
        spawn3d = {
            index = "predio",
            imageUrl = imageUrl(serverIdentifier == "NEXT" and "predio_next" or "predio_kingg"),
            description = "PREDIO",
        },
    },
}

MultitrackingSpawnZones = {}

if GetConvarBool("multiTrackingVehicleModeEnabled", true) then
    for _, zone in ipairs(vehicleZones) do
        table.insert(MultitrackingSpawnZones, zone)
    end
end

for _, zone in ipairs(baseZones) do
    table.insert(MultitrackingSpawnZones, zone)
end
