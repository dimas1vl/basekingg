DomSettings = nil
settingsOpen = false

local KVP_KEY = 'dom:settings'
local AMBIENT_SCENE = 'CHARACTER_CHANGE_IN_SKY_SCENE'
local MUTE_SCENE = 'FBI_HEIST_H5_MUTE_AMBIENCE_SCENE'
local FS_FOOTSTEP_EVENTS = 0x0653B735BFBDFE87
local FS_CLOTH_EVENTS    = 0x29DA3CA8D8B2692D

local DEFAULTS = {
    hud = {
        hotbar      = { 'fuzil', 'sub', 'pistola', 'faca' },
        announces   = true,
        progressBar = true,
        dmgMarker   = true,
        dmgColor    = { 255, 80, 80 },
        killMarker  = true,
        killColor   = { 255, 255, 255 },
        hideHealth  = false,
        hideWeapon  = false,
        hideMinimap = false,
        hideKillfeed = false,
        hideCompass = false,
        hideStats   = false,
        hideHints   = false,
        hideHotbar  = false,
        hideLevel   = false,
    },
    audio = {
        saque     = { effect = 'default', volume = 70 },
        hit       = { effect = 'default', volume = 70 },
        kill      = { effect = 'default', volume = 70 },
        ping      = { effect = 'default', volume = 70 },
        ambient   = false,
        footsteps = 'noteam',
    },
    game = {
        timeOverride    = false,
        hour            = 12,
        minute          = 0,
        weatherOverride = false,
        weather         = 'EXTRASUNNY',
    },
}

local WEATHERS = {
    EXTRASUNNY = true, CLEAR = true, CLOUDS = true, OVERCAST = true,
    RAIN = true, THUNDER = true, CLEARING = true, NEUTRAL = true,
    SMOG = true, FOGGY = true, XMAS = true, SNOWLIGHT = true,
    BLIZZARD = true, SNOW = true, HALLOWEEN = true,
}

---@param dst table
---@param src table
local function deepMerge(dst, src)
    for k, v in pairs(src) do
        if type(v) == 'table' and type(dst[k]) == 'table' then
            deepMerge(dst[k], v)
        elseif dst[k] == nil then
            if type(v) == 'table' then
                local t = {}
                deepMerge(t, v)
                dst[k] = t
            else
                dst[k] = v
            end
        end
    end
end

---@return table
local function copyDefaults()
    local t = {}
    deepMerge(t, DEFAULTS)
    return t
end

local function loadSettings()
    local raw = GetResourceKvpString(KVP_KEY)
    local ok, decoded = pcall(function() return raw and json.decode(raw) or nil end)
    local s = (ok and type(decoded) == 'table') and decoded or {}
    deepMerge(s, DEFAULTS)
    DomSettings = s
end

local function persist()
    SetResourceKvp(KVP_KEY, json.encode(DomSettings))
end

function pushSettings()
    SendNUIMessage({ action = 'settings', data = DomSettings })
end

---@param keyNum number
---@return number slot
function domHotbarSlot(keyNum)
    local cat = DomSettings and DomSettings.hud and DomSettings.hud.hotbar and DomSettings.hud.hotbar[keyNum]
    if cat then
        local c = Config.Domination.getCategory(cat)
        if c then return c.slot end
    end
    return keyNum
end

---@param slot number
---@return number keyNum
function domSlotToKey(slot)
    local order = DomSettings and DomSettings.hud and DomSettings.hud.hotbar
    if order then
        for k = 1, 4 do
            local c = Config.Domination.getCategory(order[k])
            if c and c.slot == slot then return k end
        end
    end
    return slot
end

local function applyAmbient()
    if not DomSettings then return end
    if Zone.active and DomSettings.audio.ambient == false then
        if not IsAudioSceneActive(AMBIENT_SCENE) then StartAudioScene(AMBIENT_SCENE) end
        if not IsAudioSceneActive(MUTE_SCENE) then StartAudioScene(MUTE_SCENE) end
        SetAudioFlag('PoliceScannerDisabled', true)
    else
        if IsAudioSceneActive(AMBIENT_SCENE) then StopAudioScene(AMBIENT_SCENE) end
        if IsAudioSceneActive(MUTE_SCENE) then StopAudioScene(MUTE_SCENE) end
        SetAudioFlag('PoliceScannerDisabled', false)
    end
end

---@param ped number
---@param silent boolean
local function fsApply(ped, silent)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    Citizen.InvokeNative(FS_FOOTSTEP_EVENTS, ped, not silent)
    Citizen.InvokeNative(FS_CLOTH_EVENTS, ped, not silent)
end

local function applyFootsteps()
    if not DomSettings or not Zone.active then return end
    local mode = DomSettings.audio.footsteps or 'noteam'
    local mySrc = GetPlayerServerId(PlayerId())
    local myPed = PlayerPedId()

    if myPed ~= 0 then
        fsApply(myPed, mode == 'noown' or mode == 'noteam')
    end

    for _, pid in ipairs(GetActivePlayers()) do
        local ssrc = GetPlayerServerId(pid)
        if ssrc ~= mySrc then
            local ped = GetPlayerPed(pid)
            if ped ~= 0 and DoesEntityExist(ped) then
                local mate = (domIsTeammate and domIsTeammate(ssrc)) or false
                fsApply(ped, (mode == 'noteam' and mate) and true or false)
            end
        end
    end
end

local function applyTime()
    if not DomSettings or not Zone.active then return end
    if DomSettings.game.timeOverride then
        NetworkOverrideClockTime(DomSettings.game.hour or 12, DomSettings.game.minute or 0, 0)
    else
        NetworkClearClockTimeOverride()
    end
end

local function applyWeather()
    if not DomSettings or not Zone.active then return end
    local g = DomSettings.game
    if g.weatherOverride and WEATHERS[g.weather] then
        SetWeatherTypeNowPersist(g.weather)
        SetOverrideWeather(g.weather)
    else
        ClearOverrideWeather()
        ClearWeatherTypePersist()
    end
end

local function clearTimeWeather()
    NetworkClearClockTimeOverride()
    ClearOverrideWeather()
    ClearWeatherTypePersist()
end

function applyMinimap()
    if Zone.active and DomSettings and DomSettings.hud and DomSettings.hud.hideMinimap then
        DisplayRadar(false)
    else
        DisplayRadar(true)
    end
end

function applySettings()
    if not DomSettings then return end
    pushSettings()
    applyAmbient()
    applyFootsteps()
    applyTime()
    applyWeather()
    applyMinimap()
    if Zone.active and publishWeapons then publishWeapons() end
end

function settingsCleanup()
    if IsAudioSceneActive(AMBIENT_SCENE) then StopAudioScene(AMBIENT_SCENE) end
    if IsAudioSceneActive(MUTE_SCENE) then StopAudioScene(MUTE_SCENE) end
    SetAudioFlag('PoliceScannerDisabled', false)
    clearTimeWeather()
    local myPed = PlayerPedId()
    if myPed ~= 0 then
        Citizen.InvokeNative(FS_FOOTSTEP_EVENTS, myPed, true)
        Citizen.InvokeNative(FS_CLOTH_EVENTS, myPed, true)
    end
    for _, pid in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(pid)
        if ped ~= 0 and DoesEntityExist(ped) then
            Citizen.InvokeNative(FS_FOOTSTEP_EVENTS, ped, true)
            Citizen.InvokeNative(FS_CLOTH_EVENTS, ped, true)
        end
    end
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    local myPed = PlayerPedId()
    if myPed ~= 0 then
        Citizen.InvokeNative(FS_FOOTSTEP_EVENTS, myPed, true)
        Citizen.InvokeNative(FS_CLOTH_EVENTS, myPed, true)
    end
    for _, pid in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(pid)
        if ped ~= 0 and DoesEntityExist(ped) then
            Citizen.InvokeNative(FS_FOOTSTEP_EVENTS, ped, true)
            Citizen.InvokeNative(FS_CLOTH_EVENTS, ped, true)
        end
    end
end)

function setSettingsOpen(open)
    open = open and true or false
    if open == settingsOpen then return end
    settingsOpen = open
    if settingsOpen then
        if hubOpen then setHubOpen(false) end
        if shopOpen then setShopOpen(false) end
        if spawnOpen then setSpawnOpen(false) end
        if vehiclesOpen then setVehiclesOpen(false) end
        SetNuiFocus(true, true)
        pushSettings()
        SendNUIMessage({ action = 'settings:visible', value = true })
    else
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'settings:visible', value = false })
    end
end

RegisterNUICallback('settings:save', function(data, cb)
    if type(data) == 'table' then
        deepMerge(data, DEFAULTS)
        DomSettings = data
        persist()
        applySettings()
    end
    cb({ ok = true })
end)

RegisterNUICallback('settings:close', function(_, cb)
    setSettingsOpen(false)
    cb({ ok = true })
end)

RegisterCommand('domination:settings', function()
    if not Zone.active or respawning then return end
    setSettingsOpen(not settingsOpen)
end, false)
RegisterKeyMapping('domination:settings', '[DOMINATION] Configurações', 'keyboard', 'F6')

CreateThread(function()
    while true do
        if Zone.active then
            applyAmbient()
            if DomSettings then
                if DomSettings.hud.hideMinimap then DisplayRadar(false) end
                if DomSettings.game.timeOverride then
                    NetworkOverrideClockTime(DomSettings.game.hour or 12, DomSettings.game.minute or 0, 0)
                end
                if DomSettings.game.weatherOverride and WEATHERS[DomSettings.game.weather] then
                    SetWeatherTypeNowPersist(DomSettings.game.weather)
                end
            end
            Wait(2000)
        else
            Wait(1500)
        end
    end
end)

CreateThread(function()
    while true do
        if Zone.active and DomSettings then
            applyFootsteps()
            Wait(0)
        else
            Wait(500)
        end
    end
end)

loadSettings()
