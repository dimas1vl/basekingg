--[[ Modo "roll": expoe GetRollEligibleZones, lista de zonas onde o jogador esta dentro. ]]

local zonesConfig = MultitrackingModeRollZones or {}

local function getRollEligibleZones()
    local zonesMap = zonesConfig.zones or {}
    local eligible = {}

    for zoneKey, zoneConfig in pairs(zonesMap) do
        if MultiTrackingIsPlayerInsideZoneConfig(zoneConfig, zoneKey) then
            eligible[#eligible + 1] = zoneKey
        end
    end

    return eligible
end
GetRollEligibleZones = getRollEligibleZones
