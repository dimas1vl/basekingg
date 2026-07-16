--[[
    Retorna a lista de zoneIds em que o player local está dentro,
    conforme as zonas configuradas em MultitrackingModeAreaZones.zones.
]]

local config = MultitrackingModeAreaZones or {}

local function GetAreaEligibleZones()
    local zones = config.zones or {}
    local eligible = {}

    for zoneId, zoneConfig in pairs(zones) do
        if MultiTrackingIsPlayerInsideZoneConfig(zoneConfig, zoneId) then
            eligible[#eligible + 1] = zoneId
        end
    end

    return eligible
end

_G.GetAreaEligibleZones = GetAreaEligibleZones
