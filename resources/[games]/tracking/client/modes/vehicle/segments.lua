--[[ Calcula quantos segmentos de tracking (veiculos) spawnar para uma rota. ]]

local function CalculateTrackingVehiclesSegments(_)
    local globalMax = 5
    local config = GetGlobalConfigBuilder("vehicles")
    if config and config.get then
        local value = config.get("maxGenerateVehicles")
        if value then
            globalMax = tonumber(value) or globalMax
        end
    end
    return math.max(1, math.min(40, globalMax))
end

_G.CalculateTrackingVehiclesSegments = CalculateTrackingVehiclesSegments
