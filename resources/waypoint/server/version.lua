local config = require 'config'

if not config.server.versionCheckEnabled then
    return
end

local resourceName = GetCurrentResourceName()
local currentVersion = GetResourceMetadata(resourceName, 'version', 0)

local function normalizeVersion(version)
    if not version or version == '' then
        return {}
    end

    version = version:gsub('^v', '')

    local parts = {}
    for part in version:gmatch('%d+') do
        parts[#parts + 1] = tonumber(part) or 0
    end

    return parts
end

local function isOutdated(current, latest)
    local currentParts = normalizeVersion(current)
    local latestParts = normalizeVersion(latest)
    local count = math.max(#currentParts, #latestParts)

    for index = 1, count do
        local currentValue = currentParts[index] or 0
        local latestValue = latestParts[index] or 0

        if currentValue < latestValue then
            return true
        end

        if currentValue > latestValue then
            return false
        end
    end

    return false
end

CreateThread(function()
    PerformHttpRequest('https://api.github.com/repos/Sleepless-Development/sleepless_waypoints/releases/latest', function(statusCode, body)
        if statusCode ~= 200 or not body then
            return
        end

        local ok, payload = pcall(json.decode, body)
        if not ok or type(payload) ~= 'table' then
            return
        end

        local latestVersion = payload.tag_name or payload.name
        if type(latestVersion) ~= 'string' or latestVersion == '' then
            return
        end

        if currentVersion and isOutdated(currentVersion, latestVersion) then
            print(('[%s] Update available: current=%s latest=%s'):format(resourceName, currentVersion, latestVersion))
        end
    end, 'GET', '', {
        ['User-Agent'] = resourceName
    })
end)
