MC = MatchClient.new()

local deathReported       = false
local spawnProtectId      = 0
local hudActive           = false
local hudThreadId         = 0
local controlBlockThread  = 0
local scoreboardOpen      = false
local currentSlot         = 1
local victimHealthCache   = {}

local Zone

local BLOCKED_CONTROLS = { 23, 37, 74, 157, 158, 159, 160, 161, 162, 163, 164, 165 }

local function showHud(visible)
    hudActive = visible
    SendNUIMessage({ action = 'visible', value = visible })
end

---@return table[] weapons
local function activeWeapons()
    return Config.Deathmatch:weaponsFor(MC and MC.subMode)
end

---@return string | nil weaponName, number clip, number maxAmmo
local function getCurrentWeaponInfo(ped)
    local _, hashOrZero = GetCurrentPedWeapon(ped, true)
    if not hashOrZero or hashOrZero == 0 then return nil, 0, 0 end

    local weaponName
    local list = activeWeapons()
    for i = 1, #list do
        local w = list[i]
        if w.weapon and GetHashKey(w.weapon) == hashOrZero then
            weaponName = w.weapon
            break
        end
    end

    local _, clip = GetAmmoInClip(ped, hashOrZero)
    local _, maxAmmo = GetMaxAmmo(ped, hashOrZero)
    return weaponName, clip or 0, maxAmmo or 0
end

local function sendHudUpdate()
    if not hudActive then return end
    local ped    = PlayerPedId()
    local health = math.max(0, GetEntityHealth(ped) - 100)
    local maxHp  = GetEntityMaxHealth(ped) - 100
    if maxHp <= 0 then maxHp = 100 end
    local armor  = GetPedArmour(ped)

    local me
    if MC.scoreboard then
        for i = 1, #MC.scoreboard do
            if MC.scoreboard[i].src == MC.selfSrc then
                me = MC.scoreboard[i]
                break
            end
        end
    end

    local total = MC.scoreboard and #MC.scoreboard or 0

    local weapon, ammo, maxAmmo = getCurrentWeaponInfo(ped)

    local veh = GetVehiclePedIsIn(ped, false)
    local inVehicle = veh ~= 0
    local speed = 0
    if inVehicle then
        speed = math.floor(GetEntitySpeed(veh) * 3.6 + 0.5)
    end

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
    hudThreadId = hudThreadId + 1
    local myId = hudThreadId
    local interval = Config.Deathmatch.hudUpdateMs or 500
    CreateThread(function()
        while hudActive and myId == hudThreadId do
            sendHudUpdate()
            Wait(interval)
        end
    end)
end

local function startControlBlockThread()
    controlBlockThread = controlBlockThread + 1
    local myId = controlBlockThread
    CreateThread(function()
        while myId == controlBlockThread and MC:isInMatch() do
            for i = 1, #BLOCKED_CONTROLS do
                DisableControlAction(0, BLOCKED_CONTROLS[i], true)
            end
            Wait(0)
        end
    end)
end

local function publishWeaponsConfig()
    local list = activeWeapons()
    local slots = {}
    for i = 1, #list do
        local w = list[i]
        slots[#slots + 1] = { slot = w.slot, label = w.label, weapon = w.weapon }
    end
    SendNUIMessage({ action = 'weapons', data = { slots = slots, selected = currentSlot } })
end

local function selectSlot(slot)
    if not MC:isInMatch() then return end
    local cfg
    local list = activeWeapons()
    for i = 1, #list do
        if list[i].slot == slot then
            cfg = list[i]
            break
        end
    end
    if not cfg or not cfg.weapon then return end
    local ped  = PlayerPedId()
    local hash = type(cfg.weapon) == 'string' and GetHashKey(cfg.weapon) or cfg.weapon

    if not HasPedGotWeapon(ped, hash, false) then
        GiveWeaponToPed(ped, hash, cfg.ammo or 9999, false, false)
    end

    SetCurrentPedWeapon(ped, hash, true)
    AddAmmoToPed(ped, hash, 9999)
    SetPedInfiniteAmmo(ped, true, hash)
    
    local _, maxClip = GetMaxAmmoInClip(ped, hash, true)
    SetAmmoInClip(ped, hash, maxClip and maxClip > 0 and maxClip or 30)
    currentSlot = slot

    local mult = tonumber(cfg.speedMultiplier) or 1.0
    SetRunSprintMultiplierForPlayer(PlayerId(), mult + 0.0)

    SendNUIMessage({ action = 'weapon', selected = slot, weapon = cfg.weapon })
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

    RemoveAllPedWeapons(ped, true)
    local list = activeWeapons()
    for i = 1, #list do
        local w = list[i]
        if w.weapon then
            local hash = type(w.weapon) == 'string' and GetHashKey(w.weapon) or w.weapon
            GiveWeaponToPed(ped, hash, w.ammo or 9999, false, false)
            AddAmmoToPed(ped, hash, 9999)
            SetPedInfiniteAmmo(ped, true, hash)
            local _, maxClip = GetMaxAmmoInClip(ped, hash, true)
            SetAmmoInClip(ped, hash, maxClip and maxClip > 0 and maxClip or 30)
            TriggerEvent('kingg:player:weaponGiven', hash)
        end
    end
    currentSlot = 1
    selectSlot(1)
end

local function readVictimHpArmor(victim)
    local hp = GetEntityHealth(victim)
    local armor = 0
    if IsEntityAPed(victim) and IsPedAPlayer(victim) then
        armor = GetPedArmour(victim)
    end
    return hp, armor
end

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

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    NewLoadSceneStartSphere(coords.x, coords.y, coords.z, 400.0, 0)

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

    SetEntityMaxHealth(ped, Config.Deathmatch.startHealth)
    SetEntityHealth(ped, Config.Deathmatch.startHealth)
    SetPedArmour(ped, Config.Deathmatch.startArmor)

    ClearPedTasksImmediately(ped)
    giveLoadout()

    SetPlayerInvincible(PlayerId(), true)
    deathReported = false

    spawnProtectId = spawnProtectId + 1
    local myProtect = spawnProtectId
    SetTimeout(Config.Deathmatch.spawnProtectionMs, function()
        if myProtect == spawnProtectId then
            SetPlayerInvincible(PlayerId(), false)
        end
    end)

    ShutdownLoadingScreen()
    DoScreenFadeIn(500)

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
    startPvpWatchdog()
    publishWeaponsConfig()
    SendNUIMessage({ action = 'scoreboard', data = scoreboard or {}, selfSrc = MC.selfSrc })
end)

MC:on('stateChanged', function(newState)
    SendNUIMessage({ action = 'state', value = newState })
end)

MC:on('spawn', function(coords, heading)
    applySpawn(coords, heading)
    publishWeaponsConfig()
    Zone.outsideSince = 0
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

local loadedIpls = {}
local loadedItyps = {}
local mapPreloadThread = 0

local function applyMapAssets(iplList, itypList, cx, cy, cz)
    iplList  = iplList  or {}
    itypList = itypList or {}

    local newIplSet = {}
    for i = 1, #iplList do newIplSet[iplList[i]] = true end

    for ipl in pairs(loadedIpls) do
        if not newIplSet[ipl] then
            if IsIplActive(ipl) then RemoveIpl(ipl) end
            loadedIpls[ipl] = nil
            print(('[deathmatch] removed IPL: %s'):format(ipl))
        end
    end

    for ipl in pairs(newIplSet) do
        if not loadedIpls[ipl] then
            RequestIpl(ipl)
            loadedIpls[ipl] = true
            print(('[deathmatch] requested IPL: %s'):format(ipl))
        end
    end

    local newItypSet = {}
    for i = 1, #itypList do newItypSet[itypList[i]] = true end

    for itypName, hash in pairs(loadedItyps) do
        if not newItypSet[itypName] then
            RemoveItypRequest(hash)
            loadedItyps[itypName] = nil
            print(('[deathmatch] released YTYP: %s'):format(itypName))
        end
    end

    for itypName in pairs(newItypSet) do
        if not loadedItyps[itypName] then
            local hash = GetHashKey(itypName)
            RequestItyp(hash)
            loadedItyps[itypName] = hash
            print(('[deathmatch] requested YTYP: %s (hash=%d)'):format(itypName, hash))
        end
    end

    if cx and cy and cz and (cx ~= 0.0 or cy ~= 0.0 or cz ~= 0.0) then
        mapPreloadThread = mapPreloadThread + 1
        local myId = mapPreloadThread

        CreateThread(function()
            RequestCollisionAtCoord(cx, cy, cz)
            NewLoadSceneStartSphere(cx, cy, cz, 600.0, 0)
            print(('[deathmatch] scene preload at %.1f, %.1f, %.1f (radius 600)'):format(cx, cy, cz))

            local deadline = GetGameTimer() + 10000
            while GetGameTimer() < deadline and myId == mapPreloadThread do
                local allLoaded = true

                for ipl in pairs(loadedIpls) do
                    if not IsIplActive(ipl) then
                        allLoaded = false
                        RequestIpl(ipl)
                    end
                end

                for itypName, hash in pairs(loadedItyps) do
                    if not HasThisAdditionalTextLoaded(itypName, 10) and not HasItypRequestCompleted(hash) then
                        allLoaded = false
                        RequestItyp(hash)
                    end
                end

                if allLoaded and IsNewLoadSceneLoaded() then break end
                Wait(200)
            end

            if myId == mapPreloadThread then
                NewLoadSceneStop()
                for ipl in pairs(loadedIpls) do
                    print(('[deathmatch] IPL "%s" active=%s'):format(ipl, tostring(IsIplActive(ipl))))
                end
                for itypName, hash in pairs(loadedItyps) do
                    print(('[deathmatch] YTYP "%s" completed=%s'):format(itypName, tostring(HasItypRequestCompleted(hash))))
                end
            end
        end)
    end
end

local function unloadAllMapAssets()
    mapPreloadThread = mapPreloadThread + 1
    NewLoadSceneStop()
    for ipl in pairs(loadedIpls) do
        if IsIplActive(ipl) then RemoveIpl(ipl) end
    end
    loadedIpls = {}
    for itypName, hash in pairs(loadedItyps) do
        RemoveItypRequest(hash)
    end
    loadedItyps = {}
end

local applyMapIpls = applyMapAssets
local unloadAllMapIpls = unloadAllMapAssets

MC:on('mapInfo', function(info)
    SendNUIMessage({ action = 'mapInfo', data = info })
    if info then
        applyMapAssets(info.ipls, info.ityps, info.centerX, info.centerY, info.centerZ)
    end
end)

MC:on('mapResult', function(result)
    SendNUIMessage({ action = 'mapResult', data = result, selfSrc = MC.selfSrc })
end)

MC:on('matchEnded', function()
    showHud(false)
    scoreboardOpen = false
    spawnProtectId = spawnProtectId + 1
    SetPlayerInvincible(PlayerId(), false)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    victimHealthCache = {}

    unloadAllMapIpls()

    DoScreenFadeOut(400)
    Wait(400)
    local ped = PlayerPedId()
    SetEntityMaxHealth(ped, 200)
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 0)
    RemoveAllPedWeapons(ped, true)

    local ok = pcall(function() exports.lobby:displayLobby() end)
    if not ok then
        DoScreenFadeIn(600)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for ipl in pairs(loadedIpls) do
        if IsIplActive(ipl) then RemoveIpl(ipl) end
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
        local prev = victimHealthCache[victim] or {
            hp    = Config.Deathmatch.startHealth or 200,
            armor = Config.Deathmatch.startArmor  or 100,
        }

        local damage = (prev.hp - currHp) + (prev.armor - currArmor)
        victimHealthCache[victim] = { hp = currHp, armor = currArmor }

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

    if victim == localPed and (victimDied == 1 or victimDied == true) and not deathReported then
        deathReported = true

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

local kmCfg = Config.Deathmatch.scoreboardKeyMapping

RegisterCommand('+' .. kmCfg.command, function()
    if not MC:isInMatch() or scoreboardOpen then return end
    scoreboardOpen = true
    if MC.scoreboard then
        SendNUIMessage({ action = 'scoreboard', data = MC.scoreboard, selfSrc = MC.selfSrc })
    end
    SendNUIMessage({ action = 'scoreboardVisible', value = true })
end, false)

RegisterCommand('-' .. kmCfg.command, function()
    if not scoreboardOpen then return end
    scoreboardOpen = false
    SendNUIMessage({ action = 'scoreboardVisible', value = false })
end, false)

RegisterKeyMapping('+' .. kmCfg.command, kmCfg.label, 'keyboard', kmCfg.key)

CreateThread(function()
    for i = 1, 8 do
        local cmd = 'dm_slot_' .. i
        RegisterCommand('+' .. cmd, function()
            selectSlot(i)
        end, false)
        RegisterCommand('-' .. cmd, function() end, false)
        RegisterKeyMapping('+' .. cmd, ('Slot %d (Deathmatch)'):format(i), 'keyboard', tostring(i))
    end
end)

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

RegisterCommand('+dm_leave', startLeaveHold,  false)
RegisterCommand('-dm_leave', cancelLeaveHold, false)
RegisterKeyMapping('+dm_leave', 'Sair da partida (Deathmatch)', 'keyboard', 'F')


local SZ_DICT   = 'safezone'
local SZ_TEX    = 'kingg_safezone'
local SZ_HEIGHT = 1000.0
local SZ_COLOR  = { 100, 180, 255, 180 }

Zone = {
    active           = false,
    center           = nil,
    radius           = 0.0,
    outsideRespawnMs = 1500,
    textureLoaded    = false,
    outsideSince     = 0,
    respawning       = false,
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

    DrawMarker(
        1,
        c.x, c.y, c.z - 300.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
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
        if IsEntityDead(ped) then
            Zone.outsideSince = 0
        else
            local pc   = GetEntityCoords(ped)
            local c    = Zone.center
            local dist = #(vector3(pc.x, pc.y, pc.z) - vector3(c.x, c.y, c.z))

            if dist > Zone.radius then
                if Zone.outsideSince == 0 then
                    Zone.outsideSince = GetGameTimer()
                elseif GetGameTimer() - Zone.outsideSince >= Zone.outsideRespawnMs then
                    MC:emitServer('requestZoneRespawn')
                    Zone.outsideSince = GetGameTimer()
                end
            else
                Zone.outsideSince = 0
            end
        end
    end
end

local function szStop()
    Zone.active       = false
    Zone.center       = nil
    Zone.outsideSince = 0
    Zone.respawning   = false
end

RegisterNetEvent('dm:zone:start', function(data)
    if type(data) ~= 'table' then return end
    if Zone.active then return end

    Zone.active = true
    Zone.center = {
        x = tonumber(data.x) or 0.0,
        y = tonumber(data.y) or 0.0,
        z = tonumber(data.z) or 0.0,
    }
    Zone.radius           = tonumber(data.radius)           or 500.0
    Zone.outsideRespawnMs = tonumber(data.outsideRespawnMs) or 1500
    Zone.outsideSince     = 0
    Zone.respawning       = false

    CreateThread(szTick)
    CreateThread(szWatchdog)
end)

RegisterNetEvent('dm:zone:stop', szStop)

MC:on('matchEnded', szStop)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    Zone.active = false
end)
