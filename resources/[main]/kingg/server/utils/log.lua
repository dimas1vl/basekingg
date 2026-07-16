local eLogTypes = {
    info = 1 << 0,
    warning = 1 << 1,
    error = 1 << 2,
    critical = 1 << 3,
}

local DEV_MASK  = eLogTypes.info | eLogTypes.warning | eLogTypes.error | eLogTypes.critical
local PROD_MASK = eLogTypes.error | eLogTypes.critical

_G.log = log
function log(type, message)
    local enabled = _G.devMode and DEV_MASK or PROD_MASK
    local flag = eLogTypes[type]
    if not flag or (enabled & flag) == 0 then
        return
    end
    local ts = os.date('%H:%M:%S')
    local typeColor = '^5'
    if type == 'error' then
        typeColor = '^1'
    elseif type == 'warning' then
        typeColor = '^3'
    elseif type == 'critical' then
        typeColor = '^1'
    end
    print(('[^1%s^7] %s%s^7: %s'):format(ts, typeColor, type, message))
end