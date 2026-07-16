--[[ Modo "runner": logica de roll por mira do jogador + tick de movimento dos runners. ]]

local ROLL_ANIM_DURATION_MS = 900
local ROLL_COOLDOWN_MS = 1200
local isRollThreadRunning = false

DecorRegister("multiTrackingRunnerRolling", 3)

local function getAimedRunnerPed()
    local playerId = PlayerId()
    if not IsPlayerFreeAiming(playerId) then
        return nil
    end

    local hit, entity = GetEntityPlayerIsFreeAimingAt(playerId)
    if not hit then return nil end
    if type(entity) ~= "number" then return nil end
    if entity == 0 then return nil end
    if not DoesEntityExist(entity) then return nil end
    if not IsEntityAPed(entity) then return nil end

    return entity
end

local function isInRollCooldown(ped)
    if not DecorExistOn(ped, "multiTrackingRunnerRolling") then
        return false
    end

    local lastRollAtMs = DecorGetInt(ped, "multiTrackingRunnerRolling")
    return (GetGameTimer() - lastRollAtMs) < ROLL_COOLDOWN_MS
end

local function markRollStart(ped, nowMs)
    DecorSetInt(ped, "multiTrackingRunnerRolling", nowMs)

    local registry = GetRunnerPedsRegistry()
    if registry[ped] then
        registry[ped].rollAnimEndsAtMs = nowMs + ROLL_ANIM_DURATION_MS
    end
end

local function tryStartRollOnAimedPed()
    local aimedPed = getAimedRunnerPed()
    if not aimedPed then return end

    local registry = GetRunnerPedsRegistry()
    for ped, _ in pairs(registry) do
        if ped == aimedPed then
            if not isInRollCooldown(ped) then
                if PlayRollAnimation(ped, nil, ROLL_ANIM_DURATION_MS) then
                    markRollStart(ped, GetGameTimer())
                end
            end
        end
    end
end

local function isPedRolling(info)
    return info.rollAnimEndsAtMs ~= nil
end

local function clearRollAndReassign(ped, info, assignRunTask)
    info.wasRolling = false
    ClearPedTasks(ped)
    assignRunTask(ped, info)
end

local function tickRunnerMovement(ped, info, coords, assignRunTask, enforceRunVelocity)
    if isPedRolling(info) then
        info.wasRolling = true
        return
    end

    if info.wasRolling then
        clearRollAndReassign(ped, info, assignRunTask)
    end

    local distanceToTarget = #(coords.xy - info.target.xy)
    if distanceToTarget < 5.0 then
        assignRunTask(ped, info)
    end

    enforceRunVelocity(ped, info)
end
TickRunnerMovement = tickRunnerMovement

AddEventHandler("multiTracking:runner:client:startRollThread", function()
    if isRollThreadRunning then return end
    isRollThreadRunning = true

    local runnerConfig = GetGlobalConfigBuilder("runner")
    if not runnerConfig then return end

    local ok, err = pcall(function()
        while true do
            if not isRollThreadRunning then break end
            if not IsEnabledMultiTracking() then break end

            local waitMs = 1000
            if runnerConfig.get("aimRollEnabled") then
                waitMs = 1
                tryStartRollOnAimedPed()
            end

            Wait(waitMs)
        end
    end)

    if not ok then
        print(string.format("^3 multi_tracking:runner:roll - error: %s^0", err))
    end

    isRollThreadRunning = false
end)
