--[[ Thread que destrói instâncias de tracking vehicles que terminaram a rota. ]]

local monitorRunning = false

local function cleanFinishedInstances()
    local instances = GetAllTrackingVehiclesInstances()
    for _, routeInstances in pairs(instances) do
        for instanceKey, instance in pairs(routeInstances) do
            if not instance.destroyed and instance:isVehicleFinishedRoute() then
                instance:destroy()
                routeInstances[instanceKey] = nil
            end
        end
    end
end

local function startMonitor()
    if monitorRunning then return end
    Citizen.CreateThread(function()
        monitorRunning = true
        local ok, err = pcall(function()
            while monitorRunning and IsEnabledMultiTracking() do
                cleanFinishedInstances()
                Wait(100)
            end
        end)
        if not ok then
            print("^3 multi_tracking:vehicle:client:monitor - error: " .. tostring(err) .. "^0")
        end
        monitorRunning = false
    end)
end

AddEventHandler("multiTracking:client:npcKilled", function(killedPed)
    if not killedPed then return end
    local instances = GetAllTrackingVehiclesInstances()
    for _, routeInstances in pairs(instances) do
        for instanceKey, instance in pairs(routeInstances) do
            if not instance.destroyed and instance.ped == killedPed then
                instance:destroy()
                routeInstances[instanceKey] = nil
                return
            end
        end
    end
end)

AddEventHandler("multiTracking:whenEnter", function()
    CreateAllVehicleRouteBlips()
    startMonitor()
end)

AddEventHandler("multiTracking:whenLeave", function()
    monitorRunning = false
end)
