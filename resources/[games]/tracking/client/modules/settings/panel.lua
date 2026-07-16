--[[ Painel F7 (config) + Status HUD (canto superior esquerdo). ]]

local CATEGORIES = { 'general', 'vehicles', 'parachute', 'runner', 'roll', 'area', 'weather' }
local panelOpen = false

---@param category string
---@return table|nil
local function getBuilder(category)
    if type(GetGlobalConfigBuilder) ~= 'function' then return nil end
    return GetGlobalConfigBuilder(category)
end

---@return table
local function collectConfig()
    local out = {}
    for i = 1, #CATEGORIES do
        local cat = CATEGORIES[i]
        local builder = getBuilder(cat)
        if builder then
            out[cat] = {}
            local keys = ({
                general   = { 'mapBlipsEnabled', 'spawnBlipsEnabled', 'hitmarkerEnabled' },
                vehicles  = { 'vehicleSpawnEnabled', 'maxGenerateVehicles', 'driveSpeedMultiplier', 'spawnCooldownMs' },
                parachute = { 'enabled', 'maxGeneratePeds', 'spawnCooldownMs' },
                runner    = { 'maxGeneratePeds', 'runSpeed', 'spawnCooldownMs', 'aimRollEnabled' },
                roll      = { 'maxGeneratePeds', 'spawnCooldownMs' },
                area      = { 'maxGeneratePeds', 'pedLifetimeMs' },
                weather   = { 'overrideHour', 'hour', 'overrideWeather', 'weather' },
            })[cat] or {}
            for _, k in ipairs(keys) do
                out[cat][k] = builder.get(k)
            end
        end
    end
    return out
end

local function openPanel()
    if panelOpen then return end
    if not IsEnabledMultiTracking() then return end
    panelOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'showConfig', data = collectConfig() })
end

local function closePanel()
    if not panelOpen then return end
    panelOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideConfig' })
end

local function togglePanel()
    if panelOpen then closePanel() else openPanel() end
end

RegisterCommand('+tracking_config', function() togglePanel() end, false)
RegisterCommand('-tracking_config', function() end, false)
RegisterKeyMapping('+tracking_config', 'Painel de configuração do Tracking', 'keyboard', 'F7')

RegisterCommand('trackingconfig', function() togglePanel() end, false)

RegisterNUICallback('closeConfig', function(_, cb)
    closePanel()
    cb({ ok = true })
end)

RegisterNUICallback('setConfig', function(data, cb)
    cb = cb or function() end
    if type(data) ~= 'table' then cb({ ok = false }); return end
    local builder = getBuilder(data.category)
    if not builder then cb({ ok = false, error = 'no_builder' }); return end
    builder.set(data.key, data.value)

    if data.category == 'general' then
        if data.key == 'mapBlipsEnabled' and SetMapBlipsEnabled then
            SetMapBlipsEnabled(data.value == true)
        elseif data.key == 'spawnBlipsEnabled' and SetSpawnBlipsEnabled then
            SetSpawnBlipsEnabled(data.value == true)
        end
    elseif data.category == 'vehicles' then
        if data.key == 'vehicleSpawnEnabled' and data.value == false then
            TriggerEvent('multiTracking:vehicle:client:spawnDisabled')
        elseif data.key == 'driveSpeedMultiplier' then
            TriggerEvent('multiTracking:vehicle:client:refreshPlaybackSpeed')
        elseif data.key == 'maxGenerateVehicles' then
            TriggerEvent('multiTracking:vehicle:client:refreshLimit')
        end
    elseif data.category == 'weather' then
        TriggerEvent('multiTracking:weather:client:apply')
    end

    cb({ ok = true })
end)

AddEventHandler('multiTracking:whenLeave', function()
    if panelOpen then closePanel() end
end)

----------------------------------------------------------------------
-- Status HUD (canto superior esquerdo)
----------------------------------------------------------------------

local statusVisible = false
local statusThreadId = 0

---@param key string
---@return number
local function pedControllerCount(key)
    if type(MultiTrackingGetPedsController) ~= 'function' then return 0 end
    local ctrl = MultiTrackingGetPedsController(key)
    if not ctrl or not ctrl.getTrackedCount then return 0 end
    local ok, n = pcall(function() return ctrl:getTrackedCount() end)
    if ok and tonumber(n) then return n end
    return 0
end

---@param category string
---@param keys     string[]
---@return table
local function readSection(category, keys)
    local b = getBuilder(category)
    if not b or not b.get then return {} end
    local out = {}
    for _, k in ipairs(keys) do out[k] = b.get(k) end
    return out
end

---@param fnName string
---@return boolean
local function hasEligibleZones(fnName)
    local f = rawget(_G, fnName)
    if type(f) ~= 'function' then return false end
    local ok, list = pcall(f)
    return ok and type(list) == 'table' and #list > 0
end

---@return table
local function readStatusSnapshot()
    local vehCfg = readSection('vehicles', {
        'maxGenerateVehicles', 'driveSpeedMultiplier', 'spawnCooldownMs', 'vehicleSpawnEnabled'
    })
    local vehActive = 0
    if GetActiveTrackingVehiclesCount then
        vehActive = GetActiveTrackingVehiclesCount() or 0
    end

    local paraCfg = readSection('parachute', { 'maxGeneratePeds', 'spawnCooldownMs', 'enabled' })
    local runCfg  = readSection('runner',    { 'maxGeneratePeds', 'spawnCooldownMs', 'runSpeed' })
    local rollCfg = readSection('roll',      { 'maxGeneratePeds', 'spawnCooldownMs' })
    local areaCfg = readSection('area',      { 'maxGeneratePeds', 'pedLifetimeMs' })

    local paraActive = pedControllerCount('parachute')
    local runActive  = pedControllerCount('runner')
    local rollActive = pedControllerCount('roll')
    local areaActive = pedControllerCount('area')

    return {
        vehicles = {
            active      = vehActive,
            max         = tonumber(vehCfg.maxGenerateVehicles)  or 5,
            speedMul    = tonumber(vehCfg.driveSpeedMultiplier) or 1.0,
            intervalMs  = tonumber(vehCfg.spawnCooldownMs)      or 1000,
            enabled     = vehCfg.vehicleSpawnEnabled ~= false,
            eligible    = hasEligibleZones('GetVehicleEligibleRoutes') or vehActive > 0,
        },
        parachute = {
            active     = paraActive,
            max        = tonumber(paraCfg.maxGeneratePeds) or 6,
            intervalMs = tonumber(paraCfg.spawnCooldownMs) or 2000,
            enabled    = paraCfg.enabled ~= false,
            eligible   = paraCfg.enabled ~= false,
        },
        runner = {
            active     = runActive,
            max        = tonumber(runCfg.maxGeneratePeds) or 4,
            speed      = tonumber(runCfg.runSpeed)        or 3.0,
            intervalMs = tonumber(runCfg.spawnCooldownMs) or 1500,
            eligible   = hasEligibleZones('GetRunnerEligibleZones'),
        },
        roll = {
            active     = rollActive,
            max        = tonumber(rollCfg.maxGeneratePeds) or 6,
            intervalMs = tonumber(rollCfg.spawnCooldownMs) or 1500,
            eligible   = hasEligibleZones('GetRollEligibleZones'),
        },
        area = {
            active     = areaActive,
            max        = tonumber(areaCfg.maxGeneratePeds) or 6,
            lifetimeMs = tonumber(areaCfg.pedLifetimeMs)   or 12000,
            eligible   = hasEligibleZones('GetAreaEligibleZones'),
        },
    }
end

local function pushStatus()
    if not statusVisible then return end
    SendNUIMessage({ action = 'statusUpdate', data = readStatusSnapshot() })
end

local function startStatusLoop()
    statusThreadId = statusThreadId + 1
    local myId = statusThreadId
    CreateThread(function()
        while statusVisible and myId == statusThreadId do
            pushStatus()
            Wait(500)
        end
    end)
end

AddEventHandler('multiTracking:whenEnter', function()
    statusVisible = true
    SendNUIMessage({ action = 'statusShow', data = readStatusSnapshot() })
    startStatusLoop()
end)

AddEventHandler('multiTracking:whenLeave', function()
    statusVisible = false
    statusThreadId = statusThreadId + 1
    SendNUIMessage({ action = 'statusHide' })
end)

AddEventHandler('multiTracking:vehicle:client:refreshPlaybackSpeed', pushStatus)
AddEventHandler('multiTracking:vehicle:client:refreshLimit',         pushStatus)
AddEventHandler('multiTracking:vehicle:client:spawnDisabled',        pushStatus)
