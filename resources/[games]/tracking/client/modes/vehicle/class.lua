--[[ Classe TrackingVehiclesClass: encapsula spawn, playback e blip de um veiculo. ]]

local baseBlipsColor = GetConvarInt("baseBlipsColor", 0)
local defaultBlipColor = baseBlipsColor
if not (baseBlipsColor and baseBlipsColor > 0) or not baseBlipsColor then
    defaultBlipColor = 46
end

local truckRewardsLoadRecordFile = rawget(_G, "TruckRewardsLoadRecordFile")

local function requestModel(model)
    local modelHash
    if type(model) == "string" then
        modelHash = GetHashKey(model)
    else
        modelHash = model
    end
    if HasModelLoaded(modelHash) then
        return true
    end
    local attempts = 0
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) and attempts < 100 do
        Wait(50)
        attempts = attempts + 1
    end
    if not HasModelLoaded(modelHash) then
        print(('^3[tracking] requestModel failed: %s (hash=%s)^7'):format(tostring(model), tostring(modelHash)))
        return false
    end
    return true
end

local function requestVehicleRecording(routeId, routeName)
    if not routeId or not routeName then
        return false
    end
    local id = tonumber(routeId)
    if not id then
        return false
    end
    if HasVehicleRecordingBeenLoaded(id, routeName) then
        return true
    end
    RequestVehicleRecording(id, routeName)
    local attempts = 0
    while not HasVehicleRecordingBeenLoaded(id, routeName) and attempts < 100 do
        Wait(50)
        attempts = attempts + 1
    end
    return HasVehicleRecordingBeenLoaded(id, routeName)
end

TrackingVehiclesClass = {}
TrackingVehiclesClass.__index = TrackingVehiclesClass

function TrackingVehiclesClass:new(routeId, routeName, vehicleModel, vehicleConfig)
    local instance = {
        vehicleModel = vehicleModel or "seashark",
        vehicle = nil,
        ped = nil,
        blip = nil,
        monitoring = false,
        routeId = routeId,
        routeName = routeName,
        startRouteAt = nil,
        finishAt = nil,
        isAway = false,
        playbackSpeed = 1.0,
        vehicleConfig = vehicleConfig or {}
    }
    setmetatable(instance, TrackingVehiclesClass)
    return instance
end


---@return boolean
function TrackingVehiclesClass:isVehicleFinishedRoute()
    if not self.finishAt then return false end

    local vehicle = self.vehicle
    if not (vehicle and DoesEntityExist(vehicle)) then return true end
    if GetGameTimer() >= self.finishAt then return true end
    if IsEntityDead(vehicle) then return true end
    if self.ped and (not DoesEntityExist(self.ped) or IsEntityDead(self.ped) or IsPedDeadOrDying(self.ped, true)) then
        return true
    end
    if self.ped and self.aiPatrolMode and self.aiStartedAt and (GetGameTimer() - self.aiStartedAt) > 2000 then
        if not IsPedInVehicle(self.ped, vehicle, false) then return true end
    end
    if self.aiPatrolMode and self.aiStartedAt and (GetGameTimer() - self.aiStartedAt) > 2000 then
        local driver = GetPedInVehicleSeat(vehicle, -1)
        if not driver or driver == 0 or not DoesEntityExist(driver) then return true end
    end
    if self.aiPatrolMode then
        local modelHash = self.vehicleModel
        if type(modelHash) == "string" then modelHash = GetHashKey(modelHash) end
        local skipStuck = (IsThisModelAHeli  and IsThisModelAHeli(modelHash))
                       or (IsThisModelAPlane and IsThisModelAPlane(modelHash))
                       or (IsThisModelABoat  and IsThisModelABoat(modelHash))
        if not skipStuck and self.aiStartedAt and (GetGameTimer() - self.aiStartedAt) > 8000 then
            local pos = GetEntityCoords(vehicle)
            if not self.lastMovedAt then
                self.lastMovedPos = pos
                self.lastMovedAt  = GetGameTimer()
            else
                local dx = pos.x - self.lastMovedPos.x
                local dy = pos.y - self.lastMovedPos.y
                if (dx * dx + dy * dy) > 9.0 then
                    self.lastMovedPos = pos
                    self.lastMovedAt  = GetGameTimer()
                elseif (GetGameTimer() - self.lastMovedAt) > 8000 then
                    return true
                end
            end
        end
    end
    if self.aiPatrolMode then return false end
    if not IsPlaybackGoingOnForVehicle(vehicle) then return true end
    return false
end

function TrackingVehiclesClass:cleanup()
    if self.ped and DoesEntityExist(self.ped) then
        ClearPedTasksImmediately(self.ped)
        DeleteEntity(self.ped)
        self.ped = nil
    end
    if self.vehicle and DoesEntityExist(self.vehicle) then
        DeleteVehicle(self.vehicle)
        self.vehicle = nil
    end
    if self.blip then
        RemoveBlip(self.blip)
        self.blip = nil
    end
end

function TrackingVehiclesClass:destroy()
    self.destroyed = true
    self:cleanup()
    TriggerEvent("multiTracking:reloadVehicles")
end

function TrackingVehiclesClass:setStartRouteAt(time)
    if not time or not tonumber(time) then
        return
    end
    self.startRouteAt = time
end

function TrackingVehiclesClass:getRecordingDuration()
    local routeId = self.routeId
    local routeName = self.routeName
    if not routeId or not routeName then
        return nil
    end
    local id = tonumber(routeId)
    if not id or not routeName then
        return nil
    end
    if not requestVehicleRecording(id, routeName) then
        return nil
    end
    local totalMs = GetTotalDurationOfVehicleRecording(id, routeName)
    if not totalMs or totalMs <= 0.0 then
        return nil
    end
    return totalMs / 1000.0
end

function TrackingVehiclesClass:getRecordingCoordinatesAtSeconds(seconds)
    local routeId = self.routeId
    local routeName = self.routeName
    if not routeId or not routeName then
        return nil
    end
    local id = tonumber(routeId)
    if not id then
        return nil
    end
    local secs = tonumber(seconds) or 0
    if secs < 0 then
        secs = 0
    end

    if type(truckRewardsLoadRecordFile) == "function" then
        if not truckRewardsLoadRecordFile(id, routeName) then
            return nil
        end
    else
        if not requestVehicleRecording(id, routeName) then
            return nil
        end
    end

    local timeMs = (secs * 1000) + 0.0
    local coords = GetPositionOfVehicleRecordingAtTime(id, timeMs, routeName)
    if not coords then
        return nil
    end
    return coords
end

function TrackingVehiclesClass:setPlaybackSpeed(speed)
    local target = tonumber(speed)
    if not target then
        return self.playbackSpeed or 1.0
    end
    local clamped = math.max(0.1, math.min(3.0, target + 0.0))
    self.playbackSpeed = clamped
    local vehicle = self.vehicle
    if not (vehicle and DoesEntityExist(vehicle)) then
        return clamped
    end
    if not IsEntityAVehicle(vehicle) then
        return clamped
    end
    local ok, isPlaying = pcall(IsPlaybackGoingOnForVehicle, vehicle)
    if ok and isPlaying then
        pcall(SetPlaybackSpeed, vehicle, clamped)
    end
    return clamped
end

function TrackingVehiclesClass:startRecordPlayback(vehicle, routeId, routeName)
    if not vehicle then
        return
    end
    if not DoesEntityExist(vehicle) then
        return
    end
    if not IsVehicleDriveable(vehicle, false) then
        return
    end
    if not HasVehicleRecordingBeenLoaded(routeId, routeName) then
        return
    end
    local recordingStart = GetPositionOfVehicleRecordingAtTime(routeId, 0.0, routeName)
    local currentCoords = GetEntityCoords(vehicle)
    local distance = #(currentCoords - recordingStart)
    if distance >= 100.0 then
        SetEntityCoords(
            vehicle,
            recordingStart.x, recordingStart.y, recordingStart.z - 10.0,
            false, false, false, false
        )
        local attempts = 0
        while attempts < 30 do
            if not DoesEntityExist(vehicle) then
                break
            end
            local coords = GetEntityCoords(vehicle)
            if #(coords - recordingStart) < 100.0 then
                break
            end
            Wait(100)
            attempts = attempts + 1
        end
        Wait(20)
    end
    StartPlaybackRecordedVehicle(vehicle, routeId, routeName, false)
end

function TrackingVehiclesClass:playRecord()
    local vehicle = self.vehicle
    local routeId = self.routeId
    local routeName = self.routeName
    if not (vehicle and routeId) or not routeName then
        print("^3[truckRewards]^7 Failed to play record ^0 ", vehicle, routeId, routeName)
        return
    end
    if not IsEnabledMultiTracking() then
        return
    end

    local vehicleId = tonumber(vehicle)
    local routeIdNum = tonumber(routeId)
    local routeNameStr = tostring(routeName)
    routeName = routeNameStr
    if not routeIdNum or not routeName then
        return
    end
    if not (vehicleId and DoesEntityExist(vehicleId)) then
        return
    end
    if not requestVehicleRecording(routeIdNum, routeName) then
        -- Recording do assetpack indisponível — fallback pra IA nativa do GTA.
        self:playAiPatrol()
        return
    end

    local durationSeconds = self:getRecordingDuration()
    if not durationSeconds then
        self:playAiPatrol()
        return
    end

    if IsPlaybackGoingOnForVehicle(vehicleId) then
        StopPlaybackRecordedVehicle(vehicleId)
        Wait(0)
    end

    local elapsed = GetGameTimer() - self.startRouteAt
    if elapsed < 0 then
        elapsed = 0
    end
    local clampedElapsed = math.min(elapsed, durationSeconds)
    if clampedElapsed < 0 then
        clampedElapsed = 0
    end
    local _ = (tonumber(clampedElapsed) or 0) + 0.0

    if not HasVehicleRecordingBeenLoaded(routeIdNum, routeName) then
        print("^1[vehicleTracking] Recording not loaded:", routeIdNum, routeName)
        return
    end

    local segmentOffset = self.segmentOffset or 0
    local skipMs = math.min(segmentOffset * 1000, durationSeconds * 1000)

    self:startRecordPlayback(vehicleId, routeIdNum, routeName)
    Wait(100)

    if skipMs > 0 then
        SkipTimeInPlaybackRecordedVehicle(vehicleId, skipMs)
    end

    SetVehicleActiveDuringPlayback(vehicleId, true)
    pcall(SetPlaybackSpeed, vehicleId, self.playbackSpeed or 1.0)

    local playbackSpeed = self.playbackSpeed or 1.0
    local remainingSeconds = math.max(0, (durationSeconds - (self.segmentOffset or 0)) / playbackSpeed)
    self.finishAt = GetGameTimer() + math.ceil(remainingSeconds * 1000)

    SetTimeout(100, function()
        self:applyInvisible(false)
    end)
end

-- Fallback patrol usando IA nativa do GTA. Substitui o playback de recording.
-- O veículo nasce na zona, ATIRA EM DIREÇÃO AO PLAYER (passa por cima/perto
-- pra prática de tiro), e a thread interna repete o ciclo até o finishAt.
function TrackingVehiclesClass:playAiPatrol()
    local vehicle = self.vehicle
    local ped = self.ped
    if not (vehicle and DoesEntityExist(vehicle)) then return end
    if not (ped and DoesEntityExist(ped)) then return end

    self.aiPatrolMode = true
    self.aiStartedAt = GetGameTimer()

    local modelHash = self.vehicleModel
    if type(modelHash) == "string" then modelHash = GetHashKey(modelHash) end

    local isHeli  = IsThisModelAHeli  and IsThisModelAHeli(modelHash)  or false
    local isPlane = IsThisModelAPlane and IsThisModelAPlane(modelHash) or false
    local isBoat  = IsThisModelABoat  and IsThisModelABoat(modelHash)  or false

    SetEntityCollision(vehicle, true, true)
    FreezeEntityPosition(vehicle, false)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetEntityAsMissionEntity(vehicle, true, false)
    SetEntityAsMissionEntity(ped, true, false)

    local playerPed = PlayerPedId()
    SetEntityNoCollisionEntity(vehicle, playerPed, true)
    SetEntityNoCollisionEntity(playerPed, vehicle, true)
    if ped and ped ~= 0 then
        SetEntityNoCollisionEntity(ped, playerPed, true)
        SetEntityNoCollisionEntity(playerPed, ped, true)
    end

    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedKeepTask(ped, true)
    if SetDriverAbility        then SetDriverAbility(ped, 1.0) end
    if SetDriverAggressiveness then SetDriverAggressiveness(ped, 1.0) end

    SetEntityMaxHealth(ped, 150)
    SetEntityHealth(ped, 150)
    SetPedSuffersCriticalHits(ped, true)
    SetPedArmour(ped, 0)
    SetPedCanRagdollFromPlayerImpact(ped, true)
    SetPedDiesInVehicle(ped, true)
    SetPedDiesInstantlyInWater(ped, true)

    local config = self.vehicleConfig or {}
    local baseSpeed    = tonumber(config.driveSpeed)  or (isHeli and 50.0 or 40.0)
    local drivingStyle = tonumber(config.drivingStyle) or 524871

    local vc = GetEntityCoords(vehicle)
    local pc0 = GetEntityCoords(PlayerPedId())
    local heading = GetHeadingFromVector_2d(pc0.x - vc.x, pc0.y - vc.y)
    SetEntityHeading(vehicle, heading)
    SetVehicleOnGroundProperly(vehicle)

    local dx, dy = pc0.x - vc.x, pc0.y - vc.y
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1.0 then dx, dy, len = 1.0, 0.0, 1.0 end
    local nx, ny = dx / len, dy / len
    local pastDist = (isHeli or isPlane) and 250.0 or 80.0
    local rawTargetX = pc0.x + nx * pastDist
    local rawTargetY = pc0.y + ny * pastDist
    local rawTargetZ = pc0.z

    if isHeli or isPlane or isBoat then
        self.aiTargetX, self.aiTargetY, self.aiTargetZ = rawTargetX, rawTargetY, rawTargetZ
    else
        local snapped = false
        for nth = 1, 5 do
            local ok, nodePos = GetNthClosestVehicleNode(rawTargetX, rawTargetY, rawTargetZ, nth, 1, 3.0, 0)
            if ok and nodePos and nodePos.x and nodePos.x ~= 0 then
                self.aiTargetX, self.aiTargetY, self.aiTargetZ = nodePos.x, nodePos.y, nodePos.z
                snapped = true
                break
            end
        end
        if not snapped then
            self.aiTargetX, self.aiTargetY, self.aiTargetZ = rawTargetX, rawTargetY, rawTargetZ
        end
    end

    self:applyInvisible(false)

    local function applyTask()
        if not (self.vehicle and DoesEntityExist(self.vehicle)) then return end
        if not (self.ped     and DoesEntityExist(self.ped))     then return end

        local mul = 1.0
        local b = GetGlobalConfigBuilder and GetGlobalConfigBuilder('vehicles')
        if b and b.get then mul = tonumber(b.get('driveSpeedMultiplier')) or 1.0 end
        local cruise = baseSpeed * mul
        self.targetSpeed = cruise

        SetEntityMaxSpeed(self.vehicle, cruise * 1.5)
        if ModifyVehicleTopSpeed then pcall(ModifyVehicleTopSpeed, self.vehicle, mul) end
        pcall(SetVehicleEnginePowerMultiplier, self.vehicle, mul)
        pcall(SetVehicleEngineTorqueMultiplier, self.vehicle, mul)

        local tx, ty, tz = self.aiTargetX, self.aiTargetY, self.aiTargetZ

        if isHeli then
            TaskHeliMission(self.ped, self.vehicle, 0, 0,
                tx, ty, tz + 35.0,
                4, cruise, 5.0, -1.0, 35, 25, 0.5, 0)
        elseif isPlane then
            TaskPlaneMission(self.ped, self.vehicle, 0, 0,
                tx, ty, tz + 120.0,
                4, cruise, 0.0, 0.0, 1500, 120)
        else
            TaskVehicleDriveToCoord(self.ped, self.vehicle,
                tx, ty, tz,
                cruise, 1.0, GetEntityModel(self.vehicle), drivingStyle,
                20.0, true)
            SetDriveTaskDrivingStyle(self.ped, drivingStyle)
            SetDriveTaskCruiseSpeed(self.ped, cruise)
            SetDriverAggressiveness(self.ped, 1.0)
            SetDriverAbility(self.ped, 1.0)
        end
    end

    self.applyAiTask = applyTask
    applyTask()

    if not isPlane then
        local mul0 = 1.0
        local b0 = GetGlobalConfigBuilder and GetGlobalConfigBuilder('vehicles')
        if b0 and b0.get then mul0 = tonumber(b0.get('driveSpeedMultiplier')) or 1.0 end
        local cruise0 = baseSpeed * mul0
        pcall(SetVehicleForwardSpeed, vehicle, cruise0)
    end

    if not isPlane then
        CreateThread(function()
            while self.aiPatrolMode and not self.destroyed do
                if not (self.vehicle and DoesEntityExist(self.vehicle)) then break end
                local target = self.targetSpeed or baseSpeed
                if target > 30.0 then
                    local cur = GetEntitySpeed(self.vehicle)
                    if cur < target * 0.9 then
                        SetVehicleForwardSpeed(self.vehicle, target)
                    end
                end
                Wait(250)
            end
        end)
    end

    local approachThreshold = (isHeli or isPlane) and 70.0 or 35.0

    local instance = self
    instance.hasApproached = false
    CreateThread(function()
        while instance.aiPatrolMode and not instance.destroyed do
            if not (instance.vehicle and DoesEntityExist(instance.vehicle)) then break end

            local b = GetGlobalConfigBuilder and GetGlobalConfigBuilder('vehicles')
            local speedMul = (b and b.get and tonumber(b.get('driveSpeedMultiplier'))) or 1.0
            local farThreshold = ((isHeli or isPlane) and 280.0 or 180.0) * math.max(1.0, speedMul)

            local cur = GetEntityCoords(instance.vehicle)
            local pcc = GetEntityCoords(PlayerPedId())
            local dist = #(cur - pcc)

            if not instance.hasApproached and dist < approachThreshold then
                instance.hasApproached = true
            end

            if instance.hasApproached and dist > farThreshold then
                instance.finishAt = GetGameTimer() - 1
                break
            end

            applyTask()
            Wait(3000)
        end
    end)

    self.finishAt = GetGameTimer() + 40 * 1000
end

function TrackingVehiclesClass:applyVehicleFlags(vehicle)
    if not (vehicle and DoesEntityExist(vehicle)) then return end

    SetEntityInvincible(vehicle, false)
    SetEntityCanBeDamaged(vehicle, true)
    SetVehicleCanBeVisiblyDamaged(vehicle, false)
    SetVehicleStrong(vehicle, true)
    SetVehicleTyresCanBurst(vehicle, false)
    SetEntityProofs(vehicle, false, false, false, false, false, false, false, false)
    SetVehicleDeformationFixed(vehicle)
end

function TrackingVehiclesClass:applyRoute()
    if not IsEnabledMultiTracking() then
        return
    end
    local vehicle = self.vehicle
    if not (vehicle and DoesEntityExist(vehicle)) then
        return
    end
    local config = self.vehicleConfig or {}
    local proofs = config.proofs or {true, true, true, true, true, true, true, true}
    local isInvincible = config.isInvincible ~= false

    SetEntityProofs(
        vehicle,
        proofs[1] == true, proofs[2] == true, proofs[3] == true, proofs[4] == true,
        proofs[5] == true, proofs[6] == true, proofs[7] == true, proofs[8] == true
    )
    SetEntityInvincible(vehicle, isInvincible)
    self:playRecord()
end

function TrackingVehiclesClass:createBlipVehicle()
    local vehicle = self.vehicle
    if not vehicle then
        return nil
    end
    if self.blip and DoesBlipExist(self.blip) then
        return self.blip
    end
    local config = self.vehicleConfig or {}
    local blipConfig = config.vehicleBlipConfig or {}

    local sprite = tonumber(blipConfig.sprite) or 477
    local color = tonumber(blipConfig.color) or defaultBlipColor
    local scale = tonumber(blipConfig.scale) or 0.7
    local display = tonumber(blipConfig.display) or 6
    local shortRange = blipConfig.shortRange == true
    local showCone = blipConfig.showCone ~= false
    local showHeadingIndicator = blipConfig.showHeadingIndicator ~= false
    local name = blipConfig.name or "\240\159\154\154"
    local showOutlineIndicator = blipConfig.showOutlineIndicator and true or false
    local secondaryColor = blipConfig.secondaryColor or {r = 255, g = 255, b = 255}

    local blip = AddBlipForEntity(vehicle)
    self.blip = blip
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipScale(blip, scale)
    SetBlipDisplay(blip, display)
    SetBlipAsShortRange(blip, shortRange)
    SetBlipShowCone(blip, showCone)
    ShowHeadingIndicatorOnBlip(blip, showHeadingIndicator)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)
    SetBlipSecondaryColour(blip, secondaryColor.r, secondaryColor.g, secondaryColor.b)
    ShowOutlineIndicatorOnBlip(blip, showOutlineIndicator)
    return self.blip
end

function TrackingVehiclesClass:applyInvisible(invisible)
    if invisible then
        if self.vehicle and DoesEntityExist(self.vehicle) then
            SetEntityVisible(self.vehicle, false, false)
        end
        if self.ped and DoesEntityExist(self.ped) then
            SetEntityVisible(self.ped, false, false)
        end
    else
        if self.vehicle and DoesEntityExist(self.vehicle) then
            SetEntityVisible(self.vehicle, true, false)
        end
        if self.ped and DoesEntityExist(self.ped) then
            SetEntityVisible(self.ped, true, false)
        end
    end
end

function TrackingVehiclesClass:ensureBlip()
    local vehicle = self.vehicle
    if not (vehicle and DoesEntityExist(vehicle)) then
        return nil
    end
    if not IsMapBlipsEnabled() then
        if self.blip and DoesBlipExist(self.blip) then
            RemoveBlip(self.blip)
            self.blip = nil
        end
        return nil
    end
    if self.blip and DoesBlipExist(self.blip) then
        return self.blip
    end
    self.blip = self:createBlipVehicle()
    return self.blip
end

function TrackingVehiclesClass:createLocalVehicle(coords, heading)
    if not requestModel(self.vehicleModel) then
        print(('^3[tracking] createLocalVehicle aborted: model %s did not load^7'):format(tostring(self.vehicleModel)))
        return
    end
    if not IsEnabledMultiTracking() then
        return
    end

    local vehicle = CreateVehicle(self.vehicleModel, coords.x, coords.y, coords.z, heading, false, false)
    if not (vehicle and DoesEntityExist(vehicle)) then
        print(('^3[tracking] CreateVehicle returned 0 for %s at %.2f,%.2f,%.2f^7'):format(
            tostring(self.vehicleModel), coords.x, coords.y, coords.z))
        return
    end
    self.vehicle = vehicle
    SetVehicleOnGroundProperly(vehicle)

    local ped = CreateMultiTrackingPed(coords)
    if not (ped and DoesEntityExist(ped)) then
        print(('^3[tracking] driver ped failed for vehicle %s — keeping the vehicle parked^7'):format(tostring(self.vehicleModel)))
        self:applyVehicleFlags(vehicle)
        SetModelAsNoLongerNeeded(self.vehicleModel)
        SetVehicleDoorsLocked(vehicle, 2)
        SetEntityCollision(vehicle, true, true)
        FreezeEntityPosition(vehicle, false)
        self:ensureBlip()
        return vehicle
    end
    self.ped = ped

    local hasRecording = self.routeId
        and self.routeName
        and HasVehicleRecordingBeenLoaded(self.routeId, self.routeName)

    SetEntityVisible(vehicle, false, false)
    SetEntityVisible(ped, false, false)
    SetEntityAsMissionEntity(vehicle, true, false)
    SetEntityAsMissionEntity(ped, true, false)
    self:applyVehicleFlags(vehicle)
    SetModelAsNoLongerNeeded(self.vehicleModel)
    SetVehicleDoorsLocked(vehicle, 2)
    SetPedIntoVehicle(ped, vehicle, -1)

    if hasRecording then
        Wait(200)
        SetEntityCollision(vehicle, false, false)
        FreezeEntityPosition(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)
        Wait(200)

        self:ensureBlip()
        self:applyInvisible(true)
        self:applyRoute()
    else
        SetEntityCollision(vehicle, true, true)
        FreezeEntityPosition(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)
        SetVehicleOnGroundProperly(vehicle)
        self:ensureBlip()
        self:playAiPatrol()
    end

    return vehicle
end

function TrackingVehiclesClass:effectShow()
    local vehicle = self.vehicle
    local ped = self.ped
    if not (vehicle and DoesEntityExist(vehicle)) then
        return
    end
    if ped and DoesEntityExist(ped) then
        SetEntityVisible(ped, true, true)
        NetworkFadeInEntity(ped, true)
    end
    SetEntityVisible(vehicle, true, true)
    SetEntityCollision(vehicle, false, false)
    NetworkFadeInEntity(vehicle, true)
end

function TrackingVehiclesClass:effectHide()
    local vehicle = self.vehicle
    local ped = self.ped
    if not (vehicle and DoesEntityExist(vehicle)) then
        return
    end
    if ped and DoesEntityExist(ped) then
        SetEntityVisible(ped, false, false)
        NetworkFadeOutEntity(ped, true, true)
    end
    SetEntityVisible(vehicle, false, false)
    NetworkFadeOutEntity(vehicle, true, true)
    Wait(600)
end
