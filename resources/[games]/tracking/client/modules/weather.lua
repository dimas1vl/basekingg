--[[ Override LOCAL de clima/horário no tracking. NetworkOverrideClockTime
     + SetWeatherType* não sincronizam com outros players. ]]

local active   = false
local threadId = 0

---@param category string
---@return table|nil
local function getBuilder(category)
    if type(GetGlobalConfigBuilder) ~= 'function' then return nil end
    return GetGlobalConfigBuilder(category)
end

---@return table
local function readConfig()
    local b = getBuilder('weather')
    if not b then
        return { overrideHour = false, hour = 12, overrideWeather = false, weather = 'EXTRASUNNY' }
    end
    return {
        overrideHour    = b.get('overrideHour') == true,
        hour            = math.floor(tonumber(b.get('hour')) or 12),
        overrideWeather = b.get('overrideWeather') == true,
        weather         = tostring(b.get('weather') or 'EXTRASUNNY'),
    }
end

local function apply()
    if not active then return end
    local cfg = readConfig()

    if cfg.overrideHour then
        local h = math.max(0, math.min(23, cfg.hour))
        NetworkOverrideClockTime(h, 0, 0)
    else
        NetworkClearClockTimeOverride()
    end

    if cfg.overrideWeather then
        ClearOverrideWeather()
        SetWeatherTypeNowPersist(cfg.weather)
        SetWeatherTypePersist(cfg.weather)
        SetWeatherTypeNow(cfg.weather)
    else
        ClearWeatherTypePersist()
        ClearOverrideWeather()
    end
end

local function startThread()
    threadId = threadId + 1
    local myId = threadId
    CreateThread(function()
        while active and myId == threadId do
            apply()
            Wait(5000)
        end
    end)
end

AddEventHandler('multiTracking:whenEnter', function()
    active = true
    apply()
    startThread()
end)

AddEventHandler('multiTracking:whenLeave', function()
    active = false
    threadId = threadId + 1
    NetworkClearClockTimeOverride()
    ClearWeatherTypePersist()
    ClearOverrideWeather()
end)

AddEventHandler('multiTracking:weather:client:apply', apply)
