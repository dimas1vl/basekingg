local RESOURCE = GetCurrentResourceName()
local cfg = Config.DriveBy

MC = MatchClient.new()

local gDeathReported       = false
local gSpawnProtectId      = 0
local gHudActive           = false
local gHudThreadId         = 0
local gControlBlockThread  = 0
local gLockInCarThread     = 0
local gScoreboardOpen      = false
local gVictimHealthCache   = {}

---@type number
local gCurrentVehicle = 0

---@type { coords: vector3, heading: number } | nil
local gLastSpawn = nil

local BLOCKED_CONTROLS = {
    0, 23, 27, 37, 74, 75, 80,
    157, 158, 159, 160, 161, 162, 163, 164, 165,
}

local gCurrentSlot = 1

---@param visible boolean
local function showHud(visible)

    gHudActive = visible

    SendNUIMessage({ action = 'visible', value = visible })
end

---@param ped number
---@return string | nil weaponName, number clipAmmo
local function getCurrentWeaponInfo(ped)

    local _, hashOrZero = GetCurrentPedWeapon(ped, true)

    if not hashOrZero or hashOrZero == 0 then return nil, 0 end

    local weaponName

    for i = 1, #cfg.weapons do
        local w = cfg.weapons[i]
        if w.weapon and GetHashKey(w.weapon) == hashOrZero then
            weaponName = w.weapon
            break
        end
    end

    local _, clip = GetAmmoInClip(ped, hashOrZero)

    return weaponName, clip or 0
end

local function sendHudUpdate()

    if not gHudActive then return end

    local ped    = PlayerPedId()
    local health = math.max(0, GetEntityHealth(ped) - 100)
    local maxHp  = GetEntityMaxHealth(ped) - 100

    if maxHp <= 0 then maxHp = 100 end

    local armor = GetPedArmour(ped)

    local me, total = nil, 0

    if MC.scoreboard then

        total = #MC.scoreboard

        for i = 1, total do

            if MC.scoreboard[i].src == MC.selfSrc then
                me = MC.scoreboard[i]
                break
            end
        end
    end

    local weapon, ammo = getCurrentWeaponInfo(ped)
    local maxAmmo = 0

    local veh       = GetVehiclePedIsIn(ped, false)
    local inVehicle = veh ~= 0
    local speed     = inVehicle and math.floor(GetEntitySpeed(veh) * 3.6 + 0.5) or 0

    SendNUIMessage({
        action = 'hud',
        data = {
            hp        = health,
            hpMax     = maxHp,
            armor     = armor,
            armorMax  = 100,
            kills     = me and me.kills or 0,
            deaths    = me and me.deaths or 0,
            streak    = me and me.streak or 0,
            players   = total,
            ammo      = ammo,
            maxAmmo   = maxAmmo,
            weapon    = weapon,
            inVehicle = inVehicle,
            speed     = speed,
        },
    })
end

local function startHudThread()

    gHudThreadId = gHudThreadId + 1

    local myId = gHudThreadId
    local interval = cfg.hudUpdateMs or 500

    CreateThread(function()

        while gHudActive and myId == gHudThreadId do
            sendHudUpdate()
            Wait(interval)
        end
    end)
end

local function startControlBlockThread()

    gControlBlockThread = gControlBlockThread + 1

    local myId = gControlBlockThread

    CreateThread(function()

        while myId == gControlBlockThread and MC:isInMatch() do

            for i = 1, #BLOCKED_CONTROLS do
                DisableControlAction(0, BLOCKED_CONTROLS[i], true)
            end

            DisableControlAction(2, 23, true)
            DisableControlAction(2, 75, true)

            SetCinematicButtonActive(false)
            DisableFirstPersonCamThisFrame()
            SetFollowVehicleCamViewMode(1)

            Wait(0)
        end
    end)
end

local function publishWeaponsConfig()

    local slots = {}

    for i = 1, #cfg.weapons do
        local w = cfg.weapons[i]
        slots[#slots + 1] = { slot = w.slot, label = w.label, weapon = w.weapon }
    end

    SendNUIMessage({ action = 'weapons', data = { slots = slots, selected = gCurrentSlot } })
end

---@param slot integer
local function selectSlot(slot)

    if not MC:isInMatch() then return end

    local pick

    for i = 1, #cfg.weapons do
        if cfg.weapons[i].slot == slot then
            pick = cfg.weapons[i]
            break
        end
    end

    if not pick or not pick.weapon then return end

    local ped  = PlayerPedId()
    local hash = type(pick.weapon) == 'string' and GetHashKey(pick.weapon) or pick.weapon

    if not HasPedGotWeapon(ped, hash, false) then
        GiveWeaponToPed(ped, hash, pick.ammo or 9999, false, true)
    end

    SetCurrentPedWeapon(ped, hash, true)
    AddAmmoToPed(ped, hash, 9999)
    SetPedInfiniteAmmo(ped, true, hash)
    local _, maxClip = GetMaxAmmoInClip(ped, hash, true)
    SetAmmoInClip(ped, hash, maxClip and maxClip > 0 and maxClip or 30)
    gCurrentSlot = slot

    SendNUIMessage({ action = 'weapon', selected = slot, weapon = pick.weapon })
end

local function giveLoadout()

    local ped = PlayerPedId()
    NetworkSetFriendlyFireOption(true)
    SetCanAttackFriendly(ped, true, true)
    SetPlayerCanDoDriveBy(PlayerId(), true)
    SetPedCanSwitchWeapon(ped, true)
    SetPedCanRagdoll(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, false)
    SetPedDropsWeaponsWhenDead(ped, false)
    SetPedConfigFlag(ped, 100, true)   -- DisableShockingEvents off
    SetPedConfigFlag(ped, 122, false)  -- can attack while in vehicle
    SetPedConfigFlag(ped, 184, false)  -- can fire from vehicle

    RemoveAllPedWeapons(ped, true)

    for i = 1, #cfg.weapons do

        local w = cfg.weapons[i]

        if w.weapon then
            local hash = type(w.weapon) == 'string' and GetHashKey(w.weapon) or w.weapon
            GiveWeaponToPed(ped, hash, w.ammo or 9999, false, true)
            AddAmmoToPed(ped, hash, 9999)
            SetPedInfiniteAmmo(ped, true, hash)
            local _, maxClip = GetMaxAmmoInClip(ped, hash, true)
            SetAmmoInClip(ped, hash, maxClip and maxClip > 0 and maxClip or 30)

            if w.components then
                for j = 1, #w.components do
                    local comp = w.components[j]
                    local compHash = type(comp) == 'string' and GetHashKey(comp) or comp
                    GiveWeaponComponentToPed(ped, hash, compHash)
                end
            end

            TriggerEvent('kingg:player:weaponGiven', hash)
        end
    end

    gCurrentSlot = 1
    selectSlot(1)
end

---@param victim number
---@return number hp
---@return number armor
local function readVictimHpArmor(victim)

    local hp = GetEntityHealth(victim)
    local armor = 0

    if IsEntityAPed(victim) and IsPedAPlayer(victim) then
        armor = GetPedArmour(victim)
    end

    return hp, armor
end

local function despawnCurrentVehicle()

    if gCurrentVehicle ~= 0 and DoesEntityExist(gCurrentVehicle) then
        SetEntityAsMissionEntity(gCurrentVehicle, true, true)
        DeleteEntity(gCurrentVehicle)
    end

    gCurrentVehicle = 0
end

---@param coords vector3
---@param heading number
---@return number vehicleHandle
local function spawnVehicleAt(coords, heading)

    local hash = GetHashKey(cfg.vehicle.model)

    RequestModel(hash)

    local deadline = GetGameTimer() + 5000

    while not HasModelLoaded(hash) and GetGameTimer() < deadline do
        Wait(0)
    end

    if not HasModelLoaded(hash) then
        return 0
    end

    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, heading or 0.0, true, false)

    SetModelAsNoLongerNeeded(hash)
    SetVehicleOnGroundProperly(veh)
    SetVehicleEngineOn(veh, cfg.vehicle.engineOn == true, true, false)
    SetVehicleFuelLevel(veh, 100.0)

    if cfg.vehicle.primaryColor and cfg.vehicle.secondaryColor then
        SetVehicleColours(veh, cfg.vehicle.primaryColor, cfg.vehicle.secondaryColor)
    end

    if cfg.vehicle.locked then
        SetVehicleDoorsLocked(veh, 4)
        SetVehicleDoorsLockedForAllPlayers(veh, true)
    end

    TriggerEvent('kingg:player:vehicleEntered', veh)

    return veh
end

local function startLockInCarThread()

    gLockInCarThread = gLockInCarThread + 1

    local myId = gLockInCarThread

    CreateThread(function()

        while myId == gLockInCarThread and MC:isInMatch() do

            local ped = PlayerPedId()
            local veh = gCurrentVehicle

            SetPlayerCanDoDriveBy(PlayerId(), true)

            if veh ~= 0 and DoesEntityExist(veh) and not IsEntityDead(ped) then

                if GetVehiclePedIsIn(ped, false) ~= veh then
                    ClearPedTasksImmediately(ped)
                    local seat = IsVehicleSeatFree(veh, -1) and -1 or -2
                    SetPedIntoVehicle(ped, veh, seat)
                end
            end

            Wait(150)
        end
    end)
end

---@param coords vector3
---@param heading number
local function applySpawn(coords, heading)

    if not IsScreenFadedOut() then
        DoScreenFadeOut(200)
        while not IsScreenFadedOut() do Wait(0) end
    end

    local ped = PlayerPedId()

    if IsEntityDead(ped) then
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading or 0.0, true, false)
        Wait(50)
        ped = PlayerPedId()
    end

    despawnCurrentVehicle()

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    NewLoadSceneStart(coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 50.0, 0)

    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, true)
    SetEntityHeading(ped, heading or 0.0)
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true)

    local deadline = GetGameTimer() + 5000

    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < deadline do
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        Wait(50)
    end

    NewLoadSceneStop()

    SetEntityMaxHealth(ped, cfg.startHealth)
    SetEntityHealth(ped, cfg.startHealth)
    SetPedArmour(ped, cfg.startArmor)

    gCurrentVehicle = spawnVehicleAt(coords, heading)

    if gCurrentVehicle ~= 0 then
        SetPedIntoVehicle(ped, gCurrentVehicle, -1)
    end

    ClearPedTasksImmediately(ped)
    SetEntityInvincible(ped, false)
    SetPlayerInvincible(PlayerId(), false)
    SetPlayerCanDoDriveBy(PlayerId(), true)

    giveLoadout()

    SetPlayerInvincible(PlayerId(), true)
    gDeathReported = false
    gSpawnProtectId = gSpawnProtectId + 1

    local myProtect = gSpawnProtectId

    SetTimeout(cfg.spawnProtectionMs, function()
        if myProtect == gSpawnProtectId then
            SetPlayerInvincible(PlayerId(), false)
        end
    end)

    ShutdownLoadingScreen()
    DoScreenFadeIn(500)

    gLastSpawn = { coords = vec3(coords.x, coords.y, coords.z), heading = heading or 0.0 }

    TriggerEvent('kingg:player:spawned')
end

local gPvpWatchdogId = 0
local function startPvpWatchdog()
    gPvpWatchdogId = gPvpWatchdogId + 1
    local myId = gPvpWatchdogId
    CreateThread(function()
        while myId == gPvpWatchdogId and MC:isInMatch() do
            NetworkSetFriendlyFireOption(true)
            local ped = PlayerPedId()
            if ped and ped ~= 0 then
                SetCanAttackFriendly(ped, true, true)
            end
            Wait(100)
        end
    end)
end

MC:on('matchJoined', function(_, _, scoreboard)

    NetworkSetFriendlyFireOption(true)
    showHud(true)
    startHudThread()
    startControlBlockThread()
    startLockInCarThread()
    startPvpWatchdog()
    publishWeaponsConfig()

    SendNUIMessage({ action = 'scoreboard', data = scoreboard or {}, selfSrc = MC.selfSrc })
end)

---@param newState MatchState
MC:on('stateChanged', function(newState)

    SendNUIMessage({ action = 'state', value = newState })
end)

---@param coords vector3
---@param heading number
MC:on('spawn', function(coords, heading)

    applySpawn(coords, heading)
end)

MC:on('scoreboard', function(scoreboard)

    SendNUIMessage({ action = 'scoreboard', data = scoreboard, selfSrc = MC.selfSrc })
end)

MC:on('killFeed', function(entry)

    SendNUIMessage({ action = 'killFeed', data = entry, selfSrc = MC.selfSrc })
end)

MC:on('matchResult', function(result)

    SendNUIMessage({ action = 'result', data = result, selfSrc = MC.selfSrc })
end)

MC:on('matchEnded', function()

    showHud(false)
    gScoreboardOpen = false
    gSpawnProtectId = gSpawnProtectId + 1
    gLastSpawn = nil

    SetPlayerInvincible(PlayerId(), false)
    gVictimHealthCache = {}

    DoScreenFadeOut(400)
    Wait(400)

    local ped = PlayerPedId()

    SetEntityMaxHealth(ped, 200)
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 0)
    RemoveAllPedWeapons(ped, true)

    despawnCurrentVehicle()

    local ok = pcall(function() exports.lobby:displayLobby() end)

    if not ok then
        DoScreenFadeIn(600)
    end
end)

AddEventHandler('gameEventTriggered', function(eventName, args)

    if eventName ~= 'CEventNetworkEntityDamage' then return end
    if not MC:isInMatch() then return end

    local victim     = args[1]
    local attacker   = args[2]
    local victimDied = args[6]
    local weaponHash = args[7]

    local localPed = PlayerPedId()

    if attacker == localPed and victim and victim ~= 0 and victim ~= localPed and IsEntityAPed(victim) then

        local currHp, currArmor = readVictimHpArmor(victim)
        local prev = gVictimHealthCache[victim] or {
            hp    = cfg.startHealth or 200,
            armor = cfg.startArmor  or 100,
        }

        local damage = (prev.hp - currHp) + (prev.armor - currArmor)

        gVictimHealthCache[victim] = { hp = currHp, armor = currArmor }

        local lethal = (victimDied == 1 or victimDied == true)

        if damage > 0 and (lethal or damage <= 250) then

            local vc = GetEntityCoords(victim)
            local onScreen, sx, sy = World3dToScreen2d(vc.x, vc.y, vc.z + 0.6)

            if onScreen then

                local jitter = (math.random() - 0.5) * 0.03

                SendNUIMessage({
                    action = 'hitmarker',
                    data = {
                        x      = sx + jitter,
                        y      = sy,
                        damage = math.floor(damage + 0.5),
                        lethal = lethal,
                    },
                })
            end
        end
    end

    if victim == localPed and (victimDied == 1 or victimDied == true) and not gDeathReported then

        gDeathReported = true

        local killerSrc = 0

        if attacker and attacker ~= 0 and attacker ~= victim and IsPedAPlayer(attacker) then

            local killerPlayer = NetworkGetPlayerIndexFromPed(attacker)

            if killerPlayer and killerPlayer >= 0 then
                killerSrc = GetPlayerServerId(killerPlayer)
            end
        end

        MC:emitServer('playerDeath', killerSrc, weaponHash or 0)
    end
end)

local kmCfg = cfg.scoreboardKeyMapping

RegisterCommand('+' .. kmCfg.command, function()

    if not MC:isInMatch() or gScoreboardOpen then return end

    gScoreboardOpen = true

    if MC.scoreboard then
        SendNUIMessage({ action = 'scoreboard', data = MC.scoreboard, selfSrc = MC.selfSrc })
    end

    SendNUIMessage({ action = 'scoreboardVisible', value = true })
end, false)

RegisterCommand('-' .. kmCfg.command, function()

    if not gScoreboardOpen then return end

    gScoreboardOpen = false

    SendNUIMessage({ action = 'scoreboardVisible', value = false })
end, false)

RegisterKeyMapping('+' .. kmCfg.command, kmCfg.label, 'keyboard', kmCfg.key)

CreateThread(function()
    for i = 1, #cfg.weapons do
        local cmd = 'db_slot_' .. i
        RegisterCommand('+' .. cmd, function()
            selectSlot(i)
        end, false)
        RegisterCommand('-' .. cmd, function() end, false)
        RegisterKeyMapping('+' .. cmd, ('Slot %d (Drive-By)'):format(i), 'keyboard', tostring(i))
    end
end)

RegisterCommand('+db_reload', function()
    if not MC:isInMatch() then return end
    local ped = PlayerPedId()
    if IsEntityDead(ped) then return end
    local _, hash = GetCurrentPedWeapon(ped, true)
    if not hash or hash == 0 or hash == GetHashKey('WEAPON_UNARMED') then return end
    local _, maxClip = GetMaxAmmoInClip(ped, hash, true)
    SetAmmoInClip(ped, hash, maxClip or 30)
end, false)
RegisterCommand('-db_reload', function() end, false)
RegisterKeyMapping('+db_reload', 'Recarregar (Drive-By)', 'keyboard', 'R')

RegisterCommand('db_map', function()
    if not MC:isInMatch() then return end
    ActivateFrontendMenu(GetHashKey('FE_MENU_VERSION_SP_PAUSE'), false, -1)
end, false)
RegisterKeyMapping('db_map', 'Abrir mapa (Drive-By)', 'keyboard', 'M')


local LEAVE_HOLD_MS    = 2000
local leaveHoldActive  = false
local leaveHoldThread  = 0

local function startLeaveHold()
    if not MC:isInMatch() then return end
    if leaveHoldActive then return end

    leaveHoldActive  = true
    leaveHoldThread  = leaveHoldThread + 1
    local myId       = leaveHoldThread
    local startedAt  = GetGameTimer()

    SendNUIMessage({ action = 'leaveHold', visible = true, percent = 0, totalMs = LEAVE_HOLD_MS })

    CreateThread(function()
        while leaveHoldActive and myId == leaveHoldThread and MC:isInMatch() do
            local elapsed = GetGameTimer() - startedAt
            local pct     = math.min(100, math.floor((elapsed / LEAVE_HOLD_MS) * 100))
            SendNUIMessage({ action = 'leaveHold', visible = true, percent = pct, totalMs = LEAVE_HOLD_MS })
            if elapsed >= LEAVE_HOLD_MS then
                leaveHoldActive = false
                SendNUIMessage({ action = 'leaveHold', visible = false, percent = 0, totalMs = LEAVE_HOLD_MS })
                MC:emitServer('leaveMatch')
                return
            end
            Wait(50)
        end
        SendNUIMessage({ action = 'leaveHold', visible = false, percent = 0, totalMs = LEAVE_HOLD_MS })
    end)
end

local function cancelLeaveHold()
    if not leaveHoldActive then return end
    leaveHoldActive = false
    SendNUIMessage({ action = 'leaveHold', visible = false, percent = 0, totalMs = LEAVE_HOLD_MS })
end

RegisterCommand('+db_leave', startLeaveHold,  false)
RegisterCommand('-db_leave', cancelLeaveHold, false)
RegisterKeyMapping('+db_leave', 'Sair da partida (Drive-By)', 'keyboard', 'F')

AddEventHandler('onResourceStop', function(res)

    if res == RESOURCE then
        despawnCurrentVehicle()
    end
end)

-- ============================================================
-- Zona PVP
-- ============================================================

local SZ_DICT   = 'safezone'
local SZ_TEX    = 'kingg_safezone'
local SZ_HEIGHT = 1000.0
local SZ_COLOR  = { 100, 180, 255, 180 }

local Zone = {
    active        = false,
    center        = nil,
    radius        = 0.0,
    outsideKillMs = 1500,
    textureLoaded = false,
    outsideSince  = 0,
}

local function szLoadTexture()
    if Zone.textureLoaded then return end
    RequestStreamedTextureDict(SZ_DICT, true)
    local deadline = GetGameTimer() + 5000
    while not HasStreamedTextureDictLoaded(SZ_DICT) and GetGameTimer() < deadline do
        Wait(50)
    end
    Zone.textureLoaded = HasStreamedTextureDictLoaded(SZ_DICT)
end

local function szDrawMarker()
    local c = Zone.center
    if not c then return end

    local size = Zone.radius * 1.98412
    local rotZ = (GetGameTimer() * 0.001) % 360.0
    DrawMarker(
        1,
        c.x, c.y, c.z - 300.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, rotZ,
        size, size, SZ_HEIGHT,
        SZ_COLOR[1], SZ_COLOR[2], SZ_COLOR[3], SZ_COLOR[4],
        false, false, 2,
        false,
        SZ_DICT, SZ_TEX,
        false
    )
end

local function szTick()
    szLoadTexture()
    while Zone.active do
        szDrawMarker()
        Wait(0)
    end

    if Zone.textureLoaded then
        SetStreamedTextureDictAsNoLongerNeeded(SZ_DICT)
        Zone.textureLoaded = false
    end
end

local function szWatchdog()
    while Zone.active do
        Wait(400)

        if not Zone.active or not Zone.center then break end
        if not MC:isInMatch() then break end

        local ped = PlayerPedId()
        if IsEntityDead(ped) or gDeathReported then
            Zone.outsideSince = 0
        else
            local pc   = GetEntityCoords(ped)
            local c    = Zone.center
            local dist = #(vector3(pc.x, pc.y, pc.z) - vector3(c.x, c.y, c.z))

            if dist > Zone.radius then
                if Zone.outsideSince == 0 then
                    Zone.outsideSince = GetGameTimer()
                elseif GetGameTimer() - Zone.outsideSince >= Zone.outsideKillMs then
                    gDeathReported = true
                    SetEntityHealth(ped, 0)
                    MC:emitServer('playerDeath', 0, 0)
                    Zone.outsideSince = 0
                end
            else
                Zone.outsideSince = 0
            end
        end
    end
end

local function szStop()
    Zone.active = false
    Zone.center = nil
    Zone.outsideSince = 0
end

RegisterNetEvent('db:zone:start', function(data)
    if type(data) ~= 'table' then return end
    if Zone.active then return end

    Zone.active = true
    Zone.center = {
        x = tonumber(data.x) or 0.0,
        y = tonumber(data.y) or 0.0,
        z = tonumber(data.z) or 0.0,
    }
    Zone.radius        = tonumber(data.radius) or 200.0
    Zone.outsideKillMs = tonumber(data.outsideKillMs) or 1500
    Zone.outsideSince  = 0

    CreateThread(szTick)
    CreateThread(szWatchdog)
end)

RegisterNetEvent('db:zone:stop', szStop)

MC:on('matchEnded', szStop)