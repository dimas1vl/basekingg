local Combat = Game.module('combat')

local cfgInjury = Config.BR.injury
local cfgProne = Config.BR.prone
local REVIVE_DICT = Config.BR.anims.revive

local DICT_CRAWL      = 'move_crawl'
local DICT_CRAWL_FLIP = 'move_crawlprone2crawlfront'
local DICT_GETUP      = 'get_up@directional@'
local DICT_SWEEP      = 'get_up@directional_sweep@combat@pistol@'
local DICT_ENTER_RUN  = 'explosions'
local DICT_ENTER_IDLE = 'amb@world_human_sunbathe@male@front@enter'
local CLIP_BLOWN      = 'react_blown_forwards'


local EMPTY = {}

---@param ped number
---@param dict string
---@param clip string
---@param opts? { blendIn?: number, blendOut?: number, duration?: number, startPhase?: number }
local function playAnimation(ped, dict, clip, opts)
    opts = opts or EMPTY
    Game.requestAsset(dict, 'anim')
    TaskPlayAnim(ped, dict, clip,
        opts.blendIn or 2.0, opts.blendOut or 2.0,
        opts.duration or -1, 0, opts.startPhase or 0.0,
        false, false, false)
    RemoveAnimDict(dict)
end

---@param ped number
---@param delta number
---@param duration number
local function lerpHeading(ped, delta, duration)
    local start = GetEntityHeading(ped)
    local elapsed = 0
    while elapsed < duration do
        Wait(0)
        elapsed = elapsed + GetFrameTime() * 1000
        local t = math.min(elapsed / duration, 1.0)
        SetEntityHeading(ped, start + delta * t)
    end
end

---@param ped number
---@param heading? number
---@param blendSpeed? number
local function idleProne(ped, posture, heading, blendSpeed)
    local coords = GetEntityCoords(ped)
    TaskPlayAnimAdvanced(ped, DICT_CRAWL, posture .. '_fwd',
        coords.x, coords.y, coords.z,
        0.0, 0.0, heading or GetEntityHeading(ped),
        blendSpeed or 2.0, 2.0, -1, 2, 1.0, false, false)
end


local PRONE_BELLY  = 'belly'
local PRONE_SUPINE = 'supine'

local HASH_PARACHUTE = GetHashKey('GADGET_PARACHUTE')
local HASH_UNARMED   = GetHashKey('WEAPON_UNARMED')
local HASH_KNIFE     = GetHashKey('WEAPON_KNIFE')

local ANIM_PREFIX = {
    [PRONE_BELLY]  = 'onfront',
    [PRONE_SUPINE] = 'onback',
}

local STANDUP_STEPS = {
    [PRONE_BELLY] = {
        { DICT_GETUP .. 'transition@prone_to_knees@crawl', 'front', 800 },
        { DICT_GETUP .. 'movement@from_knees@standard', 'getup_l_0', 1350 },
    },
    [PRONE_SUPINE] = {
        { DICT_GETUP .. 'transition@prone_to_seated@crawl', 'back', 900, 16.0 },
        { DICT_GETUP .. 'movement@from_seated@standard', 'get_up_l_0', 1350 },
    },
}


local isInjuredProne = false
local isManualProne = false
local isMoving = false
local isBusy = false
local isFlipping = false

local injuredPosture = PRONE_BELLY
local manualPosture = PRONE_BELLY
local hadParachute = false
local parachuteCooldown = 0

---@alias CombatPhase 'standing' | 'injured' | 'eliminated'

Status = {
    STANDING   = 'standing',
    INJURED    = 'injured',
    ELIMINATED = 'eliminated',
}

local combatPhase = Status.STANDING
local killerServerId = 0
local hasSentDeath = false

local reviveActive = false
local reviveSrc = nil
local reviveAbort = nil

---@type table<number, PlayerState>
local squadStates = {}

Game.combat = {
    status = function() return combatPhase end,
}

Core._proneCheck = function() return isInjuredProne or isManualProne end
Core._layingCheck = function() return isManualProne end

local function disableProneControls()
    for _, c in ipairs(cfgProne.disabledControls) do
        DisableControlAction(0, c)
    end
end

---@param ped number
---@param posture string
---@param direction string
local function moveProne(ped, posture, direction)
    isMoving = true
    TaskPlayAnim(ped, DICT_CRAWL, ANIM_PREFIX[posture] .. '_' .. direction, 8.0, -8.0, -1, 2, 0.0, false, false, false)

    local elapsed = 0
    local target = cfgProne.crawlMs[posture][direction]
    CreateThread(function()
        while elapsed < target do
            elapsed = elapsed + GetFrameTime() * 1000
            Wait(0)
        end
        isMoving = false
    end)
end

local function turnBelly(ped, dir)
    local rot = cfgProne.rotations.belly[dir]
    local coords = GetEntityCoords(ped)
    TaskPlayAnimAdvanced(ped, DICT_CRAWL_FLIP, dir,
        coords.x, coords.y, coords.z,
        0.0, 0.0, GetEntityHeading(ped),
        2.0, 2.0, -1, 2, 0.1, false, false)
    lerpHeading(ped, rot, 300)
    Wait(750)
end

local function turnSupine(ped, dir)
    local dicts = {
        left  = DICT_SWEEP .. 'left',
        right = DICT_SWEEP .. 'right',
    }
    local clips = { left = 'left_to_prone', right = 'right_to_prone' }
    local rot = cfgProne.rotations.supine[dir]
    playAnimation(ped, dicts[dir], clips[dir])
    lerpHeading(ped, rot, 400)
    idleProne(ped, ANIM_PREFIX[PRONE_SUPINE])
    Wait(550)
end

---@param posture string
local function handleInput(posture)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local prefix = ANIM_PREFIX[posture]

    if vehicle ~= 0 then
        StopAnimTask(ped)
        if GetPedInVehicleSeat(vehicle, -1) ~= ped then return end
        ClearPedTasksImmediately(ped)
    end

    local fwd = IsControlPressed(0, 32)
    local bwd = IsControlPressed(0, 33)

    if not isMoving then
        if fwd then
            moveProne(ped, posture, 'fwd')
        elseif bwd then
            moveProne(ped, posture, 'bwd')
        end
    end

    if IsPedFalling(ped) then return end

    local left = IsControlPressed(0, 34)
    local right = IsControlPressed(0, 35)
    local dir = left and 'left' or right and 'right' or nil

    if not dir then
        if fwd or bwd then
            if IsPedInAnyVehicle(ped) then return end
            if IsEntityPlayingAnim(ped, DICT_CRAWL, prefix .. '_fwd', 3) then return end
        end
        idleProne(ped, prefix)
        return
    end

    if isMoving then
        local delta = (dir == 'left') and (fwd and 1.0 or -1.0) or (bwd and 1.0 or -1.0)
        SetEntityHeading(ped, GetEntityHeading(ped) + delta)
        return
    end

    isBusy = true
    if posture == PRONE_BELLY then
        turnBelly(ped, dir)
    else
        turnSupine(ped, dir)
    end
    isBusy = false
end

local function standUp()
    isBusy = true
    local ped = PlayerPedId()
    local steps = STANDUP_STEPS[injuredPosture]

    for _, step in ipairs(steps) do
        local dict, clip, dur = step[1], step[2], step[3]
        local blendIn = step[4]
        playAnimation(ped, dict, clip, { blendIn = blendIn, duration = dur })
        Wait(dur)
    end

    isBusy = false
end

local function injuredLoop()
    Wait(350)

    while isInjuredProne and Game.session:active() do
        disableProneControls()
        DisablePlayerFiring(PlayerPedId(), true)
        handleInput(injuredPosture)
        Wait(0)
    end

    standUp()
    DisablePlayerFiring(PlayerPedId(), false)

    isMoving = false
    isBusy = false
    injuredPosture = PRONE_BELLY
    RemoveAnimDict(DICT_CRAWL)
    RemoveAnimDict(DICT_CRAWL_FLIP)
end

---@param enabled boolean
local function setInjuredProne(enabled)
    if enabled then
        hadParachute = HasPedGotWeapon(PlayerPedId(), HASH_PARACHUTE)
    end

    if enabled == isInjuredProne then return end

    local ped = PlayerPedId()
    RemoveAllPedWeapons(ped)

    if isBusy then return end

    isManualProne = false

    if isInjuredProne then
        isInjuredProne = false
        if hadParachute then
            GiveWeaponToPed(ped, HASH_PARACHUTE, 1, true, false)
        end
        return
    end

    if not IsPedHuman(ped) then return end
    ClearPedTasksImmediately(ped)

    isBusy = true
    isInjuredProne = true

    if GetPedStealthMovement(ped) == 1 then
        SetPedStealthMovement(ped, false, 'DEFAULT_ACTION')
        Wait(80)
    end

    Game.requestAsset(DICT_CRAWL_FLIP, 'anim')
    Game.requestAsset(DICT_CRAWL, 'anim')
    idleProne(ped, ANIM_PREFIX[injuredPosture], nil, 3.0)
    isBusy = false

    CreateThread(injuredLoop)
end

Core._crawlSet = setInjuredProne

---@param ped number
---@return boolean
local function canGoProne(ped)
    if GetPedParachuteState(ped) ~= -1 then
        parachuteCooldown = GetGameTimer() + 4500
    end

    if not Game.session:active() or Game.session:currentPhase() ~= MatchState.STARTED then return false end
    if combatPhase ~= Status.STANDING then return false end
    if GetEntityHealth(ped) < 101 or not IsEntityVisible(ped) then return false end

    if not IsPedOnFoot(ped) or IsPedRagdoll(ped) or IsPedInjured(ped) then return false end
    if IsPedJumping(ped) or IsPedFalling(ped) or IsEntityInAir(ped) then return false end
    if GetEntityHeightAboveGround(ped) > 2.0 then return false end

    if IsPedInParachuteFreeFall(ped) or GetPedParachuteState(ped) ~= -1 then return false end
    if GetPedParachuteLandingType(ped) ~= -1 then return false end
    if parachuteCooldown > GetGameTimer() then return false end

    if IsPedInMeleeCombat(ped) or IsPedReloading(ped) or IsPedShooting(ped) then return false end

    return true
end

---@param ped number
local function flipPosture(ped)
    isFlipping = true
    local heading = GetEntityHeading(ped)

    if manualPosture == PRONE_BELLY then
        manualPosture = PRONE_SUPINE
        playAnimation(ped, DICT_SWEEP .. 'front', 'front_to_prone', { blendIn = 2.0 })
        lerpHeading(ped, cfgProne.flipRot.toSupine, 3400)
    else
        manualPosture = PRONE_BELLY
        playAnimation(ped, DICT_CRAWL_FLIP, 'back', { blendIn = 2.0 })
        lerpHeading(ped, cfgProne.flipRot.toBelly, 1600)
    end

    idleProne(ped, ANIM_PREFIX[manualPosture], heading + 180.0)
    Wait(350)
    isFlipping = false
end

local function proneLoop()
    Wait(350)

    while isManualProne and Game.session:active() do
        local ped = PlayerPedId()

        disableProneControls()
        DisablePlayerFiring(ped, true)

        if not canGoProne(ped) or IsEntityInWater(ped) then
            ClearPedTasks(ped)
            isManualProne = false
            break
        end

        handleInput(manualPosture)

        if not isFlipping and IsControlPressed(0, 22) then
            flipPosture(ped)
        end

        Wait(0)
    end

    standUp()
    DisablePlayerFiring(PlayerPedId(), false)

    parachuteCooldown = GetGameTimer() + 800
    isFlipping = false
    manualPosture = PRONE_BELLY
    RemoveAnimDict(DICT_CRAWL)
    RemoveAnimDict(DICT_CRAWL_FLIP)
end

local function toggleProne()
    if isBusy or isFlipping or isInjuredProne then return end
    if not Game.session:active() then return end
    if Game.session:currentPhase() ~= MatchState.STARTED then return end
    if IsPauseMenuActive() or IsNuiFocused() then return end

    if isManualProne then
        isManualProne = false
        return
    end

    local ped = PlayerPedId()
    if not canGoProne(ped) then return end
    if IsEntityInWater(ped) then return end
    if not IsPedHuman(ped) then return end

    isFlipping = true
    isManualProne = true

    if GetPedStealthMovement(ped) == 1 then
        SetPedStealthMovement(ped, false, 'DEFAULT_ACTION')
        Wait(80)
    end

    Game.requestAsset(DICT_CRAWL, 'anim')
    Game.requestAsset(DICT_CRAWL_FLIP, 'anim')

    if IsPedRunning(ped) or IsPedSprinting(ped) then
        playAnimation(ped, DICT_ENTER_RUN, CLIP_BLOWN, { blendOut = 3.0 })
        Wait(1050)
    else
        playAnimation(ped, DICT_ENTER_IDLE, 'enter')
        Wait(2800)
    end

    if canGoProne(ped) and not IsEntityInWater(ped) then
        idleProne(ped, ANIM_PREFIX[manualPosture], nil, 3.0)
    end

    isFlipping = false
    CreateThread(proneLoop)
end

RegisterCommand('br:crawl', function()
    toggleProne()
end, false)

RegisterKeyMapping('br:crawl', 'Rastejar', 'keyboard', cfgProne.key)

function Combat:onInjured()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local savedSeat = -2

    if vehicle ~= 0 then
        for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
            if GetPedInVehicleSeat(vehicle, seat) == ped then
                savedSeat = seat
                break
            end
        end
    end

    local coords = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetEntityInvincible(ped, true)

    pcall(Core.setCrawl, true)
    DisablePlayerFiring(PlayerId(), true)

    if vehicle ~= 0 and savedSeat ~= -2 and DoesEntityExist(vehicle) then
        CreateThread(function()
            Wait(100)
            local currentPed = PlayerPedId()
            if DoesEntityExist(vehicle) then
                SetPedIntoVehicle(currentPed, vehicle, savedSeat)
            end
        end)
    end

    CreateThread(function()
        local nextBleed = GetGameTimer() + 1000

        while combatPhase == Status.INJURED do
            local currentPed = PlayerPedId()

            DisablePlayerFiring(PlayerId(), true)
            for _, c in ipairs(cfgInjury.disabledControls) do
                DisableControlAction(0, c, true)
            end

            if GetGameTimer() >= nextBleed then
                nextBleed = GetGameTimer() + 1000

                if GetEntityHealth(currentPed) <= 101 then
                    Game.session:send('playerDeath', killerServerId, 0)
                    break
                end

                SetEntityHealth(currentPed, GetEntityHealth(currentPed) - cfgInjury.bleedDamage)
            end

            Wait(0)
        end
    end)
end

function Combat:onRevived()
    local ped = PlayerPedId()

    pcall(Core.setCrawl, false)
    ClearPedTasks(ped)
    SetEntityInvincible(ped, false)

    local maxHp = GetEntityMaxHealth(ped)
    local healAmount = math.floor(maxHp * cfgInjury.reviveHealth)
    SetEntityHealth(ped, healAmount)

    if Game.requestAsset(cfgInjury.getupAnim.dict, 'anim') then
        TaskPlayAnim(ped, cfgInjury.getupAnim.dict, cfgInjury.getupAnim.name, 8.0, -8.0, 2000, 0, 0, false, false, false)
    end
end

function Combat:onEliminated()
    local ped = PlayerPedId()
    pcall(Core.setCrawl, false)
    ClearPedTasks(ped)
    SetEntityInvincible(ped, false)
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end

    local ped = PlayerPedId()
    local victim = args[1]
    local attacker = args[2]
    local weaponHash = args[7]

    if victim ~= ped then return end

    if combatPhase ~= Status.STANDING then
        if (weaponHash == HASH_UNARMED or weaponHash == HASH_KNIFE) and combatPhase == Status.INJURED then
            SetPedCanRagdoll(ped, true)
            SetPedToRagdoll(ped, 2000, 2000, 0, 0, 0, 0)
        end
        return
    end

    local isDead = GetEntityHealth(ped) <= 100
    if not isDead then return end
    if hasSentDeath then return end

    hasSentDeath = true

    local srcId = 0

    if attacker and DoesEntityExist(attacker) and IsPedAPlayer(attacker) then
        local killerPlayer = NetworkGetPlayerIndexFromPed(attacker)
        if killerPlayer ~= -1 then
            srcId = GetPlayerServerId(killerPlayer)
        end
    end

    killerServerId = srcId
    Game.session:send('playerDeath', srcId, weaponHash)
end)

Game.session:onNet('playerState.update', function(src, newState)
    squadStates[src] = newState

    local localSrc = GetPlayerServerId(PlayerId())
    if src ~= localSrc then return end

    local oldPhase = combatPhase

    if newState == PlayerState.INJURED then
        combatPhase = Status.INJURED
        hasSentDeath = false
        Combat:onInjured()
    elseif newState == PlayerState.ALIVE and oldPhase == Status.INJURED then
        combatPhase = Status.STANDING
        hasSentDeath = false
        Combat:onRevived()
    elseif newState == PlayerState.DEAD then
        combatPhase = Status.ELIMINATED
        Combat:onEliminated()
    end
end)

---@return number | nil
function Combat:nearestDownedAlly()
    local ped = PlayerPedId()
    local myCoords = GetEntityCoords(ped)
    local nearest = nil
    local nearestDist = cfgInjury.reviveRange + 1

    for _, src in ipairs(Game.session.squad) do
        if squadStates[src] == PlayerState.INJURED then
            local playerId = GetPlayerFromServerId(src)
            if playerId ~= -1 then
                local targetPed = GetPlayerPed(playerId)
                if DoesEntityExist(targetPed) then
                    local dist = #(myCoords - GetEntityCoords(targetPed))
                    if dist <= cfgInjury.reviveRange and dist < nearestDist then
                        nearest = src
                        nearestDist = dist
                    end
                end
            end
        end
    end

    return nearest
end

function Combat:abortRevive()
    if not reviveActive then return end
    reviveActive = false
    reviveSrc = nil
    if reviveAbort then
        reviveAbort()
        reviveAbort = nil
    end
end

RegisterCommand('+br:revive', function()
    if combatPhase ~= Status.STANDING then return end
    if reviveActive then return end

    local targetSrc = Combat:nearestDownedAlly()
    if not targetSrc then return end

    reviveActive = true
    reviveSrc = targetSrc

    local ped = PlayerPedId()

    if Game.requestAsset(REVIVE_DICT, 'anim') then
        TaskPlayAnim(ped, REVIVE_DICT, 'idle_a', 8.0, -8.0, -1, 1, 0, false, false, false)
    end

    reviveAbort = Game.ui.holdAction({
        label = 'REANIMANDO',
        key = 'E',
        duration = cfgInjury.reviveTime,
        done = function()
            Game.session:send('playerRevive', reviveSrc)
            reviveActive = false
            reviveSrc = nil
            reviveAbort = nil
            ClearPedTasks(PlayerPedId())
        end,
        check = function()
            if not reviveActive then return true end

            local targetPlayer = GetPlayerFromServerId(reviveSrc)
            if targetPlayer == -1 then return true end

            local targetPed = GetPlayerPed(targetPlayer)
            if not DoesEntityExist(targetPed) then return true end

            local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(targetPed))
            if dist > cfgInjury.reviveRange then return true end

            if squadStates[reviveSrc] ~= PlayerState.INJURED then return true end

            return false
        end,
        fail = function()
            reviveActive = false
            reviveSrc = nil
            reviveAbort = nil
            ClearPedTasks(PlayerPedId())
        end,
    })
end, false)

RegisterCommand('-br:revive', function()
    Combat:abortRevive()
end, false)

RegisterKeyMapping('+br:revive', 'Revive Ally', 'keyboard', 'E')

function Combat:teardown()
    combatPhase = Status.STANDING
    reviveActive = false
    reviveSrc = nil
    reviveAbort = nil
    squadStates = {}
    killerServerId = 0
    hasSentDeath = false

    isInjuredProne = false
    isManualProne = false
    isMoving = false
    isBusy = false
    isFlipping = false
    injuredPosture = PRONE_BELLY
    manualPosture = PRONE_BELLY
    hadParachute = false

    local ped = PlayerPedId()
    ClearPedTasks(ped)
    SetEntityInvincible(ped, false)

    Game.ui.send('hud:action', { visible = false, type = nil, text = '', cancelKey = '', progress = 0 })
end
