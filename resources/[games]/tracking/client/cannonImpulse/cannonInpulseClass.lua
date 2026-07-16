--[[ Classe CannonImpulse: representa um canhao de impulso interagivel.
     Gerencia spawn do prop, anima sentar, dispara o player e abre paraquedas. ]]

local baseTextColor = GetConvar("serverBaseTextColor", "~y~")
local interFont = RegisterFontId("inter")

CannonImpulse = {}
CannonImpulse.__index = CannonImpulse

local SIT_ANIM_DICT = "anim@heists@prison_heistunfinished_biztarget_idle"
local SIT_ANIM_NAME = "target_idle"

local function getDistanceTo(ped, coords)
    return #(GetEntityCoords(ped) - coords)
end

function CannonImpulse:new(spawnCoords, rotation)
    local self = {}

    self.config = {
        model = -1110990529,
        spawnCoords = spawnCoords,
        rotation = rotation,
        drawTextOffset = vector3(0.3, 0.0, 1.2),
        sitOffset = vector3(1.7, 0.0, 1.1),
        sitOffsetRotation = vector3(0.0, 30.0, -90.0),
        launchAxisOffset = vector3(2.0, 0.0, 0.0),
        interactionDistance = 2.0,
        interactionRenderDistance = 10.0,
        sitKey = 38,
        fireKey = 38,
        cancelKey = 22,
        launchPower = 2800.0,
        launchBoostTicks = 16,
        launchBoostIntervalMs = 8,
        launchPitchOffset = 10.0,
        forceGlideDurationMs = 450,
        parachuteDeployControl = 144,
    }

    self.state = {
        object = nil,
        isSitting = false,
        isRunnigProximityThread = false,
    }

    setmetatable(self, CannonImpulse)
    return self
end

function CannonImpulse:requestModel(model)
    local hash = model
    if type(model) == "string" then
        hash = GetHashKey(model) or model
    end

    if not IsModelInCdimage(hash) then
        return false
    end

    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(10)
    end
    return true
end

function CannonImpulse:getDirectionFromPropAxis(prop, axisOffset)
    local origin = GetOffsetFromEntityInWorldCoords(prop, 0.0, 0.0, 0.0)
    local tip = GetOffsetFromEntityInWorldCoords(prop, axisOffset.x, axisOffset.y, axisOffset.z)

    local dx = tip.x - origin.x
    local dy = tip.y - origin.y
    local dz = tip.z - origin.z
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)

    if len <= 0.0 then
        return vector3(0.0, 1.0, 0.0)
    end
    return vector3(dx / len, dy / len, dz / len)
end

function CannonImpulse:applyPitchOffsetToDirection(direction, pitchDegrees)
    local horizontalLen = math.sqrt(direction.x * direction.x + direction.y * direction.y)
    local currentPitch = math.atan(direction.z, horizontalLen)
    local newPitch = currentPitch + math.rad(pitchDegrees + 0.0)
    local clampedPitch = math.max(math.rad(-25.0), math.min(math.rad(80.0), newPitch))

    local cosPitch = math.cos(clampedPitch)
    local nx, ny = 0.0, 1.0
    if horizontalLen > 1.0E-4 then
        nx = direction.x / horizontalLen
        ny = direction.y / horizontalLen
    end

    return vector3(nx * cosPitch, ny * cosPitch, math.sin(clampedPitch))
end

function CannonImpulse:getRotationWithOffset(prop, rotationOffset)
    local rot = GetEntityRotation(prop, 2)
    return vector3(rot.x + rotationOffset.x, rot.y + rotationOffset.y, rot.z + rotationOffset.z)
end

function CannonImpulse:forcePlayerGlide(ped)
    local startTime = GetGameTimer()
    local config = self.config
    CreateThread(function()
        Wait(40)
        while GetGameTimer() - startTime < config.forceGlideDurationMs do
            if not (DoesEntityExist(ped) and not IsEntityDead(ped)) then
                return
            end

            if IsControlPressed(0, config.parachuteDeployControl) or IsControlJustPressed(0, config.parachuteDeployControl) then
                return
            end

            if IsPedInParachuteFreeFall(ped) then
                return
            end

            TaskSkyDive(ped)
            Wait(120)
        end
    end)
end

function CannonImpulse:drawText3d(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end

    SetTextScale(0.25, 0.25)
    SetTextFont(interFont)
    SetTextProportional(true)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

function CannonImpulse:isSpawnedProp()
    local state = self.state
    return state.object and DoesEntityExist(state.object)
end

function CannonImpulse:spawnLauncher()
    local config = self.config
    local state = self.state

    if state.object and DoesEntityExist(state.object) then
        DeleteEntity(state.object)
        state.object = nil
        return
    end

    if not self:requestModel(config.model) then return end

    state.object = CreateObject(
        config.model,
        config.spawnCoords.x, config.spawnCoords.y, config.spawnCoords.z,
        false, false, false
    )

    FreezeEntityPosition(state.object, true)
    SetEntityRotation(state.object, config.rotation.x, config.rotation.y, config.rotation.z, 2, true)
    SetEntityInvincible(state.object, true)
    SetEntityCollision(state.object, false, false)
    SetEntityCanBeDamaged(state.object, false)
    SetModelAsNoLongerNeeded(config.model)
end

function CannonImpulse:sitPlayer()
    local state = self.state
    if not (state.object and DoesEntityExist(state.object)) then return end

    self:placePlayerOnSeat()
    self:playSeatAnimation()
    state.isSitting = true
end

function CannonImpulse:placePlayerOnSeat()
    local config = self.config
    local prop = self.state.object
    local ped = PlayerPedId()

    local seatCoords = GetOffsetFromEntityInWorldCoords(prop, config.sitOffset.x, config.sitOffset.y, config.sitOffset.z)
    local seatRotation = self:getRotationWithOffset(prop, config.sitOffsetRotation)

    SetEntityCoordsNoOffset(ped, seatCoords.x, seatCoords.y, seatCoords.z, false, false, false)
    SetEntityRotation(ped, seatRotation.x, seatRotation.y, seatRotation.z, 2, true)
end

function CannonImpulse:playSeatAnimation()
    local ped = PlayerPedId()

    RequestAnimDict(SIT_ANIM_DICT)
    while not HasAnimDictLoaded(SIT_ANIM_DICT) do
        Wait(10)
    end

    TaskPlayAnim(ped, SIT_ANIM_DICT, SIT_ANIM_NAME, 2.0, 2.0, -1, 1, 0.0, false, false, false)
    FreezeEntityPosition(ped, true)
end

function CannonImpulse:launchPlayer()
    local state = self.state
    if not (state.object and DoesEntityExist(state.object)) then return end

    pcall(function()
        local current = exports.weapons_system:getLastHudSelectedCategory()
        if not current or current == "fuzil" or current == "extra" then
            exports.weapons_system:equipWeaponByCategory("pistola", false)
        end
    end)

    local ped = self:releasePlayerFromSeat()
    local velocity = self:buildLaunchVelocity()
    SetEntityVelocity(ped, velocity.x, velocity.y, velocity.z)
    self:applyLaunchBoost(ped, velocity)
    self:forcePlayerGlide(ped)
end

function CannonImpulse:applyLaunchBoost(ped, velocity)
    local config = self.config
    local ticks = config.launchBoostTicks or 0
    if ticks <= 0 then return end

    CreateThread(function()
        for _ = 1, ticks, 1 do
            if not (DoesEntityExist(ped) and not IsEntityDead(ped)) then
                return
            end
            SetEntityVelocity(ped, velocity.x, velocity.y, velocity.z)
            Wait(config.launchBoostIntervalMs or 20)
        end
    end)
end

function CannonImpulse:releasePlayerFromSeat()
    local state = self.state
    local ped = PlayerPedId()

    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, false)
    state.isSitting = false
    return ped
end

function CannonImpulse:buildLaunchVelocity()
    local config = self.config
    local prop = self.state.object

    local direction = self:getDirectionFromPropAxis(prop, config.launchAxisOffset)
    local pitched = self:applyPitchOffsetToDirection(direction, config.launchPitchOffset)

    return vector3(
        pitched.x * config.launchPower,
        pitched.y * config.launchPower,
        pitched.z * config.launchPower
    )
end

function CannonImpulse:cleanup()
    local state = self.state
    local ped = PlayerPedId()

    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, false)
    state.isSitting = false

    if state.object and DoesEntityExist(state.object) then
        DeleteEntity(state.object)
        state.object = nil
    end
end

function CannonImpulse:processProximityTick()
    local config = self.config
    local state = self.state

    if not (state.object and DoesEntityExist(state.object)) then
        self:spawnLauncher()
        Wait(100)
    end

    local ped = PlayerPedId()
    local drawCoords = self:getDrawCoords()
    local distance = getDistanceTo(ped, drawCoords)

    if not state.isSitting and distance > config.interactionRenderDistance then
        return false
    end

    if state.isSitting then
        self:handleLaunchInteraction(drawCoords)
        return true
    end

    self:handleSeatInteraction(drawCoords, distance)
    return true
end

function CannonImpulse:getDrawCoords()
    local config = self.config
    local prop = self.state.object
    return GetOffsetFromEntityInWorldCoords(prop, config.drawTextOffset.x, config.drawTextOffset.y, config.drawTextOffset.z)
end

function CannonImpulse:handleSeatInteraction(coords, distance)
    local config = self.config
    self:drawText3d(coords, string.format("%s[E]~w~ \nUsar Canh\195\163o de Impulso~w~", baseTextColor))

    if IsControlJustPressed(0, config.sitKey) then
        if distance > config.interactionDistance then return end
        self:sitPlayer()
    end
end

function CannonImpulse:handleLaunchInteraction(coords)
    local config = self.config
    self:drawText3d(coords, string.format("%s[E]~w~ Disparar \n %s[ESPA\195\135O]~w~ Cancelar", baseTextColor, baseTextColor))

    if IsControlJustPressed(0, config.fireKey) then
        self:launchPlayer()
        return
    end

    if IsControlJustPressed(0, config.cancelKey) then
        self:releasePlayerFromSeat()
    end
end

function CannonImpulse:stop()
    self.state.isRunnigProximityThread = false
end

function CannonImpulse:start()
    local state = self.state
    if state.isRunnigProximityThread then return end
    state.isRunnigProximityThread = true

    while state.isRunnigProximityThread do
        local wait = 1000
        if self:processProximityTick() then
            wait = 0
        end
        Wait(wait)
    end

    self:cleanup()
end

function CannonImpulse:testThread()
    self:spawnLauncher()

    if self.state.object and DoesEntityExist(self.state.object) then
        Citizen.CreateThread(function()
            self:start()
        end)
        return
    end

    self:stop()
end
