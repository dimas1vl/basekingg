local Airdrop = Game.module("airdrop")

local cfgDrop = Config.BR.airdrop

local PTFX_DICT = "core"
local PTFX_FLARE = "exp_grd_flare"
local PTFX_COLLECT = "scr_indep_fireworks"
local PTFX_COLLECT_NAME = "scr_indep_firework_starburst"

local DROP_MODEL = `p_secret_weapon_02`
local PARACHUTE_MODEL = `p_parachute1_mp_s`
local PARACHUTE_OFFSET = vector3(0.0, 0.0, 4.0)

local activeDropId = nil
local dropEntity = nil
local parachuteEntity = nil
local dropBlip = nil
local dropPos = nil
local dropLanded = false
local blipFlashing = false
local cancelHold = nil
local openingMe = false
local flareFxId = nil
local ptfxLoaded = {}

---@param dict string
---@return boolean
local function ensurePtfx(dict)
	if ptfxLoaded[dict] then
		return true
	end

	RequestNamedPtfxAsset(dict)

	local timeout = GetGameTimer() + 5000

	while not HasNamedPtfxAssetLoaded(dict) do
		if GetGameTimer() > timeout then
			return false
		end

		Wait(50)
	end

	ptfxLoaded[dict] = true
	return true
end

---@param dict string
local function releasePtfx(dict)
	if ptfxLoaded[dict] then
		RemoveNamedPtfxAsset(dict)
		ptfxLoaded[dict] = nil
	end
end

---@param x number
---@param y number
---@param highZ number
---@return number | nil
local function probeGround(x, y, highZ)
	for _ = 1, 30 do
		local ok, gz = GetGroundZFor_3dCoord(x, y, highZ, false)

		if ok then
			return gz
		end

		Wait(0)
	end

	return nil
end

local function removeParachute()
	if parachuteEntity and DoesEntityExist(parachuteEntity) then
		DetachEntity(parachuteEntity, false, false)
		Game.removeProp(parachuteEntity)
	end

	parachuteEntity = nil
end

local function cleanup()
	if cancelHold then
		cancelHold()
		cancelHold = nil
	end

	openingMe = false

	if flareFxId then
		StopParticleFxLooped(flareFxId, false)
		flareFxId = nil
	end

	removeParachute()

	Game.removeProp(dropEntity)
	dropEntity = nil

	Game.removeBlip(dropBlip)
	dropBlip = nil

	Game.prompts.unregister("airdrop")

	activeDropId = nil
	dropPos = nil
	dropLanded = false
	blipFlashing = false

	releasePtfx(PTFX_DICT)
	releasePtfx(PTFX_COLLECT)

	SetNuiFocus(false, false)
end

local function registerPrompt()
	Game.prompts.register({
		id = "airdrop",
		priority = 10,

		label = function()
			return "Abrir Airdrop"
		end,

		available = function()
			if not dropLanded then
				return false
			end

			if activeDropId == nil then
				return false
			end

			if openingMe then
				return false
			end

			if not dropPos then
				return false
			end

			local dist = #(GetEntityCoords(PlayerPedId()) - dropPos)

			return dist <= cfgDrop.collectRange
		end,

		position = function()
			if not dropPos then
				return nil
			end

			return vector3(dropPos.x, dropPos.y, dropPos.z + 1.0)
		end,

		execute = function() end,
		hold = true,
		zOffset = 0.5,
	})
end

function Airdrop:setup(ctx)
	cleanup()
end

function Airdrop:teardown(ctx)
	cleanup()
end

Game.session:onNet("airdrop.spawn", function(dropId, x, y, z, startHeight)
	print("receive airdrop spawn")
	cleanup()

	activeDropId = dropId
	dropPos = vector3(x, y, z)
	dropLanded = false
	blipFlashing = false

	dropBlip = Game.addBlip(dropPos, {
		icon = 94,
		color = 28,
		scale = 0.9,
		label = "Airdrop",
		shortRange = false,
		display = 2,
	})

	Game.ui.notify("Um airdrop foi lancado!", 5)

	CreateThread(function()
		local crateHash = Game.requestAsset(DROP_MODEL)

		if not crateHash then
			return
		end

		if activeDropId ~= dropId then
			return
		end

		local spawnZ = z + startHeight
		local groundZ = probeGround(x, y, spawnZ)
		local targetZ = groundZ or z

		dropPos = vector3(x, y, targetZ)

		if DoesBlipExist(dropBlip) then
			SetBlipCoords(dropBlip, x, y, targetZ)
		end

		dropEntity = CreateObject(crateHash, x, y, spawnZ, false, true, false)

		if not dropEntity or dropEntity == 0 then
			return
		end

		SetEntityAsMissionEntity(dropEntity, true, true)
		FreezeEntityPosition(dropEntity, true)
		SetEntityCollision(dropEntity, false, false)
		SetEntityLodDist(dropEntity, 500)

		local chuteHash = Game.requestAsset(PARACHUTE_MODEL)

		if chuteHash then
			parachuteEntity = CreateObject(chuteHash, x, y, spawnZ, false, true, false)

			if parachuteEntity and parachuteEntity ~= 0 then
				SetEntityAsMissionEntity(parachuteEntity, true, true)
				SetEntityLodDist(parachuteEntity, 500)
				SetEntityVisible(parachuteEntity, true)

				AttachEntityToEntity(
					parachuteEntity,
					dropEntity,
					0,
					PARACHUTE_OFFSET.x,
					PARACHUTE_OFFSET.y,
					PARACHUTE_OFFSET.z,
					0.0,
					0.0,
					0.0,
					false,
					false,
					false,
					false,
					2,
					true
				)
			end
		end

		SetModelAsNoLongerNeeded(crateHash)
		if chuteHash then
			SetModelAsNoLongerNeeded(chuteHash)
		end

		if ensurePtfx(PTFX_DICT) then
			UseParticleFxAssetNextCall(PTFX_DICT)
			flareFxId = StartParticleFxLoopedAtCoord(
				PTFX_FLARE,
				x,
				y,
				targetZ - 0.99,
				0.0,
				0.0,
				0.0,
				2.0,
				false,
				false,
				false,
				false
			)
		end

		local t0 = GetGameTimer()
		local duration = cfgDrop.descentDuration

		while activeDropId == dropId and not dropLanded and dropEntity do
			local t = (GetGameTimer() - t0) / duration

			if t >= 1.0 then
				t = 1.0
			end

			local currentZ = spawnZ + (targetZ - spawnZ) * t

			if DoesEntityExist(dropEntity) then
				SetEntityCoordsNoOffset(dropEntity, x, y, currentZ, false, false, false)
			end

			if t >= 1.0 then
				break
			end

			Wait(0)
		end
		if dropEntity and DoesEntityExist(dropEntity) then
			PlaceObjectOnGroundProperly(dropEntity)
		end
		if activeDropId ~= dropId then
			return
		end

		dropLanded = true
		print("dropLanded", dropId)
		if dropEntity and DoesEntityExist(dropEntity) then
			print("placing object on ground")
			PlaceObjectOnGroundProperly(dropEntity)
			FreezeEntityPosition(dropEntity, true)
			SetEntityCollision(dropEntity, true, true)
		end

		removeParachute()

		Game.session:send("airdrop.clientLanded", dropId)

		registerPrompt()
	end)
end)

Game.session:onNet("airdrop.landed", function(dropId)
	if activeDropId ~= dropId then
		return
	end

	if dropLanded then
		return
	end

	dropLanded = true

	removeParachute()

	if dropEntity and DoesEntityExist(dropEntity) and dropPos then
		SetEntityCoordsNoOffset(dropEntity, dropPos.x, dropPos.y, dropPos.z, false, false, false)
		FreezeEntityPosition(dropEntity, true)
		SetEntityCollision(dropEntity, true, true)
	end

	registerPrompt()
end)

Game.session:listen("interact.pressed", function()
	if not dropLanded then
		return
	end

	if activeDropId == nil then
		return
	end

	if openingMe then
		return
	end

	if not dropPos then
		return
	end

	local dist = #(GetEntityCoords(PlayerPedId()) - dropPos)

	if dist > cfgDrop.collectRange then
		return
	end

	openingMe = true

	Game.session:send("airdrop.startOpen", activeDropId)

	local currentDropId = activeDropId

	cancelHold = Game.ui.holdAction({
		label = "Abrindo Airdrop",
		key = "E",
		duration = 10000,

		done = function()
			cancelHold = nil
		end,

		fail = function()
			cancelHold = nil

			if openingMe then
				openingMe = false

				if activeDropId == currentDropId then
					Game.session:send("airdrop.cancelOpen", currentDropId)
				end
			end
		end,

		check = function()
			if activeDropId ~= currentDropId then
				return true
			end

			if not dropPos then
				return true
			end

			local ped = PlayerPedId()

			if IsEntityDead(ped) then
				return true
			end

			local d = #(GetEntityCoords(ped) - dropPos)

			return d > cfgDrop.collectRange * 2
		end,

		onProgress = function(pct)
			Game.prompts.setHoldProgress(pct)
		end,
	})
end)

Game.session:listen("interact.released", function()
	if not openingMe then
		return
	end

	if cancelHold then
		cancelHold()
		cancelHold = nil
	end
end)

Game.session:onNet("airdrop.opening", function(dropId, openerSrc)
	if activeDropId ~= dropId then
		return
	end

	blipFlashing = true

	CreateThread(function()
		local toggle = false

		while blipFlashing and activeDropId == dropId do
			if DoesBlipExist(dropBlip) then
				SetBlipColour(dropBlip, toggle and 1 or 28)
			end

			toggle = not toggle
			Wait(300)
		end

		if DoesBlipExist(dropBlip) then
			SetBlipColour(dropBlip, 28)
		end
	end)
end)

Game.session:onNet("airdrop.idle", function(dropId)
	if activeDropId ~= dropId then
		return
	end

	blipFlashing = false

	if cancelHold then
		cancelHold()
		cancelHold = nil
	end

	openingMe = false
end)

Game.session:onNet("airdrop.opened", function(dropId)
	if activeDropId ~= dropId then
		return
	end

	blipFlashing = false
	openingMe = false

	if cancelHold then
		cancelHold()
		cancelHold = nil
	end

	Game.prompts.unregister("airdrop")

	SetNuiFocus(true, true)
	Game.ui.send("airdrop:show", true)
end)

Game.session:onNet("airdrop.remove", function(dropId)
	if activeDropId ~= dropId then
		return
	end

	cleanup()

	if dropPos and ensurePtfx(PTFX_COLLECT) and dropPos.x then
		UseParticleFxAssetNextCall(PTFX_COLLECT)
		StartParticleFxNonLoopedAtCoord(
			PTFX_COLLECT_NAME,
			dropPos.x,
			dropPos.y,
			dropPos.z + 1.0,
			0.0,
			0.0,
			0.0,
			2.0,
			false,
			false,
			false
		)
	end
end)

Game.session:onNet("airdrop.notify", function(text)
	Game.ui.notify(text, 5)
end)

Game.session:onNet("airdrop.reviveTeleport", function(x, y, z)
	local ped = PlayerPedId()

	if IsEntityDead(ped) then
		NetworkResurrectLocalPlayer(x, y, z, 0.0, true, false)
		ped = PlayerPedId()
	end

	SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
	ClearPedTasks(ped)
	ClearPedBloodDamage(ped)
	SetEntityHealth(ped, GetEntityMaxHealth(ped))
	SetPedArmour(ped, 0)
	FreezeEntityPosition(ped, false)
	SetEntityVisible(ped, true)
	SetEntityInvincible(ped, false)

	Game.ui.notify("Voce foi revivido pelo airdrop!", 5)
end)

RegisterNUICallback("getAbilities", function(_, cb)
	cb({
		{ id = "vant", title = "VANT", description = "REVELAR\nINIMIGOS" },
		{ id = "radar", title = "RADAR", description = "REVELAR PROXIMA\nSAFE" },
		{ id = "revive", title = "REVIVE", description = "REVIVER TODOS\nOS ALIADOS" },
	})
end)

RegisterNUICallback("selectAbility", function(data, cb)
	SetNuiFocus(false, false)

	if activeDropId and data and data.id then
		Game.session:send("airdrop.select", activeDropId, data.id)
	end

	cb({ success = true })
end)

RegisterNUICallback("airdrop:close", function(_, cb)
	SetNuiFocus(false, false)
	cb({})
end)

AddEventHandler("onResourceStop", function(resource)
	if resource == GetCurrentResourceName() then
		cleanup()
	end
end)
