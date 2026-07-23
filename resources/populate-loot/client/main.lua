local CHEST_MODELS = {
	"kingg_lootbox_red",
	"kingg_lootbox_blue",
	"kingg_lootbox_grenn",
	"kingg_lootbox_yellow",
	"kingg_lootbox_purple",
}
local BLIP_SPRITE = 587

local OBJECT_RADIUS = 75.0
local CACHE150_RADIUS = 150.0
local CACHE500_RADIUS = 500.0
local CACHE150_THRESHOLD = 75.0
local CACHE500_THRESHOLD = 250.0
local MIN_DISTANCE = 4.5
local DELETE_RANGE = 3.0

---@type number[]
local modelHashes = {}

for i = 1, #CHEST_MODELS do
	modelHashes[i] = GetHashKey(CHEST_MODELS[i])
end

local active = false

---@type table<number, { id: number, x: number, y: number, z: number, heading: number }>
local chests = {}

---@type table<number, number>
local blips = {}

---@type table<number, number>
local objects = {}

local cache500 = { center = nil, ids = {} }
local cache150 = { center = nil, ids = {} }

---@param msg string
local function notify(text)
	TriggerEvent("Notify", "", text, 2)
end

local function requestModels()
	for i = 1, #modelHashes do
		if not HasModelLoaded(modelHashes[i]) then
			RequestModel(modelHashes[i])
		end
	end

	local timeout = GetGameTimer() + 5000

	while GetGameTimer() < timeout do
		local allLoaded = true

		for i = 1, #modelHashes do
			if not HasModelLoaded(modelHashes[i]) then
				allLoaded = false
				break
			end
		end

		if allLoaded then
			break
		end

		Wait(50)
	end
end

---@param center vector3
---@param radius number
---@return table<number, boolean>
local function collectWithin(center, radius)
	local ids = {}

	for id, chest in pairs(chests) do
		if #(vector3(chest.x, chest.y, chest.z) - center) <= radius then
			ids[id] = true
		end
	end

	return ids
end

---@param id number
local function removeBlip(id)
	local blip = blips[id]

	if blip and DoesBlipExist(blip) then
		RemoveBlip(blip)
	end

	blips[id] = nil
end

---@param id number
local function removeObject(id)
	local obj = objects[id]

	if obj and DoesEntityExist(obj) then
		DeleteEntity(obj)
	end

	objects[id] = nil
end

---@param id number
---@param chest table
local function ensureBlip(id, chest)
	if blips[id] then
		return
	end

	local blip = AddBlipForCoord(chest.x, chest.y, chest.z)
	SetBlipSprite(blip, BLIP_SPRITE)
	SetBlipScale(blip, 0.5)

	blips[id] = blip
end

---@param id number
---@param chest table
local function ensureObject(id, chest)
	if objects[id] then
		return
	end

	-- seed pelo id do bau para que todo mundo sorteie o mesmo estilo de caixa
	math.randomseed(id)
	local modelHash = modelHashes[math.random(1, #modelHashes)]

	if not HasModelLoaded(modelHash) then
		return
	end

	local obj = CreateObject(modelHash, chest.x, chest.y, chest.z, false, false, false)

	SetEntityHeading(obj, chest.heading or 0.0)
	PlaceObjectOnGroundProperly(obj)
	FreezeEntityPosition(obj, true)
	SetEntityCollision(obj, false, false)

	objects[id] = obj
end

local function clearAll()
	for id in pairs(blips) do
		removeBlip(id)
	end

	for id in pairs(objects) do
		removeObject(id)
	end

	cache500 = { center = nil, ids = {} }
	cache150 = { center = nil, ids = {} }
end

---@param playerCoords vector3
local function refreshVisuals(playerCoords)
	for id in pairs(blips) do
		if not cache500.ids[id] then
			removeBlip(id)
		end
	end

	for id in pairs(cache500.ids) do
		local chest = chests[id]

		if chest then
			ensureBlip(id, chest)
		end
	end

	for id in pairs(objects) do
		local chest = chests[id]
		local inRange = chest
			and cache150.ids[id]
			and #(playerCoords - vector3(chest.x, chest.y, chest.z)) <= OBJECT_RADIUS

		if not inRange then
			removeObject(id)
		end
	end

	for id in pairs(cache150.ids) do
		local chest = chests[id]

		if chest then
			local dist = #(playerCoords - vector3(chest.x, chest.y, chest.z))

			if dist <= OBJECT_RADIUS then
				ensureObject(id, chest)
			end
		end
	end
end

---@param x number
---@param y number
---@param z number
---@return boolean
local function isFarEnough(x, y, z)
	for _, chest in pairs(chests) do
		if #(vector3(chest.x, chest.y, chest.z) - vector3(x, y, z)) < MIN_DISTANCE then
			return false
		end
	end

	return true
end

CreateThread(function()
	while true do
		if active then
			local coords = GetEntityCoords(PlayerPedId())

			if not cache500.center or #(coords - cache500.center) > CACHE500_THRESHOLD then
				cache500 = { center = coords, ids = collectWithin(coords, CACHE500_RADIUS) }
				cache150 = { center = coords, ids = collectWithin(coords, CACHE150_RADIUS) }
			elseif not cache150.center or #(coords - cache150.center) > CACHE150_THRESHOLD then
				cache150 = { center = coords, ids = collectWithin(coords, CACHE150_RADIUS) }
			end

			refreshVisuals(coords)

			Wait(500)
		else
			Wait(1000)
		end
	end
end)

RegisterNetEvent("populate-loot:activate", function(list)
	chests = {}

	for i = 1, #list do
		local c = list[i]
		chests[c.id] = { id = c.id, x = c.x, y = c.y, z = c.z, heading = c.heading or 0.0 }
	end

	requestModels()

	active = true

	notify(("Populate Loot ativado — %d bau(s) carregado(s)"):format(#list))
end)

RegisterNetEvent("populate-loot:deactivate", function()
	active = false
	clearAll()
	chests = {}

	for i = 1, #modelHashes do
		SetModelAsNoLongerNeeded(modelHashes[i])
	end

	notify("Populate Loot desativado")
end)

RegisterNetEvent("populate-loot:created", function(id, x, y, z, heading)
	chests[id] = { id = id, x = x, y = y, z = z, heading = heading or 0.0 }

	if cache500.center and #(vector3(x, y, z) - cache500.center) <= CACHE500_RADIUS then
		cache500.ids[id] = true
	end

	if cache150.center and #(vector3(x, y, z) - cache150.center) <= CACHE150_RADIUS then
		cache150.ids[id] = true
	end
end)

RegisterNetEvent("populate-loot:deleted", function(id)
	chests[id] = nil
	cache500.ids[id] = nil
	cache150.ids[id] = nil
	removeBlip(id)
	removeObject(id)
end)

RegisterNetEvent("populate-loot:createRejected", function()
	notify("Muito perto de outro bau (minimo 3m)")
end)

RegisterCommand("+populateloot_place", function()
	if not active then
		return
	end

	local ped = PlayerPedId()
	local coords = GetEntityCoords(ped)
	local ok, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
	local z = ok and groundZ or coords.z
	local heading = GetEntityHeading(ped)

	if not isFarEnough(coords.x, coords.y, z) then
		notify("Muito perto de outro bau (minimo 3m)")
		return
	end

	TriggerServerEvent("populate-loot:create", coords.x, coords.y, z, heading)
end)

RegisterCommand("+populateloot_delete", function()
	if not active then
		return
	end

	local coords = GetEntityCoords(PlayerPedId())
	local closestId, closestDist = nil, DELETE_RANGE

	for id, chest in pairs(chests) do
		local dist = #(coords - vector3(chest.x, chest.y, chest.z))

		if dist < closestDist then
			closestId, closestDist = id, dist
		end
	end

	if closestId then
		TriggerServerEvent("populate-loot:delete", closestId)
	else
		notify("Nenhum bau por perto")
	end
end)

RegisterKeyMapping("+populateloot_place", "Colocar bau (Populate Loot)", "keyboard", "E")
RegisterKeyMapping("+populateloot_delete", "Remover bau (Populate Loot)", "keyboard", "DELETE")

AddEventHandler("onResourceStop", function(resource)
	if resource ~= GetCurrentResourceName() then
		return
	end

	clearAll()
end)
