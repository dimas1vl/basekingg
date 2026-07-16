--[[ Minimapa controlado por mapBlipsEnabled (toggle F7). ]]

---@return boolean
local function blipsEnabled()
    local cfg = GetGlobalConfigBuilder and GetGlobalConfigBuilder('general')
    if not (cfg and cfg.get) then return false end
    return cfg.get('mapBlipsEnabled') == true
end

AddEventHandler('multiTracking:whenEnter', function()
    DisplayRadar(blipsEnabled())
end)

AddEventHandler('multiTracking:whenLeave', function()
    DisplayRadar(false)
end)

AddEventHandler('multiTracking:blips:changed', function(enabled)
    if not IsEnabledMultiTracking() then return end
    DisplayRadar(enabled and true or false)
end)
