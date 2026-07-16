--[[ Estado global do modo MultiTracking.
     Controla entrada/saida no modo, integracao com tips,
     e flags de configuracao (blips do mapa / spawn). ]]

local configBuilder = GetGlobalConfigBuilder("general")
local enabled = false

MultiTrackingActiveDebug = false

local function updateKeyPressMonitor()
    if enabled then
        TriggerEvent("multiTracking:keyPressMonitor:client:start")
    else
        DeleteAllCannonImpulseInstances()
        TriggerEvent("multiTracking:keyPressMonitor:client:stop")
    end
end

local function updateTipsIntegration()
    if GetResourceState("tips") ~= "started" then return end

    if enabled then
        exports.tips:hiddeTips(nil, true)
        exports.tips:activeTipsToMode("multiTracking")
    else
        exports.tips:hiddeTips("multiTracking")
    end
end

local function setEnabledMultiTracking(value)
    local newValue = value and true or false
    if enabled == newValue then return end

    enabled = newValue

    if enabled then
        TriggerEvent("multiTracking:whenEnter")
        TriggerEvent("multiTracking:randomSpawnPlayer")
    else
        TriggerEvent("multiTracking:whenLeave")
    end

    updateKeyPressMonitor()
    updateTipsIntegration()
end
SetEnabledMultiTracking = setEnabledMultiTracking

local function isEnabledMultiTracking()
    return enabled
end
IsEnabledMultiTracking = isEnabledMultiTracking

local function isMapBlipsEnabled()
    if not configBuilder then return false end
    return configBuilder.get("mapBlipsEnabled") == true
end
IsMapBlipsEnabled = isMapBlipsEnabled

local function setMapBlipsEnabled(value)
    if not configBuilder then return end
    configBuilder.set("mapBlipsEnabled", value == true)
    TriggerEvent("multiTracking:blips:changed", value == true)
end
SetMapBlipsEnabled = setMapBlipsEnabled

local function isSpawnBlipsEnabled()
    if not configBuilder then return true end
    local v = configBuilder.get("spawnBlipsEnabled")
    if v == nil then return true end
    return v == true
end
IsSpawnBlipsEnabled = isSpawnBlipsEnabled

local function setSpawnBlipsEnabled(value)
    if not configBuilder then return end
    configBuilder.set("spawnBlipsEnabled", value == true)
    TriggerEvent("multiTracking:spawnBlips:changed", value == true)
end
SetSpawnBlipsEnabled = setSpawnBlipsEnabled

-- Compat: entry point preserved. Now this just defers to the matchmaking flow
-- (player should pick "Rolamento com Bots + Tracking" in the lobby UI).
-- Triggers the server-side join via the lobby NUI handler.
exports("enterMultiTrackingMode", function()
    TriggerServerEvent('net.lobby:joinQueue', {
        category = 'treinamento',
        submode  = 'rolamento-com-bots--tracking',
    })
end)
