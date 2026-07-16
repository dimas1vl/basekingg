--[[ Lifecycle do modo "roll": peds em rooftops que tocam combat roll. ]]

local isChecking = false

AddEventHandler("multiTracking:roll:client:checkNpcs", function()
    if isChecking then return end
    isChecking = true

    local ok, err = pcall(function()
        while isChecking and IsEnabledMultiTracking() do
            CheckRollTrackingNpcs()
            Wait(250)
        end
    end)

    if not ok then
        print("^3 multi_tracking:roll:client:checkNpcs - error: " .. tostring(err) .. "^0")
    end

    isChecking = false
end)

AddEventHandler("multiTracking:whenEnter", function()
    if isChecking then return end
    TriggerEvent("multiTracking:roll:client:checkNpcs")
    TriggerEvent("multiTracking:roll:client:monitorNpcs")
end)

AddEventHandler("multiTracking:whenLeave", function()
    isChecking = false
    DeleteAllRollTrackingNpcs()
end)
