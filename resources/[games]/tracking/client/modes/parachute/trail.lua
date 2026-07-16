--[[ Particles/trail dos pedestres durante queda livre e paraquedismo. ]]

local function parseBaseColor()
    local convarValue = GetConvar("serverBaseColor", "244, 235, 0, 180")
    local ok, color = pcall(function()
        local trimmed = convarValue:gsub("%s+", "")
        local r, g, b, a = trimmed:match("(%d+),(%d+),(%d+),(%d+)")
        return {
            r = tonumber(r),
            g = tonumber(g),
            b = tonumber(b),
            a = tonumber(a)
        }
    end)
    if not ok then
        return nil
    end
    if type(color) ~= "table" then
        return nil
    end
    if not color.r or not color.g or not color.b then
        return nil
    end
    return color
end

local baseColor = parseBaseColor()
if not baseColor then
    baseColor = {r = 244, g = 235, b = 0, a = 180}
end

local function normalize(value, min, max)
    if max == min then
        return 0
    end
    return (value - min) / (max - min)
end

local function rgbToFloat(r, g, b)
    return normalize(r, 0, 255), normalize(g, 0, 255), normalize(b, 0, 255)
end

local config = {}
config.parachute_parachuteModel = "p_parachute1_mp_s"
config.parachute_ajustParachuteModel = {
    left = {offSetX = -3.1, offSetY = -1.2, offSetZ = 0.4},
    right = {offSetX = 3.1, offSetY = -1.2, offSetZ = 0.4}
}
config.heightParachute = 4.0

local trackedPeds = {}
local effectThreadRunning = false
local parachuteBones = {right = 57005, left = 18905}

local function safeHash(value)
    if value then
        local hash = GetHashKey(value)
        if hash then
            return hash
        end
    end
    return nil
end

local parachuteModelHash = safeHash(config.parachute_parachuteModel)

local function ensurePedTracked(ped)
    if not ped or not DoesEntityExist(ped) then
        return false
    end
    if trackedPeds[ped] then
        return true
    end
    trackedPeds[ped] = {
        fallActive = false,
        chuteActive = false,
        usedParachute = false,
        particleLeft = nil,
        particleRight = nil,
        parachuteProp = nil
    }
    return true
end

local function removePedTracking(ped)
    local data = trackedPeds[ped]
    if not data then
        return false
    end
    if data.particleLeft and DoesParticleFxLoopedExist(data.particleLeft) then
        StopParticleFxLooped(data.particleLeft, false)
    end
    if data.particleRight and DoesParticleFxLoopedExist(data.particleRight) then
        StopParticleFxLooped(data.particleRight, false)
    end
    if data.parachuteProp and DoesEntityExist(data.parachuteProp) then
        RemoveParticleFxFromEntity(data.parachuteProp)
    end
    trackedPeds[ped] = nil
    return true
end

local function getOrCreatePedData(ped)
    if not trackedPeds[ped] then
        ensurePedTracked(ped)
    end
    return trackedPeds[ped]
end

local function requestPtfxAsset(assetName)
    RequestNamedPtfxAsset(assetName)
    while not HasNamedPtfxAssetLoaded(assetName) do
        Wait(10)
    end
    UseParticleFxAssetNextCall(assetName)
end

local function startTrailOnEntity(entity, assetName, effectName, offset, rotation, scale, color)
    if not entity or not DoesEntityExist(entity) then
        return nil
    end
    if type(assetName) ~= "string" or type(effectName) ~= "string" then
        return nil
    end
    requestPtfxAsset(assetName)
    local handle = StartParticleFxLoopedOnEntity(
        effectName,
        entity,
        offset.x or 0.0, offset.y or 0.0, offset.z or 0.0,
        rotation.x or 0.0, rotation.y or 0.0, rotation.z or 0.0,
        scale or 1.0,
        false, false, false
    )
    SetParticleFxLoopedColour(handle, color.r + 0.0, color.g + 0.0, color.b + 0.0, false)
    SetParticleFxLoopedAlpha(handle, 1.0)
    return handle
end

local function startTrailOnEntityBone(entity, assetName, effectName, boneIndex, rotation, scale, color)
    if type(assetName) ~= "string" or type(effectName) ~= "string" then
        return nil
    end
    requestPtfxAsset(assetName)
    local handle = StartParticleFxLoopedOnEntityBone(
        effectName,
        entity,
        0.0, 0.0, 0.0,
        rotation.x or 0.0, rotation.y or 0.0, rotation.z or 0.0,
        boneIndex,
        scale or 1.0,
        false, false, false
    )
    SetParticleFxLoopedColour(handle, color.r + 0.0, color.g + 0.0, color.b + 0.0, false)
    SetParticleFxLoopedAlpha(handle, 1.0)
    return handle
end

local function findAttachedParachuteProp(ped)
    if not parachuteModelHash or not ped or not DoesEntityExist(ped) then
        return nil
    end
    local objects = GetGamePool("CObject")
    for _, object in ipairs(objects) do
        if object and GetEntityModel(object) == parachuteModelHash then
            if IsEntityAttachedToEntity(object, ped) then
                return object
            end
        end
    end
    return nil
end

local function stopChuteParticles(ped)
    local data = getOrCreatePedData(ped)
    if data.particleLeft and DoesParticleFxLoopedExist(data.particleLeft) then
        StopParticleFxLooped(data.particleLeft, false)
    end
    if data.particleRight and DoesParticleFxLoopedExist(data.particleRight) then
        StopParticleFxLooped(data.particleRight, false)
    end
    data.particleLeft = nil
    data.particleRight = nil
    local coords = GetEntityCoords(ped)
    RemoveParticleFxInRange(coords.x, coords.y, coords.z, 10.0)
end

local function stopParachutePropParticles(ped)
    local data = getOrCreatePedData(ped)
    if not data then
        return
    end
    if data.parachuteProp and DoesEntityExist(data.parachuteProp) then
        RemoveParticleFxFromEntity(data.parachuteProp)
    end
end

local function applyParachutePropParticles(ped)
    local data = getOrCreatePedData(ped)
    if not data then
        return
    end
    data.parachuteProp = findAttachedParachuteProp(ped)
    if not data.parachuteProp then
        return
    end
    SetEntityProofs(data.parachuteProp, true, true, true, true, true, true, true, true)
    local rotation = vector3(0.0, 0.0, 0.0)
    local scale = 0.2
    local leftCfg = (config.parachute_ajustParachuteModel and config.parachute_ajustParachuteModel.left) or {}
    local rightCfg = (config.parachute_ajustParachuteModel and config.parachute_ajustParachuteModel.right) or {}
    local leftOffset = vector3(leftCfg.offSetX or -3.1, leftCfg.offSetY or -1.2, leftCfg.offSetZ or 0.4)
    local rightOffset = vector3(rightCfg.offSetX or 3.1, rightCfg.offSetY or -1.2, rightCfg.offSetZ or 0.4)
    local r, g, b = rgbToFloat(baseColor.r, baseColor.g, baseColor.b)
    local color = {r = r or 1.0, g = g or 1.0, b = b or 1.0, a = 1.0}
    startTrailOnEntity(data.parachuteProp, "scr_ar_planes", "scr_ar_trail_smoke", leftOffset, rotation, scale, color)
    startTrailOnEntity(data.parachuteProp, "scr_ar_planes", "scr_ar_trail_smoke", rightOffset, rotation, scale, color)
end

local function applyChuteParticles(ped)
    local data = getOrCreatePedData(ped)
    if not data then
        return
    end
    local r, g, b = rgbToFloat(baseColor.r, baseColor.g, baseColor.b)
    local color = {r = r or 1.0, g = g or 1.0, b = b or 1.0, a = 1.0}
    local rotation = vector3(0.0, 0.0, 0.0)
    local scale = 0.2
    data.particleLeft = startTrailOnEntityBone(
        ped, "scr_ar_planes", "scr_ar_trail_smoke",
        GetPedBoneIndex(ped, parachuteBones.left),
        rotation, scale, color
    )
    data.particleRight = startTrailOnEntityBone(
        ped, "scr_ar_planes", "scr_ar_trail_smoke",
        GetPedBoneIndex(ped, parachuteBones.right),
        rotation, scale, color
    )
end

local function handleChuteState(ped, enable)
    if not parachuteModelHash then
        return
    end
    if enable then
        stopParachutePropParticles(ped)
        applyParachutePropParticles(ped)
    else
        stopParachutePropParticles(ped)
    end
end

local function handleFallState(ped, enable)
    if enable then
        applyChuteParticles(ped)
    else
        stopChuteParticles(ped)
    end
end

local function updatePedEffects(ped)
    if not ped or not DoesEntityExist(ped) then
        return
    end
    local data = getOrCreatePedData(ped)
    if not data then
        return
    end

    local visible = IsEntityVisible(ped)
    local isFreeFalling = visible and IsPedInParachuteFreeFall(ped)
    local isChuteOpen = visible and GetPedParachuteState(ped) == 2

    if isFreeFalling and not data.fallActive then
        data.fallActive = true
        handleFallState(ped, true)
    end

    if data.fallActive and not isFreeFalling then
        Wait(IsEntityStatic(ped) and 1500 or 500)
        if not (IsEntityVisible(ped) and IsPedInParachuteFreeFall(ped)) then
            handleFallState(ped, false)
            data.fallActive = false
        end
    end

    if isChuteOpen and not data.chuteActive then
        data.chuteActive = true
        data.usedParachute = true
        local r, g, b = rgbToFloat(baseColor.r, baseColor.g, baseColor.b)
        if ped == PlayerPedId() then
            SetPlayerParachuteSmokeTrailColor(
                PlayerId(),
                math.floor(r or 1.0),
                math.floor(g or 1.0),
                math.floor(b or 1.0)
            )
            SetPlayerCanLeaveParachuteSmokeTrail(PlayerId(), true)
        end
        handleChuteState(ped, true)
    end

    if data.chuteActive and not isChuteOpen then
        Wait(IsEntityStatic(ped) and 1500 or 500)
        if not (IsEntityVisible(ped) and GetPedParachuteState(ped) == 2) then
            handleChuteState(ped, false)
            data.chuteActive = false
        end
    end

    local parachuteState = GetPedParachuteState(ped)
    local stateInProgress = parachuteState == 1 or parachuteState == 2
    if not visible and stateInProgress then
        ClearPedTasks(ped)
        ClearPedTasksImmediately(ped)
        data.chuteActive = false
        data.usedParachute = false
    end
end

local function getTrackedPedList()
    local list = {}
    for ped in pairs(trackedPeds) do
        list[#list + 1] = ped
    end
    return list
end

AddEventHandler("parachuteTraining:effect", function()
    if effectThreadRunning then
        return
    end
    effectThreadRunning = true
    while true do
        if not effectThreadRunning then break end
        if not trackedPeds then break end
        if not next(trackedPeds) then break end
        local list = getTrackedPedList()
        for i = 1, #list do
            local ped = list[i]
            if DoesEntityExist(ped) then
                updatePedEffects(ped)
            else
                removePedTracking(ped)
            end
        end
        Wait(200)
    end
    effectThreadRunning = false
end)

local function addPedToTrail(ped)
    pcall(function()
        ensurePedTracked(ped)
        if not effectThreadRunning then
            TriggerEvent("parachuteTraining:effect")
        end
    end)
end

AddPedToParachuteTrackingTrail = addPedToTrail

AddEventHandler("multiTracking:parachute:trail:remove", function(ped)
    removePedTracking(ped)
end)
