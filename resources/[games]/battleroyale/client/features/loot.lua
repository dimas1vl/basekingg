local Loot = Game.module("loot")

local REVIVE_DICT = Config.BR.anims.revive

local CHEST_LOD = Config.BR.loot.chestLod
local CHEST_OPEN_TIME = Config.BR.loot.chestOpenTime
local CHEST_INTERACT_RANGE = Config.BR.loot.chestInteractRange
local PICKUP_LOD = Config.BR.loot.pickupLod
local PICKUP_INTERACT_RANGE = Config.BR.loot.pickupInteractRange

local CHEST_DEFS = Config.BR.loot.chests

local CHEST_CATEGORIES = {}
local CHEST_MODELS = {}
for _, def in ipairs(CHEST_DEFS) do
	CHEST_CATEGORIES[#CHEST_CATEGORIES + 1] = def.category
	CHEST_MODELS[def.category] = GetHashKey(def.model)
end

local MODEL_TO_ITEM = {}

for itemName, def in pairs(GItems) do
	if def.model then
		MODEL_TO_ITEM[GetHashKey(def.model)] = itemName
	end
end

local WEAPON_CHEST_TYPES = { RIFLE = true, SUB = true }

local function getOwnedWeapons()
	local owned = {}
	for _, data in pairs(gInventory) do
		local itemDef = GItems[data.index]
		if itemDef and itemDef.ammo then
			owned[data.index] = true
		end
	end
	return owned
end

local PICKUP_COOLDOWN_MS = 1000

local allChests = {}
local visibleChests = {}
local pickups = {}
local opening = false
local outlinedEntity = nil
local pickupCooldown = 0
local spawnPoints = gLootCoords
local activeCancel = nil
local pendingRelease = false

---@param seed number
local function GenerateChests(seed)
	allChests = {}

	local sz = Config.BR.safezone
	local cx, cy = sz.initialCenter.x, sz.initialCenter.y
	local radiusSq = sz.initialRadius * sz.initialRadius
	local spawnChance = Config.BR.loot.chestSpawnChance
	local typeCount = #CHEST_CATEGORIES

	for idx, point in ipairs(spawnPoints) do
		if LootRng.spawnRoll(seed, idx) < spawnChance then
			local px, py, pz, heading = point[1], point[2], point[3], point[4]
			local dx, dy = px - cx, py - cy

			if (dx * dx + dy * dy) >= radiusSq then
				goto skip
			end

			local category = CHEST_CATEGORIES[LootRng.typeIndex(seed, idx, typeCount)]

			allChests[idx] = {
				pos = vector3(px, py, pz),
				heading = heading,
				chestType = category,
				entity = nil,
			}
		end

		::skip::
	end
end

---@return boolean
local function isInteractionAllowed()
	if opening then
		return false
	end
	if Core._busy and Core._busy() then
		return false
	end
	if IsPedInAnyVehicle(PlayerPedId(), false) then
		return false
	end
	return true
end

---@return number | nil idx
---@return table | nil chest
local function findClosestChest()
	local origin = GetEntityCoords(PlayerPedId())
	local bestIdx, bestChest, bestDist = nil, nil, CHEST_INTERACT_RANGE + 1

	for idx, chest in pairs(visibleChests) do
		local ref = (chest.entity and DoesEntityExist(chest.entity)) and GetEntityCoords(chest.entity) or chest.pos
		local d = #(origin - ref)

		if d < bestDist then
			bestIdx = idx
			bestChest = chest
			bestDist = d
		end
	end

	return bestIdx, bestChest
end

---@return number | nil idx
---@return table | nil pickup
local function findClosestPickup()
	local origin = GetEntityCoords(PlayerPedId())
	local bestIdx, bestPickup, bestDist = nil, nil, PICKUP_INTERACT_RANGE + 1

	for idx, p in pairs(pickups) do
		if not p.entity or not DoesEntityExist(p.entity) then
			goto next
		end

		local ref = GetEntityCoords(p.entity)
		local d = #(origin - ref)

		if d < bestDist then
			bestIdx = idx
			bestPickup = p
			bestDist = d
		end

		::next::
	end

	return bestIdx, bestPickup
end

---@param chest table
local function destroyChestEntity(chest)
	if chest.entity and DoesEntityExist(chest.entity) then
		SetEntityVisible(chest.entity, false)
		DeleteEntity(chest.entity)
		chest.entity = nil
	end
end

function Loot:setup(ctx)
	ctx.tracker = Game.Tracker.new()
	allChests = {}
	visibleChests = {}
	pickups = {}
	opening = false
	outlinedEntity = nil
	pickupCooldown = 0
	activeCancel = nil
	pendingRelease = false
end

function Loot:activate(ctx)
	local chestCount = 0
	for _ in pairs(allChests) do
		chestCount = chestCount + 1
	end
	print(("[loot] activate called — allChests=%d pickups=%d"):format(chestCount, 0))

	ctx:poll(800, function()
		self:updateChestLOD()
	end)

	ctx:poll(400, function()
		self:updatePickupLOD()
	end)

	ctx:tick(function()
		local ft = GetFrameTime()
		self:updatePickupEffects()
		Wait(ft * 1000 / 60)
	end)
end

function Loot:teardown(ctx)
	for _, chest in pairs(allChests) do
		if chest.entity and DoesEntityExist(chest.entity) then
			DeleteEntity(chest.entity)
		end
	end

	for _, p in pairs(pickups) do
		if p.entity and DoesEntityExist(p.entity) then
			DeleteEntity(p.entity)
		end
	end

	for _, h in pairs(CHEST_MODELS) do
		SetModelAsNoLongerNeeded(h)
	end
	allChests = {}
	visibleChests = {}
	pickups = {}
	opening = false
	outlinedEntity = nil
	pickupCooldown = 0
	activeCancel = nil
	pendingRelease = false

	ctx.tracker:flush()
end

function Loot:updateChestLOD()
	visibleChests = {}
	local cam = GetFinalRenderedCamCoord()

	for idx, chest in pairs(allChests) do
		local dist = #(chest.pos - cam)

		if dist <= CHEST_LOD then
			visibleChests[idx] = chest

			if not chest.entity or not DoesEntityExist(chest.entity) then
				local modelHash = CHEST_MODELS[chest.chestType]
				if modelHash and HasModelLoaded(modelHash) then
					local obj = CreateObject(modelHash, chest.pos.x, chest.pos.y, chest.pos.z, false, false, false)
					PlaceObjectOnGroundProperly(obj)
					SetEntityHeading(obj, chest.heading)
					SetEntityCollision(obj, false, false)
					FreezeEntityPosition(obj, true)
					chest.entity = obj
				end
			end
		else
			if chest.entity and DoesEntityExist(chest.entity) then
				DeleteEntity(chest.entity)
			end

			chest.entity = nil
		end
	end
end

function Loot:updatePickupLOD()
	local cam = GetFinalRenderedCamCoord()

	for idx, p in pairs(pickups) do
		local dist = #(cam - p.pos)

		if dist <= PICKUP_LOD then
			if not p.entity or not DoesEntityExist(p.entity) then
				if HasModelLoaded(p.model) then
					local obj = CreateObject(p.model, p.pos.x, p.pos.y, p.pos.z, false, false, false)
					PlaceObjectOnGroundProperly(obj)
					local groundPos = GetEntityCoords(obj)
					SetEntityCoordsNoOffset(obj, groundPos.x, groundPos.y, groundPos.z + 0.5, false, false, false)
					p.entity = obj
					FreezeEntityPosition(obj, true)
					SetEntityCollision(obj, false, false)
					SetEntityAlpha(obj, 220, false)
				end
			end
		else
			if p.entity and DoesEntityExist(p.entity) then
				DeleteEntity(p.entity)
			end

			p.entity = nil
		end
	end
end

function Loot:updatePickupEffects()
	local _, closest = findClosestPickup()
	local newOutline = closest and closest.entity or nil

	if newOutline ~= outlinedEntity then
		if outlinedEntity and DoesEntityExist(outlinedEntity) then
			SetEntityDrawOutline(outlinedEntity, false)
		end

		if newOutline and DoesEntityExist(newOutline) then
			SetEntityDrawOutline(newOutline, true)
			SetEntityDrawOutlineColor(255, 255, 255, 100)
		end

		outlinedEntity = newOutline
	end

	for _, p in pairs(pickups) do
		if p.entity and DoesEntityExist(p.entity) then
			local heading = GetEntityHeading(p.entity) + 1
			SetEntityHeading(p.entity, heading)
		end
	end
end

Game.session:onNet("chest.seed", function(seed)
	print(("[loot] chest.seed received — seed=%s spawnPoints=%d"):format(tostring(seed), #spawnPoints))

	if not spawnPoints or #spawnPoints == 0 then
		print("[loot] WARNING: no spawnPoints loaded, chests will not generate")
		return
	end

	GenerateChests(seed)

	local count = 0
	for _ in pairs(allChests) do
		count = count + 1
	end

	print(("[loot] generated %d chests from seed %s"):format(count, tostring(seed)))

	for _, def in ipairs(CHEST_DEFS) do
		Game.requestAsset(def.model, "model")
	end
end)

Game.session:onNet("chest.opened", function(chestIdx)
	print(("[loot] chest.opened received — chestIdx=%s"):format(tostring(chestIdx)))

	local chest = allChests[chestIdx]

	if not chest then
		print(("[loot] WARNING: chest %s not found in allChests"):format(tostring(chestIdx)))
		return
	end

	visibleChests[chestIdx] = nil
	destroyChestEntity(chest)
	allChests[chestIdx] = nil
end)

Game.session:onNet("pickup.created", function(pickupIdx, modelHash, coords)
	print(("[loot] pickup.created received — idx=%s model=%s"):format(tostring(pickupIdx), tostring(modelHash)))

	pickups[pickupIdx] = {
		model = modelHash,
		pos = vector3(coords[1], coords[2], coords[3]),
		entity = nil,
	}

	RequestModel(modelHash)
end)

Game.session:onNet("pickup.taken", function(pickupIdx)
	local p = pickups[pickupIdx]

	if not p then
		return
	end

	if p.entity and DoesEntityExist(p.entity) then
		DeleteEntity(p.entity)
	end

	pickups[pickupIdx] = nil
end)

Game.prompts.register({
	id = "loot_chest",
	priority = 5,
	label = function()
		local _, chest = findClosestChest()

		if not chest then
			return nil
		end

		return "ABRIR"
	end,
	available = function()
		if Game.session:currentPhase() ~= MatchState.STARTED then
			return false
		end

		local _, chest = findClosestChest()

		return chest ~= nil
	end,
	position = function()
		local _, chest = findClosestChest()
		if not chest then
			return nil
		end
		if chest.entity and DoesEntityExist(chest.entity) then
			return GetEntityCoords(chest.entity)
		end
		return chest.pos - vec3(0, 0, 0.8)
	end,
	zOffset = 1.1,
	worldWidth = 0.8,
	worldHeight = 1.6,
	execute = function() end,
})

Game.prompts.register({
	id = "loot_pickup",
	priority = 4,
	label = function()
		local _, pickup = findClosestPickup()

		if not pickup then
			return nil
		end

		local itemName = MODEL_TO_ITEM[pickup.model]

		if not itemName then
			return nil
		end

		local def = GItems[itemName]
		return ("PEGAR %s"):format(def and def.name or itemName)
	end,
	available = function()
		if opening then
			return false
		end
		if Game.session:currentPhase() ~= MatchState.STARTED then
			return false
		end
		if GetGameTimer() < pickupCooldown then
			return false
		end

		local _, pickup = findClosestPickup()

		if not pickup then
			return false
		end

		local itemName = MODEL_TO_ITEM[pickup.model]

		if not itemName then
			return false
		end

		return getFreeSpace(itemName) > 0
	end,
	position = function()
		local _, pickup = findClosestPickup()
		if not pickup then
			return nil
		end
		if pickup.entity and DoesEntityExist(pickup.entity) then
			return GetEntityCoords(pickup.entity)
		end
		return pickup.pos
	end,
	zOffset = 0.3,
	execute = function() end,
})

Game.session:listen("interact.pressed", function()
	if not Game.session:active() or pickupCooldown > GetGameTimer() then
		return
	end

	if Game.session:currentPhase() ~= MatchState.STARTED then
		return
	end
	if not isInteractionAllowed() then
		return
	end

	local ped = PlayerPedId()

	local chestIdx, chest = findClosestChest()

	if not chest then
		local pickupIdx, pickup = findClosestPickup()

		if pickup then
			local itemName = MODEL_TO_ITEM[pickup.model]

			if itemName and getFreeSpace(itemName) > 0 then
				PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
				Game.session:send("pickup.take", pickupIdx)
			end
		end

		return
	end

	opening = true
	pendingRelease = false
	activeCancel = nil
	Core._setBusy(true)

	local openDict = "anim@heists@money_grab@briefcase"
	local loopDict = "anim@heists@money_grab@duffel"

	Game.requestAsset(openDict, "anim")
	Game.requestAsset(loopDict, "anim")

	if pendingRelease then
		opening = false
		Core._setBusy(false)
		return
	end

	TaskPlayAnim(ped, openDict, "enter", 8.0, -8.0, -1, 0, 0, false, false, false)

	CreateThread(function()
		Wait(1000)
		if opening then
			TaskPlayAnim(PlayerPedId(), loopDict, "loop", 8.0, -8.0, -1, 0, 0, false, false, false)
		end
	end)

	activeCancel = Game.ui.holdAction({
		label = "ABRINDO BAU",
		key = "E",
		duration = CHEST_OPEN_TIME,
		onProgress = function(pct)
			Game.prompts.setHoldProgress(pct)
		end,
		done = function()
			opening = false
			activeCancel = nil
			ClearPedTasks(PlayerPedId())
			pickupCooldown = GetGameTimer() + PICKUP_COOLDOWN_MS

			Core._setBusy(false)

			if WEAPON_CHEST_TYPES[chest.chestType] then
				Game.session:send("chest.open", chestIdx, getOwnedWeapons())
			else
				Game.session:send("chest.open", chestIdx)
			end
		end,
		check = function()
			local ref = (chest.entity and DoesEntityExist(chest.entity)) and GetEntityCoords(chest.entity) or chest.pos
			local d = #(GetEntityCoords(PlayerPedId()) - ref)
			return d > CHEST_INTERACT_RANGE
		end,
		fail = function()
			opening = false
			activeCancel = nil
			ClearPedTasks(PlayerPedId())
			pickupCooldown = GetGameTimer() + (PICKUP_COOLDOWN_MS / 3)
			Core._setBusy(false)
		end,
	})
end)

Game.session:listen("interact.released", function()
	if not opening then
		return
	end

	pendingRelease = true

	if not activeCancel then
		return
	end

	opening = false
	ClearPedTasks(PlayerPedId())
	Core._setBusy(false)

	local cancel = activeCancel
	activeCancel = nil
	cancel()
end)

RegisterCommand("bugcaixa", function()
	local ped = PlayerPedId()
	local pedPos = GetEntityCoords(ped)
	local camPos = GetFinalRenderedCamCoord()

	local allCount, visCount = 0, 0
	for _ in pairs(allChests) do
		allCount = allCount + 1
	end
	for _ in pairs(visibleChests) do
		visCount = visCount + 1
	end

	print("==================== [bugcaixa] ====================")

	print(
		("[bugcaixa] session.active=%s | phase=%s (esperado=%s)"):format(
			tostring(Game.session:active()),
			tostring(Game.session:currentPhase()),
			tostring(MatchState.STARTED)
		)
	)

	print(
		("[bugcaixa] spawnPoints=%d | allChests=%d | visibleChests=%d"):format(
			spawnPoints and #spawnPoints or -1,
			allCount,
			visCount
		)
	)

	print(
		("[bugcaixa] cfg: CHEST_LOD=%s CHEST_INTERACT_RANGE=%s chestSpawnChance=%s"):format(
			tostring(CHEST_LOD),
			tostring(CHEST_INTERACT_RANGE),
			tostring(Config.BR.loot.chestSpawnChance)
		)
	)

	print(
		("[bugcaixa] flags: opening=%s Core._busy=%s inVehicle=%s isInteractionAllowed=%s"):format(
			tostring(opening),
			tostring(Core._busy and Core._busy() or nil),
			tostring(IsPedInAnyVehicle(ped, false)),
			tostring(isInteractionAllowed())
		)
	)

	local bestIdx, bestChest, bestDist = nil, nil, math.huge
	for idx, chest in pairs(allChests) do
		local d = #(pedPos - chest.pos)
		if d < bestDist then
			bestIdx, bestChest, bestDist = idx, chest, d
		end
	end

	if not bestChest then
		print("[bugcaixa] Nenhum baú em allChests — verifique chest.seed / spawnPoints / safezone.")
		print("====================================================")
		return
	end

	local dCam = #(camPos - bestChest.pos)
	local dx, dy, dz = pedPos.x - bestChest.pos.x, pedPos.y - bestChest.pos.y, pedPos.z - bestChest.pos.z
	local horiz = math.sqrt(dx * dx + dy * dy)

	local entityExists = bestChest.entity and DoesEntityExist(bestChest.entity)
	local entPos = entityExists and GetEntityCoords(bestChest.entity) or nil
	local zDiff = entPos and (entPos.z - bestChest.pos.z) or nil

	local modelHash = CHEST_MODELS[bestChest.chestType]
	local modelLoaded = modelHash and HasModelLoaded(modelHash) or false

	print(
		("[bugcaixa] near chest: idx=%s type=%s pos=%.2f,%.2f,%.2f"):format(
			tostring(bestIdx),
			tostring(bestChest.chestType),
			bestChest.pos.x,
			bestChest.pos.y,
			bestChest.pos.z
		)
	)

	print(
		("[bugcaixa] dist ped->pos: 3D=%.3f horiz=%.3f dz=%.3f | dist cam->pos=%.3f"):format(bestDist, horiz, dz, dCam)
	)

	print(
		("[bugcaixa] visibleChests=%s | ent=%s | model=%s (hash=%s)"):format(
			tostring(visibleChests[bestIdx] ~= nil),
			tostring(entityExists),
			tostring(modelLoaded),
			tostring(modelHash)
		)
	)

	if entPos then
		print(
			("[bugcaixa] ent pos=%.2f,%.2f,%.2f | Z ent - Z chest.pos = %.3f"):format(
				entPos.x,
				entPos.y,
				entPos.z,
				zDiff
			)
		)
	end

	local fcIdx, fcChest = findClosestChest()
	print(("[bugcaixa] findClosestChest: idx=%s = %s"):format(tostring(fcIdx), tostring(fcChest ~= nil)))

	local phaseOk = Game.session:currentPhase() == MatchState.STARTED
	local inRange = bestDist < CHEST_INTERACT_RANGE
	local inVis = visibleChests[bestIdx] ~= nil
	local inLod = dCam <= CHEST_LOD

	local verdict
	if not Game.session:active() then
		verdict = "(matchId nil)"
	elseif not phaseOk then
		verdict = ("604"):format(tostring(Game.session:currentPhase()))
	elseif not inVis then
		if not inLod then
			verdict = ("607"):format(dCam, tostring(CHEST_LOD))
		else
			verdict = "609"
		end
	elseif not inRange then
		if zDiff and math.abs(zDiff) > 1.0 then
			verdict = ("d3d (%.3f > %s):: Z ( Z=%.2f vs pos Z=%.2f) [613]"):format(
				bestDist,
				tostring(CHEST_INTERACT_RANGE),
				entPos and entPos.z or 0.0,
				bestChest.pos.z
			)
		else
			verdict = ("d3d > range (%.3f > %s)"):format(bestDist, tostring(CHEST_INTERACT_RANGE))
		end
	else
		verdict = "certo"
	end

	print(("[bugcaixa] VEREDITO: %s"):format(verdict))
	print("====================================================")
end, false)

RegisterCommand("bugarma", function()
	local ped = PlayerPedId()
	local pedPos = GetEntityCoords(ped)
	local camPos = GetFinalRenderedCamCoord()

	local pickupCount = 0
	for _ in pairs(pickups) do
		pickupCount = pickupCount + 1
	end

	print("==================== [bugarma] ====================")

	print(
		("[bugarma] session.active=%s | phase=%s (esperado=%s)"):format(
			tostring(Game.session:active()),
			tostring(Game.session:currentPhase()),
			tostring(MatchState.STARTED)
		)
	)

	print(
		("[bugarma] pickups=%d | cfg: PICKUP_LOD=%s PICKUP_INTERACT_RANGE=%s PICKUP_COOLDOWN_MS=%s"):format(
			pickupCount,
			tostring(PICKUP_LOD),
			tostring(PICKUP_INTERACT_RANGE),
			tostring(PICKUP_COOLDOWN_MS)
		)
	)

	local cooldownRemaining = math.max(0, pickupCooldown - GetGameTimer())
	print(
		("[bugarma] flags: opening=%s Core._busy=%s inVehicle=%s cooldownRestante=%dms"):format(
			tostring(opening),
			tostring(Core._busy and Core._busy() or nil),
			tostring(IsPedInAnyVehicle(ped, false)),
			cooldownRemaining
		)
	)

	local bestIdx, bestPickup, bestDist = nil, nil, math.huge
	for idx, p in pairs(pickups) do
		local d = #(pedPos - p.pos)
		if d < bestDist then
			bestIdx, bestPickup, bestDist = idx, p, d
		end
	end

	if not bestPickup then
		print("[bugarma] Nenhuma pickup em pickups — verifique pickup.created do server.")
		print("====================================================")
		return
	end

	local itemName = MODEL_TO_ITEM[bestPickup.model]
	local itemDef = itemName and GItems[itemName] or nil
	local freeSpace = itemName and getFreeSpace(itemName) or nil

	local entityExists = bestPickup.entity and DoesEntityExist(bestPickup.entity)
	local entPos = entityExists and GetEntityCoords(bestPickup.entity) or nil
	local zDiff = entPos and (entPos.z - bestPickup.pos.z) or nil
	local dEnt = entPos and #(pedPos - entPos) or nil

	local dCam = #(camPos - bestPickup.pos)
	local dx, dy, dz = pedPos.x - bestPickup.pos.x, pedPos.y - bestPickup.pos.y, pedPos.z - bestPickup.pos.z
	local horiz = math.sqrt(dx * dx + dy * dy)

	print(
		("[bugarma] near pickup: idx=%s model=%s itemName=%s"):format(
			tostring(bestIdx),
			tostring(bestPickup.model),
			tostring(itemName)
		)
	)

	print(
		("[bugarma] pos=%.2f,%.2f,%.2f | dist ped->pos: 3D=%.3f horiz=%.3f dz=%.3f | dist cam->pos=%.3f"):format(
			bestPickup.pos.x,
			bestPickup.pos.y,
			bestPickup.pos.z,
			bestDist,
			horiz,
			dz,
			dCam
		)
	)

	print(
		("[bugarma] entidade=%s | modelLoaded=%s | entPos=%s | Z ent - Z pos = %s | dist ped->ent=%s"):format(
			tostring(entityExists),
			tostring(HasModelLoaded(bestPickup.model)),
			entPos and ("%.2f,%.2f,%.2f"):format(entPos.x, entPos.y, entPos.z) or "nil",
			tostring(zDiff),
			tostring(dEnt and ("%.3f"):format(dEnt) or "nil")
		)
	)

	print(
		("[bugarma] getFreeSpace(%s)=%s | itemDef=%s"):format(
			tostring(itemName),
			tostring(freeSpace),
			tostring(itemDef and itemDef.name or nil)
		)
	)

	local fcIdx, fcPickup = findClosestPickup()
	print(("[bugarma] findClosestPickup: idx=%s = %s"):format(tostring(fcIdx), tostring(fcPickup ~= nil)))

	local phaseOk = Game.session:currentPhase() == MatchState.STARTED
	local inRangePos = bestDist < PICKUP_INTERACT_RANGE
	local inRangeEnt = dEnt and dEnt < PICKUP_INTERACT_RANGE or false
	local cooldownOk = GetGameTimer() >= pickupCooldown

	local verdict
	if not Game.session:active() then
		verdict = "BLOQUEADO: session não ativa (matchId nil)"
	elseif not phaseOk then
		verdict = ("BLOQUEADO: fase != STARTED (atual=%s)"):format(tostring(Game.session:currentPhase()))
	elseif opening then
		verdict = "BLOQUEADO: opening=true (abertura de baú em andamento)"
	elseif not cooldownOk then
		verdict = ("BLOQUEADO: pickupCooldown ativo (%dms restantes)"):format(cooldownRemaining)
	elseif not entityExists then
		verdict = "BLOQUEADO: pickup sem entidade (ainda não spawnou no LOD ou modelo não carregou)"
	elseif not itemName then
		verdict = ("BLOQUEADO: modelo %s não mapeado em MODEL_TO_ITEM"):format(tostring(bestPickup.model))
	elseif not inRangeEnt then
		if zDiff and math.abs(zDiff) > 1.0 then
			verdict = ("BLOQUEADO: dist ped->ent > range (%.3f > %s) por divergência de Z (ent Z=%.2f vs pos Z=%.2f)"):format(
				dEnt,
				tostring(PICKUP_INTERACT_RANGE),
				entPos and entPos.z or 0.0,
				bestPickup.pos.z
			)
		else
			verdict = ("BLOQUEADO: dist ped->ent > range (%.3f > %s)"):format(dEnt, tostring(PICKUP_INTERACT_RANGE))
		end
	elseif freeSpace == nil or freeSpace <= 0 then
		verdict = ("BLOQUEADO: sem espaço no inventário para %s (freeSpace=%s)"):format(
			tostring(itemName),
			tostring(freeSpace)
		)
	else
		verdict = "TUDO OK — prompt loot_pickup deveria aparecer."
	end

	print(("[bugarma] VEREDITO: %s"):format(verdict))
	print("====================================================")
end, false)
