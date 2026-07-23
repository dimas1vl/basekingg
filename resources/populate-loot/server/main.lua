local RESOURCE = GetCurrentResourceName()

local SAVE_FILE = "locates.json"
local SAVE_INTERVAL = 5000
local MIN_DISTANCE = 3.0

---@type table<number, { id: number, x: number, y: number, z: number, heading: number }>
local chests = {}
local nextId = 1
local dirty = false

---@type table<number, boolean>
local editors = {}

-- locates.json: array de arrays [x, y, z, heading], igual ao formato vec4 do gLootCoords
local function loadChests()
	local raw = LoadResourceFile(RESOURCE, SAVE_FILE)
	local data = (raw and json.decode(raw)) or {}

	chests = {}
	nextId = 1

	for i = 1, #data do
		local entry = data[i]
		local id = nextId

		nextId = nextId + 1

		chests[id] = { id = id, x = entry[1], y = entry[2], z = entry[3], heading = entry[4] or 0.0 }
	end

	print(("[populate-loot] %d bau(s) carregado(s) de %s"):format(#data, SAVE_FILE))
end

---@param n number
---@return number
local function round2(n)
	return tonumber(("%.2f"):format(n)) or n
end

---@param list number[][]
---@return string
local function encodeChests(list)
	if #list == 0 then
		return "[]"
	end

	local rows = {}

	for i = 1, #list do
		local c = list[i]
		rows[i] = ("  [%s, %s, %s, %s]"):format(c[1], c[2], c[3], c[4])
	end

	return "[\n" .. table.concat(rows, ",\n") .. "\n]"
end

local function saveChests()
	local list = {}

	for _, chest in pairs(chests) do
		list[#list + 1] = { round2(chest.x), round2(chest.y), round2(chest.z), round2(chest.heading) }
	end

	SaveResourceFile(RESOURCE, SAVE_FILE, encodeChests(list), -1)
	dirty = false

	print(("[populate-loot] %d bau(s) salvo(s) em %s"):format(#list, SAVE_FILE))
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

---@param eventName string
---@param ... any
local function broadcastToEditors(eventName, ...)
	for src in pairs(editors) do
		TriggerClientEvent(eventName, src, ...)
	end
end

loadChests()

CreateThread(function()
	while true do
		Wait(SAVE_INTERVAL)

		if dirty then
			saveChests()
		end
	end
end)

RegisterCommand("populate-loot", function(src)
	if src == 0 then
		return
	end

	if editors[src] then
		editors[src] = nil
		TriggerClientEvent("populate-loot:deactivate", src)
		return
	end

	editors[src] = true

	local list = {}

	for _, chest in pairs(chests) do
		list[#list + 1] = { id = chest.id, x = chest.x, y = chest.y, z = chest.z, heading = chest.heading }
	end

	TriggerClientEvent("populate-loot:activate", src, list)
end)

RegisterNetEvent("populate-loot:create", function(x, y, z, heading)
	local src = source

	if not editors[src] then
		return
	end

	if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
		return
	end

	if not isFarEnough(x, y, z) then
		TriggerClientEvent("populate-loot:createRejected", src)
		return
	end

	local id = nextId
	nextId = nextId + 1

	chests[id] = { id = id, x = x, y = y, z = z, heading = heading or 0.0 }
	dirty = true

	broadcastToEditors("populate-loot:created", id, x, y, z, heading or 0.0)
end)

RegisterNetEvent("populate-loot:delete", function(id)
	local src = source

	if not editors[src] then
		return
	end

	if not chests[id] then
		return
	end

	chests[id] = nil
	dirty = true

	broadcastToEditors("populate-loot:deleted", id)
end)

AddEventHandler("playerDropped", function()
	editors[source] = nil
end)

AddEventHandler("onResourceStop", function(resource)
	if resource ~= RESOURCE then
		return
	end

	if dirty then
		saveChests()
	end
end)
