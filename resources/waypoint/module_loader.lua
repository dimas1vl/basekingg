local moduleCache = {}

---@param moduleName string
---@return string
local function moduleNameToPath(moduleName)
    return ('%s.lua'):format(moduleName:gsub('%.', '/'))
end

---@param moduleName string
---@return any
local function resourceRequire(moduleName)
    if moduleCache[moduleName] ~= nil then
        return moduleCache[moduleName]
    end

    local resourceName = GetCurrentResourceName()
    local modulePath = moduleNameToPath(moduleName)
    local source = LoadResourceFile(resourceName, modulePath)

    if not source then
        error(("module '%s' not found"):format(moduleName), 2)
    end

    local chunk, loadError = load(source, ('@@%s/%s'):format(resourceName, modulePath), 't')
    if not chunk then
        error(loadError, 2)
    end

    local result = chunk()
    if result == nil then
        result = true
    end

    moduleCache[moduleName] = result
    return result
end

require = resourceRequire
