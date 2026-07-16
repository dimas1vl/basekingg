--[[ Cria, configura e monitora NPCs de parachute (modo tracking). ]]

local parachuteTintIndex = GetConvarInt("serverParachuteTintIndex", 1)
local baseBlipsColor = GetConvarInt("baseBlipsColor", 0)
local blipColor = baseBlipsColor
if not (baseBlipsColor and baseBlipsColor > 0) or not baseBlipsColor then
    blipColor = 46
end

local resourceName = GetCurrentResourceName()
local pedBlips = {}
local pedsController = MultiTrackingGetPedsController("parachute")
local configBuilder = GetGlobalConfigBuilder("parachute")
local lastSpawnAt = 0

local function getConfig(key, default)
    if configBuilder and configBuilder.get then
        local value = configBuilder.get(key)
        if value ~= nil then
            return value
        end
    end
    return default
end

local function createBlipForPed(ped)
    if not IsMapBlipsEnabled() then
        return nil
    end
    if pedBlips[ped] and DoesBlipExist(pedBlips[ped]) then
        return pedBlips[ped]
    end
    local blip = AddBlipForEntity(ped)
    SetBlipSprite(blip, 94)
    SetBlipColour(blip, blipColor)
    SetBlipScale(blip, 0.7)
    SetBlipAsShortRange(blip, false)
    SetBlipDisplay(blip, 2)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("\240\159\167\141")
    EndTextCommandSetBlipName(blip)
    pedBlips[ped] = blip
    return blip
end

local function randomizeSeed()
    local time = GetGameTimer()
    local s1 = tostring(time)
    local s2 = tostring(time)
    local s3 = tostring(collectgarbage("count"))
    local s4 = tostring(debug.getinfo(1).short_src)
    local combined = s1 .. s2 .. s3 .. s4
    local seed = 0
    for i = 1, #combined do
        seed = (seed * 131 + combined:byte(i)) % 2147483647
    end
    math.randomseed(seed)
end

local function getRandomOffsetCoords()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local function randomAxisOffset()
        randomizeSeed()
        if math.random() < 0.5 then
            return math.random(-120, -50)
        else
            return math.random(50, 120)
        end
    end

    local offsetX = randomAxisOffset()
    local offsetY = randomAxisOffset()
    randomizeSeed()
    local offsetZ = math.random(60, 100)
    return vector3(playerCoords.x + offsetX, playerCoords.y + offsetY, playerCoords.z + offsetZ)
end

local function getParachuteTargetCoords()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local randomCoords = getRandomOffsetCoords()
    return vector3(randomCoords.x, randomCoords.y, playerCoords.z)
end

local function applyParachuteTask(ped, useTaskParachuteToTarget)
    local target = getParachuteTargetCoords()
    if useTaskParachuteToTarget then
        TaskParachuteToTarget(ped, target.x, target.y, target.z)
    end
    SetParachuteTaskTarget(ped, target.x, target.y, target.z)
end

local function setupParachutePed(ped, tintIndex)
    if not ped or ped == 0 then
        print("^3 multi_tracking:setup ped - ped not found^0")
        return false
    end
    if not DoesEntityExist(ped) then
        print("^3 multi_tracking:setup ped - ped does not exist^0")
        return false
    end

    SetEntityMaxHealth(ped, 150)
    SetPedMaxHealth(ped, 150)
    SetEntityHealth(ped, 150)
    SetPedConfigFlag(ped, 363, true)
    FreezeEntityPosition(ped, true)
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, false, false)

    if not DoesEntityExist(ped) then
        print("^3 multi_tracking:setup ped - ped does not exist^0")
        return false
    end

    TaskParachute(ped, true)
    ClearPedParachutePackVariation(ped)
    SetPedParachuteTintIndex(ped, tintIndex or 1)
    SetPedReserveParachuteTintIndex(ped, tintIndex or 1)
    ForcePedToOpenParachute(ped)
    SetPedDefaultComponentVariation(ped)

    local clothes = GetMultiTrackingClothesByPedModel(GetEntityModel(ped))
    exports.clotheshop:changeClothesToPed(ped, clothes and clothes.clothes or nil)
    exports.barbershop:changeCharacteristicsToPed(ped, clothes and clothes.characteristics or nil)

    SetEntityVisible(ped, true, true)
    return true
end

local function configurePed(ped)
    if not setupParachutePed(ped, parachuteTintIndex or 1) then
        return false
    end
    createBlipForPed(ped)
    applyParachuteTask(ped, true)
    TriggerEvent("hitDamage:registerExtraEntity", ped)
    AddPedToParachuteTrackingTrail(ped)
    return true, ped
end

local function shouldStopMonitor(ped)
    applyParachuteTask(ped, false)
    local parachuteState = GetPedParachuteState(ped)
    local inFreeFallOrOpening = IsPedInParachuteFreeFall(ped) or parachuteState == 1 or parachuteState == 2
    local isFalling = not IsEntityInAir(ped) and not inFreeFallOrOpening and IsPedFalling(ped)
    local heightAboveGround = GetEntityHeightAboveGround(ped)
    if isFalling or (heightAboveGround and heightAboveGround < 10.0) then
        return true
    end
    return false
end

local function setupNpcClient()
    local spawnCoords = getRandomOffsetCoords()
    local ped = CreateMultiTrackingPed(spawnCoords)
    if not ped then
        return false
    end
    local ok, configuredPed = configurePed(ped)
    if not ok or not configuredPed then
        print("^3 multi_tracking:setupNpcClient - failed to setup ped^0")
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
        return false
    end
    if DoesEntityExist(configuredPed) then
        SetEntityCollision(configuredPed, false, false)
    end
    pedsController:registerNpc(configuredPed)
    pedsController:setMonitorHandler(shouldStopMonitor)
    pedsController:startMonitor()
    return true
end

local function checkTrackingParachutePeds()
    if getConfig("enabled", true) ~= true then
        if pedsController:getTrackedCount() > 0 then
            pedsController:deleteAll()
        end
        lastSpawnAt = 0
        return
    end

    local trackedCount = pedsController:getTrackedCount()
    local maxGeneratePeds = tonumber(getConfig("maxGeneratePeds", 6)) or 6
    if trackedCount >= maxGeneratePeds then
        return
    end
    if not IsEnabledMultiTracking() then
        return
    end

    local now = GetGameTimer()
    local spawnCooldownMs = tonumber(getConfig("spawnCooldownMs", 2000)) or 2000
    local remainingSlots = maxGeneratePeds - trackedCount
    local allowedSpawns = 0
    if spawnCooldownMs <= 0 then
        allowedSpawns = remainingSlots
    elseif lastSpawnAt == 0 then
        allowedSpawns = 1
    else
        allowedSpawns = math.floor((now - lastSpawnAt) / spawnCooldownMs)
    end

    if allowedSpawns <= 0 then
        return
    end

    local batchCap = 10
    local toSpawn = math.min(remainingSlots, allowedSpawns, batchCap)
    local spawnedCount = 0
    for _ = 1, toSpawn do
        if setupNpcClient() then
            spawnedCount = spawnedCount + 1
        else
            break
        end
    end

    if spawnedCount > 0 then
        if spawnCooldownMs <= 0 then
            lastSpawnAt = now
        elseif lastSpawnAt == 0 then
            lastSpawnAt = now
        else
            lastSpawnAt = math.min(now, lastSpawnAt + spawnedCount * spawnCooldownMs)
        end
    end
end

CheckTrackinParachutePeds = checkTrackingParachutePeds

AddEventHandler("onResourceStart", function(resource)
    if resource ~= resourceName then
        return
    end
    lastSpawnAt = 0
    pedsController:deleteAll()
end)

AddEventHandler("multiTracking:blips:changed", function(enabled)
    if enabled then
        for ped in pairs(pedsController.createdNpcs) do
            if DoesEntityExist(ped) then
                createBlipForPed(ped)
            end
        end
    else
        for ped, blip in pairs(pedBlips) do
            if blip and DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
            pedBlips[ped] = nil
        end
    end
end)

AddEventHandler("multiTracking:whenLeave", function()
    for ped in pairs(pedBlips) do
        pedBlips[ped] = nil
    end
end)
