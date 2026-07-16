--[[ Bridge entre o matchmaking do kingg e o multi-tracking. ]]

local function preloadAllVehicleModels()
    local routes = MultitrackingModeVehicleRoutes and MultitrackingModeVehicleRoutes.routes
    if type(routes) ~= 'table' then return end
    for _, route in pairs(routes) do
        local m = route and route.vehicleModel
        if m then
            CreateThread(function()
                local h = (type(m) == 'string') and GetHashKey(m) or m
                if not HasModelLoaded(h) then
                    RequestModel(h)
                    local n = 0
                    while not HasModelLoaded(h) and n < 100 do Wait(50); n = n + 1 end
                end
            end)
        end
    end
end

RegisterNetEvent('tracking:enter', function()
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)

    if PreloadAllTrackingPedModels then PreloadAllTrackingPedModels() end
    preloadAllVehicleModels()

    SetEnabledMultiTracking(true)
end)

RegisterNetEvent('tracking:leave', function()
    SetEnabledMultiTracking(false)

    if FullTrackingVehicleCleanup then
        pcall(FullTrackingVehicleCleanup)
    end

    local ped = PlayerPedId()
    RemoveAllPedWeapons(ped, true)

    local ok = pcall(function() exports.lobby:displayLobby() end)
    if not ok then
        DoScreenFadeIn(600)
    end
end)
