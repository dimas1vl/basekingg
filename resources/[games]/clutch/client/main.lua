MC = MatchClient.new()

local hudActive          = false
local hudThreadId        = 0
local controlBlockThread = 0
local currentSlot        = 1
local deathReported      = false
local spawnProtectId     = 0
local frozen             = false
local frozenUntil        = 0
local spawnInProgress    = false

local Zone

local BLOCKED_CONTROLS = { 23, 37, 74, 157, 158, 159, 160, 161, 162, 163, 164, 165 }

local function showHud(visible)
    hudActive = visible
    SendNUIMessage({ action = 'visible', data = visible })
end

local function publishMatchInfo()
    SendNUIMessage({
        action = 'matchInfo',
        data = {
            variant   = MC.variant,
            selfSrc   = MC.selfSrc,
            isInMatch = MC:isInMatch(),
        },
    })
end

local function publishWeaponsConfig()
    local slots = {}
    local list = Config.Clutch.weapons
    for i = 1, #list do
        local w = list[i]
        slots[#slots + 1] = { slot = w.slot, label = w.label, weapon = w.weapon }
    end
    SendNUIMessage({ action = 'weapons', data = { slots = slots, selected = currentSlot } })
end

---@param slot number
local function applySlot(slot)
    local cfg
    for i = 1, #Config.Clutch.weapons do
        if Config.Clutch.weapons[i].slot == slot then
            cfg = Config.Clutch.weapons[i]
            break
        end
    end
    if not cfg or not cfg.weapon then return end

    local ped  = PlayerPedId()
    local hash = type(cfg.weapon) == 'string' and GetHashKey(cfg.weapon) or cfg.weapon

    if not HasPedGotWeapon(ped, hash, false) then
        GiveWeaponToPed(ped, hash, cfg.ammo or 250, false, false)
    end

    SetCurrentPedWeapon(ped, hash, true)
    local _, maxClip = GetMaxAmmoInClip(ped, hash, true)
    SetAmmoInClip(ped, hash, maxClip and maxClip > 0 and maxClip or 30)
    currentSlot = slot

    SendNUIMessage({ action = 'weapon', data = { selected = slot, weapon = cfg.weapon } })
end

local function selectSlot(slot)
    if not MC:isInMatch() then return end
    if frozen then return end
    applySlot(slot)
end

local function giveLoadout()
    local ped = PlayerPedId()

    NetworkSetFriendlyFireOption(true)
    SetCanAttackFriendly(ped, false, false)
    SetPlayerCanDoDriveBy(PlayerId(), true)
    SetPedCanSwitchWeapon(ped, true)
    SetPedCanRagdoll(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, false)
    SetPedDropsWeaponsWhenDead(ped, false)

    RemoveAllPedWeapons(ped, true)
    for i = 1, #Config.Clutch.weapons do
        local w = Config.Clutch.weapons[i]
        if w.weapon then
            local hash = type(w.weapon) == 'string' and GetHashKey(w.weapon) or w.weapon
            GiveWeaponToPed(ped, hash, w.ammo or 250, false, false)
            local _, maxClip = GetMaxAmmoInClip(ped, hash, true)
            SetAmmoInClip(ped, hash, maxClip and maxClip > 0 and maxClip or 30)
        end
    end
    currentSlot = 1
    applySlot(1)
end

---@param weaponHash number | nil
local function getCurrentWeaponName(weaponHash)
    if not weaponHash or weaponHash == 0 then return nil end
    for i = 1, #Config.Clutch.weapons do
        local w = Config.Clutch.weapons[i]
        if w.weapon and GetHashKey(w.weapon) == weaponHash then
            return w.weapon
        end
    end
    return nil
end

local function sendHudUpdate()
    if not hudActive then return end
    local ped    = PlayerPedId()
    local health = math.max(0, GetEntityHealth(ped) - 100)
    local maxHp  = GetEntityMaxHealth(ped) - 100
    if maxHp <= 0 then maxHp = 100 end
    local armor  = GetPedArmour(ped)

    local _, hash = GetCurrentPedWeapon(ped, true)
    local weapon  = getCurrentWeaponName(hash)
    local _, clip = GetAmmoInClip(ped, hash or 0)
    local _, max  = GetMaxAmmo(ped, hash or 0)

    SendNUIMessage({
        action = 'hud',
        data = {
            hp        = health,
            hpMax     = maxHp,
            armor     = armor,
            armorMax  = 100,
            ammo      = clip or 0,
            maxAmmo   = max or 0,
            weapon    = weapon,
            frozen    = frozen,
            freezeMs  = math.max(0, frozenUntil - GetGameTimer()),
        },
    })
end

local function startHudThread()
    hudThreadId = hudThreadId + 1
    local myId = hudThreadId
    local interval = Config.Clutch.hudUpdateMs or 250
    CreateThread(function()
        while myId == hudThreadId and MC:isInMatch() do
            if hudActive then
                sendHudUpdate()
            end
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
            if frozen then
                DisablePlayerFiring(PlayerId(), true)
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
                DisableControlAction(0, 21, true)
                DisableControlAction(0, 30, true)
                DisableControlAction(0, 31, true)
            end
            Wait(0)
        end
    end)
end

local currentClutchSrc  = nil   -- legado, 1o do clutchSrcs
local currentClutchSet  = {}    -- set { [src] = true } pra checagem rapida

---@param otherSrc number
---@return boolean true se otherSrc esta no mesmo lado que selfSrc (mesmo time clutch ou ambos team)
local function isTeammate(otherSrc)
    if MC.variant == '1v1' then return false end
    if not MC.selfSrc or otherSrc == MC.selfSrc then return false end
    local selfIsClutch  = currentClutchSet[MC.selfSrc] == true
    local otherIsClutch = currentClutchSet[otherSrc]   == true
    return selfIsClutch == otherIsClutch
end

local wallhackThreadId = 0
local wallhackActive   = false
local outlinedPeds     = {}

local function clearWallhackOutlines()
    for ped in pairs(outlinedPeds) do
        if DoesEntityExist(ped) then
            SetEntityDrawOutline(ped, false)
        end
    end
    outlinedPeds = {}

    local ok, pool = pcall(GetGamePool, 'CPed')
    if ok and pool then
        for i = 1, #pool do
            local ped = pool[i]
            if ped and ped ~= 0 and DoesEntityExist(ped) then
                SetEntityDrawOutline(ped, false)
            end
        end
    end

    for _, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)
        if ped and ped ~= 0 and DoesEntityExist(ped) then
            SetEntityDrawOutline(ped, false)
        end
    end
end

local function stopWallhack()
    wallhackActive = false
    wallhackThreadId = wallhackThreadId + 1
    clearWallhackOutlines()
end

local function startWallhack()
    if wallhackActive then return end
    wallhackActive = true
    wallhackThreadId = wallhackThreadId + 1
    local myId = wallhackThreadId

    CreateThread(function()
        while wallhackActive and myId == wallhackThreadId and MC:isInMatch() and frozen do
            SetEntityDrawOutlineShader(0)
            SetEntityDrawOutlineColor(255, 255, 0, 240)
            SetEntityDrawOutlineRenderTechnique('waterreflectionalphaclip')

            local seen = {}

            local sb = MC.scoreboard
            if sb then
                for i = 1, #sb do
                    local p = sb[i]
                    if p.src ~= MC.selfSrc then
                        local clientId = GetPlayerFromServerId(p.src)
                        if clientId and clientId ~= -1 then
                            local ped = GetPlayerPed(clientId)
                            if ped ~= 0 and DoesEntityExist(ped) then
                                SetEntityDrawOutline(ped, true)
                                outlinedPeds[ped] = true
                                seen[clientId] = true
                            end
                        end
                    end
                end
            end

            for _, clientId in ipairs(GetActivePlayers()) do
                if not seen[clientId] then
                    local serverSrc = GetPlayerServerId(clientId)
                    if serverSrc ~= MC.selfSrc and serverSrc ~= -1 then
                        local ped = GetPlayerPed(clientId)
                        if ped ~= 0 and DoesEntityExist(ped) then
                            SetEntityDrawOutline(ped, true)
                            outlinedPeds[ped] = true
                        end
                    end
                end
            end

            Wait(250)
        end
        clearWallhackOutlines()
        wallhackActive = false
    end)
end

---@return number | nil clientId
---@return table | nil playerInfo
local function getAliveTeammate()
    -- 1v1 nao tem teammate. 1v2/2v4/3v5 sim — pega qualquer teammate vivo
    -- via isTeammate (mesmo lado: ambos clutch OU ambos team).
    if MC.variant == '1v1' then return nil end
    if not MC.scoreboard then return nil end

    for i = 1, #MC.scoreboard do
        local p = MC.scoreboard[i]
        if p.src ~= MC.selfSrc and isTeammate(p.src) then
            local clientId = GetPlayerFromServerId(p.src)
            if clientId and clientId ~= -1 then
                local ped = GetPlayerPed(clientId)
                if ped ~= 0 and DoesEntityExist(ped) and not IsEntityDead(ped) then
                    return clientId, p
                end
            end
        end
    end
    return nil
end

local spectatorActive    = false
local spectatorThreadId  = 0
local spectatorTargetCid = nil
local spectatorTargetName = nil

local function stopSpectatorMode()
    if not spectatorActive then
        SendNUIMessage({ action = 'clutch:spectate', data = { active = false } })
        return
    end
    spectatorActive = false
    spectatorTargetCid = nil
    spectatorTargetName = nil
    pcall(function() NetworkSetInSpectatorMode(false, PlayerPedId()) end)
    SendNUIMessage({ action = 'clutch:spectate', data = { active = false } })
end

local function startSpectatorMode()
    if spectatorActive then return end
    local clientId, info = getAliveTeammate()
    if not clientId or not info then return end

    local targetPed = GetPlayerPed(clientId)
    if targetPed == 0 or not DoesEntityExist(targetPed) then return end

    spectatorActive     = true
    spectatorTargetCid  = clientId
    spectatorTargetName = info.name

    pcall(function() NetworkSetInSpectatorMode(true, targetPed) end)

    SendNUIMessage({
        action = 'clutch:spectate',
        data = {
            active = true,
            name   = info.name,
            hp     = math.max(0, GetEntityHealth(targetPed) - 100),
            hpMax  = math.max(100, GetEntityMaxHealth(targetPed) - 100),
        },
    })

    spectatorThreadId = spectatorThreadId + 1
    local myId = spectatorThreadId

    CreateThread(function()
        while spectatorActive and myId == spectatorThreadId and MC:isInMatch() do
            local cid = spectatorTargetCid
            if not cid then break end
            local ped = GetPlayerPed(cid)
            if ped == 0 or not DoesEntityExist(ped) or IsEntityDead(ped) then
                break
            end
            local hp    = math.max(0, GetEntityHealth(ped) - 100)
            local hpMax = math.max(100, GetEntityMaxHealth(ped) - 100)
            SendNUIMessage({
                action = 'clutch:spectate',
                data = {
                    active = true,
                    name   = spectatorTargetName,
                    hp     = hp,
                    hpMax  = hpMax,
                },
            })
            Wait(250)
        end
        stopSpectatorMode()
    end)
end

local teammateThreadId = 0
local teammateActive   = false

local function stopTeammateMarkers()
    teammateActive = false
    SendNUIMessage({ action = 'clutch:teammates', data = {} })
end

local function startTeammateMarkers()
    if teammateActive then return end
    teammateActive = true
    teammateThreadId = teammateThreadId + 1
    local myId = teammateThreadId

    CreateThread(function()
        while teammateActive and myId == teammateThreadId and MC:isInMatch() do
            local markers = {}
            local sb      = MC.scoreboard

            if sb and MC.variant == '1v2' and currentClutchSrc and MC.selfSrc ~= currentClutchSrc then
                for i = 1, #sb do
                    local p = sb[i]
                    if p.src ~= MC.selfSrc and p.src ~= currentClutchSrc then
                        local clientId = GetPlayerFromServerId(p.src)
                        if clientId and clientId ~= -1 then
                            local ped = GetPlayerPed(clientId)
                            if ped ~= 0 and DoesEntityExist(ped) and not IsEntityDead(ped) then
                                local coords = GetEntityCoords(ped)
                                local onScreen, sx, sy = World3dToScreen2d(coords.x, coords.y, coords.z + 1.1)
                                if onScreen then
                                    markers[#markers + 1] = {
                                        src  = p.src,
                                        name = p.name,
                                        sx   = sx,
                                        sy   = sy,
                                    }
                                end
                            end
                        end
                    end
                end
            end

            SendNUIMessage({ action = 'clutch:teammates', data = markers })
            Wait(0)
        end
        teammateActive = false
        SendNUIMessage({ action = 'clutch:teammates', data = {} })
    end)
end

---@param ms number
local function startFreeze(ms)
    frozen = true
    frozenUntil = GetGameTimer() + ms
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetPlayerInvincible(PlayerId(), true)
    SendNUIMessage({ action = 'freeze', data = { active = true, ms = ms } })
    startWallhack()

    SetTimeout(ms, function()
        if not frozen then return end
        if GetGameTimer() < frozenUntil - 50 then return end
        -- Espera o applySpawn terminar antes de desfreezar — senao o ped pode cair se
        -- a colisao ainda nao carregou completamente.
        local guardDeadline = GetGameTimer() + 15000
        while spawnInProgress and GetGameTimer() < guardDeadline do Wait(50) end
        if not frozen then return end
        frozen = false
        frozenUntil = 0
        local p = PlayerPedId()
        FreezeEntityPosition(p, false)
        SetPlayerInvincible(PlayerId(), false)
        SendNUIMessage({ action = 'freeze', data = { active = false, ms = 0 } })
    end)
end

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
        end
    end
    for ipl in pairs(newIplSet) do
        if not loadedIpls[ipl] then
            RequestIpl(ipl)
            loadedIpls[ipl] = true
        end
    end

    local newItypSet = {}
    for i = 1, #itypList do newItypSet[itypList[i]] = true end
    for itypName, hash in pairs(loadedItyps) do
        if not newItypSet[itypName] then
            if RemoveItypRequest then
                pcall(RemoveItypRequest, hash)
            end
            loadedItyps[itypName] = nil
        end
    end
    for itypName in pairs(newItypSet) do
        if not loadedItyps[itypName] then
            local hash = GetHashKey(itypName)
            if RequestItyp then
                pcall(RequestItyp, hash)
                loadedItyps[itypName] = hash
            end
        end
    end

    if cx and cy and cz and (cx ~= 0.0 or cy ~= 0.0 or cz ~= 0.0) then
        mapPreloadThread = mapPreloadThread + 1
        local myId = mapPreloadThread
        CreateThread(function()
            RequestCollisionAtCoord(cx, cy, cz)
            NewLoadSceneStartSphere(cx, cy, cz, 600.0, 0)
            local deadline = GetGameTimer() + 10000
            while GetGameTimer() < deadline and myId == mapPreloadThread do
                if IsNewLoadSceneLoaded() then break end
                Wait(200)
            end
            if myId == mapPreloadThread then
                NewLoadSceneStop()
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
    for _, hash in pairs(loadedItyps) do
        if RemoveItypRequest then
            pcall(RemoveItypRequest, hash)
        end
    end
    loadedItyps = {}
end

---@param coords vector3
---@param heading number
local function applySpawn(coords, heading)
    spawnInProgress = true

    if not IsScreenFadedOut() then
        DoScreenFadeOut(200)
        while not IsScreenFadedOut() do Wait(0) end
    end

    local ped = PlayerPedId()

    -- 1) Trava o ped ANTES de qualquer coisa — sem queda no limbo enquanto carrega
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityCollision(ped, false, false)

    if IsEntityDead(ped) then
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading or 0.0, true, false)
        Wait(50)
        ped = PlayerPedId()
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetEntityCollision(ped, false, false)
    end

    -- 2) Forca o streaming do mapa no destino ANTES de teleportar
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    NewLoadSceneStartSphere(coords.x, coords.y, coords.z, 500.0, 0)

    -- 3) Teleporta (ped continua frozen)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(ped, heading or 0.0)
    SetEntityVisible(ped, true)

    -- 4) Espera a colisao REALMENTE carregar antes de qualquer coisa fisica. Re-pinea
    --    as coords cada tick — o ped frozen nao pode mover, mas garantimos contra
    --    qualquer race do engine que tente reposicionar.
    local deadline = GetGameTimer() + 10000
    local loaded   = false
    while GetGameTimer() < deadline do
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
        if HasCollisionLoadedAroundEntity(ped) then
            loaded = true
            break
        end
        Wait(50)
    end
    NewLoadSceneStop()

    -- 5) Snap pro Z do chao se a coord esta abaixo do terreno detectado (fallback se
    --    a colisao demorou demais ou se a coord do config esta levemente errada)
    local foundGround, gz = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 50.0, false)
    if foundGround and coords.z < gz - 0.5 then
        SetEntityCoordsNoOffset(ped, coords.x, coords.y, gz + 0.1, false, false, false)
    else
        SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    end
    SetEntityHeading(ped, heading or 0.0)

    -- 6) Re-ativa colisao agora que o terreno esta carregado.
    --    NAO desfreeza aqui — startFreeze() vai segurar o freeze durante o warmup
    --    e desfreezar so quando o round comeca. Sem janela de queda.
    SetEntityCollision(ped, true, true)
    if not loaded then
        print(('^3[clutch] collision nao carregou em 10s no spawn (%.1f, %.1f, %.1f) — fallback ground z aplicado^7'):format(coords.x, coords.y, coords.z))
    end

    SetEntityMaxHealth(ped, Config.Clutch.startHealth)
    SetEntityHealth(ped, Config.Clutch.startHealth)
    SetPedArmour(ped, Config.Clutch.startArmor)

    ClearPedTasksImmediately(ped)
    giveLoadout()

    deathReported = false
    spawnProtectId = spawnProtectId + 1

    ShutdownLoadingScreen()
    DoScreenFadeIn(500)

    spawnInProgress = false
end

local CLUTCH_GROUP_NAME = 'CLUTCH_TEAM_A'
local TEAM_GROUP_NAME   = 'CLUTCH_TEAM_B'
local CLUTCH_GROUP_HASH = GetHashKey(CLUTCH_GROUP_NAME)
local TEAM_GROUP_HASH   = GetHashKey(TEAM_GROUP_NAME)
local teamGroupsRegistered = false

local function setupTeamRelationships()
    if teamGroupsRegistered then return end
    AddRelationshipGroup(CLUTCH_GROUP_NAME)
    AddRelationshipGroup(TEAM_GROUP_NAME)
    SetRelationshipBetweenGroups(1, CLUTCH_GROUP_HASH, CLUTCH_GROUP_HASH)
    SetRelationshipBetweenGroups(1, TEAM_GROUP_HASH, TEAM_GROUP_HASH)
    SetRelationshipBetweenGroups(5, CLUTCH_GROUP_HASH, TEAM_GROUP_HASH)
    SetRelationshipBetweenGroups(5, TEAM_GROUP_HASH, CLUTCH_GROUP_HASH)
    teamGroupsRegistered = true
end

local function getGroupForSrc(src)
    if MC.variant == '1v1' then
        return (src == MC.selfSrc) and CLUTCH_GROUP_HASH or TEAM_GROUP_HASH
    end
    return currentClutchSet[src] and CLUTCH_GROUP_HASH or TEAM_GROUP_HASH
end

local function applyTeamGroups()
    if not MC.selfSrc then return end

    local selfPed = PlayerPedId()
    if selfPed ~= 0 then
        SetPedRelationshipGroupHash(selfPed, getGroupForSrc(MC.selfSrc))
    end

    for _, clientId in ipairs(GetActivePlayers()) do
        local serverSrc = GetPlayerServerId(clientId)
        if serverSrc and serverSrc ~= MC.selfSrc and serverSrc ~= -1 then
            local ped = GetPlayerPed(clientId)
            if ped ~= 0 and DoesEntityExist(ped) then
                SetPedRelationshipGroupHash(ped, getGroupForSrc(serverSrc))
            end
        end
    end
end

local pvpWatchdogId = 0
local function startPvpWatchdog()
    pvpWatchdogId = pvpWatchdogId + 1
    local myId = pvpWatchdogId
    CreateThread(function()
        while myId == pvpWatchdogId and MC:isInMatch() do
            NetworkSetFriendlyFireOption(true)
            local ped = PlayerPedId()
            if ped and ped ~= 0 then
                SetCanAttackFriendly(ped, false, false)
            end
            applyTeamGroups()
            Wait(100)
        end
    end)
end

MC:on('matchJoined', function(_, _, scoreboard, variant)
    NetworkSetFriendlyFireOption(true)
    setupTeamRelationships()
    startHudThread()
    startControlBlockThread()
    startPvpWatchdog()
    publishMatchInfo()
    publishWeaponsConfig()
    SendNUIMessage({ action = 'scoreboard', data = scoreboard or {} })
    startTeammateMarkers()
end)

MC:on('stateChanged', function(newState)
    SendNUIMessage({ action = 'state', data = newState })
end)

MC:on('roundInfo', function(info)
    SendNUIMessage({ action = 'roundInfo', data = info })
    if info then
        applyMapAssets(info.ipls, info.ityps, info.centerX, info.centerY, info.centerZ)
        currentClutchSrc = info.clutchSrc
        currentClutchSet = {}
        if type(info.clutchSrcs) == 'table' then
            for i = 1, #info.clutchSrcs do
                currentClutchSet[info.clutchSrcs[i]] = true
            end
        elseif info.clutchSrc then
            currentClutchSet[info.clutchSrc] = true
        end
    end
end)

MC:on('roundSpawn', function(payload)
    if not payload then return end
    stopSpectatorMode()
    -- Seta o estado de freeze (flag `frozen` + SetTimeout) ANTES do applySpawn —
    -- assim, se o applySpawn demorar a carregar a colisao e o fightStart chegar nesse
    -- meio tempo, o handler vai ver `frozen=true` e desfreezar corretamente quando o
    -- spawnInProgress liberar. Sem essa ordem, o fightStart cairia no `if frozen then`
    -- com frozen=false e o ped ficaria travado ate o SetTimeout.
    local freezeMs = math.max(1, tonumber(payload.freezeMs) or 0)
    startFreeze(freezeMs)
    applySpawn(payload.coords, payload.heading)
    showHud(true)
    publishWeaponsConfig()
    if Zone then Zone.outsideSince = 0 end
    SendNUIMessage({
        action = 'roleUpdate',
        data = { isClutch = payload.isClutch == true, freezeMs = freezeMs },
    })
end)

MC:on('fightStart', function()
    -- Se o applySpawn ainda esta carregando a colisao, espera ele terminar antes
    -- de desfreezar — caso contrario o ped pode cair no limbo.
    local guardDeadline = GetGameTimer() + 15000
    while spawnInProgress and GetGameTimer() < guardDeadline do Wait(50) end

    if frozen then
        frozen = false
        frozenUntil = 0
        local p = PlayerPedId()
        FreezeEntityPosition(p, false)
        SetPlayerInvincible(PlayerId(), false)
        SendNUIMessage({ action = 'freeze', data = { active = false, ms = 0 } })
    end
    stopWallhack()
    clearWallhackOutlines()
    SendNUIMessage({ action = 'fightStart', data = true })
end)

MC:on('roundResult', function(result)
    SendNUIMessage({ action = 'roundResult', data = result })
end)

MC:on('scoreboard', function(scoreboard)
    SendNUIMessage({ action = 'scoreboard', data = scoreboard })
end)

MC:on('killFeed', function(entry)
    SendNUIMessage({ action = 'killFeed', data = entry })
end)

MC:on('matchResult', function(result)
    SendNUIMessage({ action = 'matchResult', data = result })
end)

MC:on('matchEnded', function()
    showHud(false)
    stopWallhack()
    clearWallhackOutlines()
    stopTeammateMarkers()
    stopSpectatorMode()
    currentClutchSrc = nil
    spawnProtectId = spawnProtectId + 1
    SetPlayerInvincible(PlayerId(), false)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    frozen = false
    frozenUntil = 0
    if Zone then Zone.active = false end

    unloadAllMapAssets()

    DoScreenFadeOut(400)
    Wait(400)
    local ped = PlayerPedId()

    if IsEntityDead(ped) then
        local coords = GetEntityCoords(ped)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z + 1.0, 0.0, true, false)
        Wait(100)
        ped = PlayerPedId()
    end

    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, false)
    SetEntityMaxHealth(ped, 200)
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 0)
    RemoveAllPedWeapons(ped, true)

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
        startSpectatorMode()
    end
end)

CreateThread(function()
    for i = 1, 8 do
        local cmd = 'clutch_slot_' .. i
        local slot = i
        RegisterCommand('+' .. cmd, function() selectSlot(slot) end, false)
        RegisterCommand('-' .. cmd, function() end, false)
        RegisterKeyMapping('+' .. cmd, ('[CLUTCH] Slot %d'):format(i), 'keyboard', tostring(i))
    end
end)

local LEAVE_HOLD_MS    = 2000
local leaveHoldActive  = false
local leaveHoldThread  = 0

local function startLeaveHold()
    if not MC:isInMatch() then return end
    if leaveHoldActive then return end

    leaveHoldActive = true
    leaveHoldThread = leaveHoldThread + 1
    local myId = leaveHoldThread
    local startedAt = GetGameTimer()

    SendNUIMessage({ action = 'leaveHold', data = { visible = true, percent = 0 } })

    CreateThread(function()
        while leaveHoldActive and myId == leaveHoldThread and MC:isInMatch() do
            local elapsed = GetGameTimer() - startedAt
            local pct = math.min(100, math.floor((elapsed / LEAVE_HOLD_MS) * 100))
            SendNUIMessage({ action = 'leaveHold', data = { visible = true, percent = pct } })
            if elapsed >= LEAVE_HOLD_MS then
                leaveHoldActive = false
                SendNUIMessage({ action = 'leaveHold', data = { visible = false, percent = 0 } })
                MC:emitServer('leaveMatch')
                return
            end
            Wait(50)
        end
        SendNUIMessage({ action = 'leaveHold', data = { visible = false, percent = 0 } })
    end)
end

local function cancelLeaveHold()
    if not leaveHoldActive then return end
    leaveHoldActive = false
    SendNUIMessage({ action = 'leaveHold', data = { visible = false, percent = 0 } })
end

RegisterCommand('+clutch_leave', startLeaveHold,  false)
RegisterCommand('-clutch_leave', cancelLeaveHold, false)
RegisterKeyMapping('+clutch_leave', '[CLUTCH] Sair da partida', 'keyboard', 'F')

local SZ_DICT   = 'safezone'
local SZ_TEX    = 'kingg_safezone'
local SZ_HEIGHT = 1000.0
local SZ_COLOR  = { 235, 100, 100, 200 }

Zone = {
    active        = false,
    center        = nil,
    startRadius   = 0.0,
    endRadius     = 0.0,
    shrinkMs      = 60000,
    dpsHp         = 8,
    tickMs        = 1000,
    startedAt     = 0,
    textureLoaded = false,
    outsideSince  = 0,
    lastDamageAt  = 0,
}

---@return number
local function currentRadius()
    if not Zone.active then return 0.0 end
    local elapsed = GetGameTimer() - Zone.startedAt
    if elapsed <= 0 then return Zone.startRadius end
    if elapsed >= Zone.shrinkMs then return Zone.endRadius end
    local t = elapsed / Zone.shrinkMs
    return Zone.startRadius + (Zone.endRadius - Zone.startRadius) * t
end

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
    local r = currentRadius()
    local size = r * 1.98412
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

local function szDamageWatchdog()
    while Zone.active do
        Wait(Zone.tickMs)
        if not Zone.active or not Zone.center then break end
        if not MC:isInMatch() then break end
        if frozen then
            Zone.outsideSince = 0
        else
            local ped = PlayerPedId()
            if not IsEntityDead(ped) then
                local pc   = GetEntityCoords(ped)
                local c    = Zone.center
                local dist = #(vector3(pc.x, pc.y, pc.z) - vector3(c.x, c.y, c.z))
                local r    = currentRadius()
                if dist > r then
                    SetPedArmour(ped, 0)
                    if ApplyDamageToPed then
                        ApplyDamageToPed(ped, Zone.dpsHp, true)
                    else
                        local hp = GetEntityHealth(ped)
                        SetEntityHealth(ped, math.max(0, hp - Zone.dpsHp))
                    end
                    Zone.outsideSince = GetGameTimer()
                else
                    Zone.outsideSince = 0
                end
            end
        end
    end
end

local function szPublishThread()
    while Zone.active do
        if MC:isInMatch() then
            local r = currentRadius()
            SendNUIMessage({ action = 'zoneUpdate', data = {
                radius      = r,
                startRadius = Zone.startRadius,
                endRadius   = Zone.endRadius,
                elapsedMs   = GetGameTimer() - Zone.startedAt,
                shrinkMs    = Zone.shrinkMs,
            } })
        end
        Wait(500)
    end
end

local function szStart(data)
    if Zone.active then Zone.active = false; Wait(50) end
    Zone.active        = true
    Zone.center        = { x = data.x or 0.0, y = data.y or 0.0, z = data.z or 0.0 }
    Zone.startRadius   = data.startRadius or 200.0
    Zone.endRadius     = data.endRadius   or 5.0
    Zone.shrinkMs      = data.shrinkMs    or 60000
    Zone.dpsHp         = data.dpsHp       or 8
    Zone.tickMs        = data.tickMs      or 1000
    Zone.startedAt     = GetGameTimer()
    Zone.outsideSince  = 0

    CreateThread(szTick)
    CreateThread(szDamageWatchdog)
    CreateThread(szPublishThread)
end

local function szStop()
    Zone.active = false
    Zone.center = nil
    Zone.outsideSince = 0
    SendNUIMessage({ action = 'zoneUpdate', data = { radius = 0, startRadius = 0, endRadius = 0, elapsedMs = 0, shrinkMs = 0 } })
end

MC:on('zoneStart', szStart)
MC:on('zoneStop',  szStop)
MC:on('matchEnded', szStop)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    Zone.active = false
    stopWallhack()
    clearWallhackOutlines()
    stopTeammateMarkers()
    stopSpectatorMode()
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    for ipl in pairs(loadedIpls) do
        if IsIplActive(ipl) then RemoveIpl(ipl) end
    end
end)
