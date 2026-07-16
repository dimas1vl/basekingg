--[[
    Agrega as configurações de cada categoria de modo do MultiTracking
    (vehicles, runner, roll, area) numa única tabela.
]]

local function GetCategoriesModesConfig()
    return {
        vehicles = MultitrackingModeVehicleRoutes,
        runner = MultitrackingModeRunnerZones,
        roll = MultitrackingModeRollZones,
        area = MultitrackingModeAreaZones,
    }
end

_G.GetCategoriesModesConfig = GetCategoriesModesConfig
