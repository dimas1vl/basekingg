--[[ Lifecycle do modo parachute: thread de check de peds. ]]

local isCheckingPeds = false
local pedsController = MultiTrackingGetPedsController("parachute")

AddEventHandler("multiTracking:client:checkPeds", function()
    if isCheckingPeds then return end
    isCheckingPeds = true

    local ok, err = pcall(function()
        while isCheckingPeds and IsEnabledMultiTracking() do
            CheckTrackinParachutePeds()
            Wait(250)
        end
    end)
    if not ok then
        print("^3 multi_tracking:client:checkPeds - error: " .. tostring(err) .. "^0")
    end

    isCheckingPeds = false
end)

AddEventHandler("multiTracking:whenEnter", function()
    if isCheckingPeds then return end
    TriggerEvent("multiTracking:client:checkPeds")
end)

AddEventHandler("multiTracking:whenLeave", function()
    isCheckingPeds = false
    pedsController:deleteAll()
end)
