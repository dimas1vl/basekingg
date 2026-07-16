--[[ Lifecycle do modo "area": peds em zonas fixas com lifetime. ]]

local isChecking = false

AddEventHandler("multiTracking:area:client:checkNpcs", function()
    if isChecking then return end
    isChecking = true

    local ok, err = pcall(function()
        while isChecking and IsEnabledMultiTracking() do
            CheckAreaTrackingNpcs()
            Wait(250)
        end
    end)

    if not ok then
        print("^3 multi_tracking:area:client:checkNpcs - error: " .. tostring(err) .. "^0")
    end

    isChecking = false
end)

AddEventHandler("multiTracking:whenEnter", function()
    if isChecking then return end
    TriggerEvent("multiTracking:area:client:checkNpcs")
    TriggerEvent("multiTracking:area:client:monitorNpcs")
end)

AddEventHandler("multiTracking:whenLeave", function()
    isChecking = false
    DeleteAllAreaTrackingNpcs()
end)
