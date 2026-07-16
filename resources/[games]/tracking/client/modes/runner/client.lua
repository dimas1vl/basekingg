--[[ Lifecycle do modo "runner": peds correndo entre dois pontos. ]]

local isChecking = false

AddEventHandler("multiTracking:runner:client:checkNpcs", function()
    if isChecking then return end
    isChecking = true

    local ok, err = pcall(function()
        while isChecking and IsEnabledMultiTracking() do
            CheckRunnerTrackingNpcs()
            Wait(300)
        end
    end)

    if not ok then
        print("^3 multi_tracking:runner:client:checkNpcs - error: " .. tostring(err) .. "^0")
    end

    isChecking = false
end)

AddEventHandler("multiTracking:whenEnter", function()
    if isChecking then return end
    TriggerEvent("multiTracking:runner:client:checkNpcs")
    TriggerEvent("multiTracking:runner:client:monitorNpcs")
    TriggerEvent("multiTracking:runner:client:startRollThread")
end)

AddEventHandler("multiTracking:whenLeave", function()
    isChecking = false
end)
