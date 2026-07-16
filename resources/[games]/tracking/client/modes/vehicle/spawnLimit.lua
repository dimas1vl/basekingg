--[[ Controla o limite global de tracking vehicles ativos simultaneamente. ]]

local convarFallback = GetConvarInt("multiTrackingSpawnVehiclesLimit", 20)

---@return number
local function getCurrentLimit()
    local cfg = GetGlobalConfigBuilder and GetGlobalConfigBuilder("vehicles")
    if cfg and cfg.get then
        local v = tonumber(cfg.get("maxGenerateVehicles"))
        if v and v > 0 then return v end
    end
    return convarFallback
end

---@return number
local function GetActiveTrackingVehiclesCount()
    local instances = GetAllTrackingVehiclesInstances()
    local count = 0
    for _, routeInstances in pairs(instances) do
        for _, instance in pairs(routeInstances) do
            if not instance.destroyed then
                if instance.spawning or (instance.vehicle and DoesEntityExist(instance.vehicle)) then
                    count = count + 1
                end
            end
        end
    end
    return count
end
_G.GetActiveTrackingVehiclesCount = GetActiveTrackingVehiclesCount

---@return boolean
local function HasLimitTrackingVehicles()
    return GetActiveTrackingVehiclesCount() >= getCurrentLimit()
end
_G.HasLimitTrackingVehicles = HasLimitTrackingVehicles

local function EnforceLimitNow()
    local limit = getCurrentLimit()
    local instances = GetAllTrackingVehiclesInstances()
    local activeList = {}
    for _, routeInstances in pairs(instances) do
        for _, instance in pairs(routeInstances) do
            if not instance.destroyed and instance.vehicle and DoesEntityExist(instance.vehicle) then
                activeList[#activeList + 1] = instance
            end
        end
    end
    while #activeList > limit do
        local victim = table.remove(activeList)
        if victim and victim.destroy then victim:destroy() end
    end
end
_G.EnforceTrackingVehiclesLimit = EnforceLimitNow

AddEventHandler("multiTracking:vehicle:client:refreshLimit", function()
    EnforceLimitNow()
    TriggerEvent("multiTracking:reloadVehicles")
end)

AddConvarChangeListener("multiTrackingSpawnVehiclesLimit", function()
    convarFallback = GetConvarInt("multiTrackingSpawnVehiclesLimit", 20)
    EnforceLimitNow()
end)
