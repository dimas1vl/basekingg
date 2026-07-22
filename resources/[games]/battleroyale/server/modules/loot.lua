while not GM do
	Wait(0)
end

local RESOURCE = GetCurrentResourceName()

local CHEST_TYPES = { "RIFLE", "SUB", "HEALTH", "AMMO", "GRENADES" }

-- Cada categoria e uma lista de "outcomes"; cada outcome e uma lista de { itemName, amount }
-- que sao dropados juntos quando esse outcome e sorteado.
local CHEST_LOOT = {
	RIFLE = {
		{ { "WEAPON_ASSAULTRIFLE", 1 } },
		{ { "WEAPON_CARBINERIFLE", 1 } },
		{ { "WEAPON_SPECIALCARBINE", 1 } },
	},

	SUB = {
		{ { "WEAPON_PISTOL_MK2", 1 } },
		{ { "WEAPON_MICROSMG", 1 } },
		{ { "WEAPON_MACHINEPISTOL", 1 } },
		{ { "WEAPON_APPISTOL", 1 } },
		{ { "WEAPON_ASSAULTSMG", 1 } },
	},

	HEALTH = {
		{ { "HEALTH_STANDARD", 1 }, { "ARMOUR_STANDARD", 1 } },
		{ { "HEALTH_STANDARD", 2 } },
		{ { "ARMOUR_STANDARD", 2 } },
	},

	AMMO = {
		{ { "WEAPON_AMMO", 90 } },
	},

	GRENADES = {
		{ { "WEAPON_SMOKEGRENADE", 1 } },
	},
}

local SPAWN_DATA = gLootCoords

local HASH_TO_ITEM = {}

for itemName, def in pairs(GItems) do
	if def.model then
		HASH_TO_ITEM[GetHashKey(def.model)] = itemName
	end
end

---@param lootPool table[] lista de outcomes; cada outcome e uma lista de { itemName, amount }
---@param seed number
---@param chestIndex number
---@param ownedWeapons table<string, boolean> | nil
---@return table[] outcome
local function pickLootEntry(lootPool, seed, chestIndex, ownedWeapons)
	if not ownedWeapons then
		return lootPool[LootRng.lootIndex(seed, chestIndex, #lootPool)]
	end

	local candidates, candidateCount = {}, 0

	for i = 1, #lootPool do
		local outcome = lootPool[i]
		local owned = false

		for j = 1, #outcome do
			local itemDef = GItems[outcome[j][1]]

			if itemDef and itemDef.ammo and ownedWeapons[outcome[j][1]] then
				owned = true
				break
			end
		end

		if not owned then
			candidateCount = candidateCount + 1
			candidates[candidateCount] = outcome
		end
	end

	if candidateCount == 0 then
		return lootPool[LootRng.lootIndex(seed, chestIndex, #lootPool)]
	end

	return candidates[LootRng.lootIndex(seed, chestIndex, candidateCount)]
end

---@param match Match
---@param pickups table
---@param nextId number
---@param itemName string
---@param amount number
---@param coords number[]
---@return number nextId
local function dropItemPickup(match, pickups, nextId, itemName, amount, coords)
	local itemDef = GItems[itemName]

	if not itemDef or not itemDef.model then
		print(("[loot] chest.open: no model for item %s"):format(itemName))
		return nextId
	end

	local modelHash = GetHashKey(itemDef.model)

	pickups[nextId] = { hash = modelHash, amount = amount, coords = coords, fromChest = true }
	match:emitClients("pickup.created", nextId, modelHash, coords)

	print(
		("[loot] chest.open: dropped %s x%d as pickup #%d (model=%s coords=%.1f,%.1f,%.1f)"):format(
			itemName,
			amount,
			nextId,
			itemDef.model,
			coords[1],
			coords[2],
			coords[3]
		)
	)

	nextId = nextId + 1

	local ammoName = GetWeaponAmmo(itemName)

	if ammoName then
		local ammoDef = GItems[ammoName]
		local ammoHash = GetHashKey(ammoDef.model)
		local ammoCoords = { coords[1] + 0.4, coords[2], coords[3] }

		pickups[nextId] = { hash = ammoHash, amount = 30, coords = ammoCoords }
		match:emitClients("pickup.created", nextId, ammoHash, ammoCoords)

		nextId = nextId + 1
	end

	return nextId
end

---@class ChestEntry
---@field type string
---@field coords number[]

---Resolve um único baú on-demand a partir de (seed, idx). Sem estado global, sem iterar todos os pontos.
---@param match Match
---@param seed number
---@param idx number
---@return ChestEntry | nil
local function getChest(match, seed, idx)
	local entry = SPAWN_DATA[idx]

	if not entry then
		return nil
	end

	if LootRng.spawnRoll(seed, idx) >= Config.BR.loot.chestSpawnChance then
		return nil
	end

	local x, y, z = entry[1], entry[2], entry[3]

	local center = match:getData("safezone").zones[1].center
	local dx, dy = x - center.x, y - center.y
	local r2 = Config.BR.safezone.initialRadius * Config.BR.safezone.initialRadius

	if (dx * dx + dy * dy) >= r2 then
		return nil
	end

	local chestType = CHEST_TYPES[LootRng.typeIndex(seed, idx, #CHEST_TYPES)]

	return { type = chestType, coords = { x, y, z } }
end

GM:on("matchStarted", function(match)
	match:setData("openedChests", {})
	match:setData("pickups", {})
	match:setData("nextPickupId", 1)
end)

GM:registerNetEvent("chest.open", function(match, src, chestIndex, ownedWeapons)
	print(("[loot] chest.open: src=%d chestIndex=%s"):format(src, tostring(chestIndex)))

	local openedChests = match:getData("openedChests") or {}

	if openedChests[chestIndex] then
		print(("[loot] chest.open: chest %s already opened"):format(tostring(chestIndex)))
		return
	end

	openedChests[chestIndex] = true
	match:setData("openedChests", openedChests)

	match:emitClients("chest.opened", chestIndex)

	local seed = match:getData("seed")

	if not seed then
		print(("[loot] chest.open: seed is nil for match %d"):format(match.id))
		return
	end

	local chestEntry = getChest(match, seed, chestIndex)

	if not chestEntry then
		print(("[loot] chest.open: chestIndex %s NOT FOUND (no spawn or out of safezone)"):format(tostring(chestIndex)))
		return
	end

	local chestType = chestEntry.type
	local chestCoords = chestEntry.coords

	if not CHEST_LOOT[chestType] then
		print(("[loot] chest.open: no loot table for type %s"):format(chestType))
		return
	end

	local lootPool = CHEST_LOOT[chestType]
	local outcome = pickLootEntry(lootPool, seed, chestIndex, ownedWeapons)

	local pickups = match:getData("pickups") or {}
	local nextId = match:getData("nextPickupId") or 1

	for i = 1, #outcome do
		local item = outcome[i]
		local dropCoords = { chestCoords[1] + (i - 1) * 0.5, chestCoords[2], chestCoords[3] + 1.0 }

		nextId = dropItemPickup(match, pickups, nextId, item[1], item[2], dropCoords)
	end

	match:setData("pickups", pickups)
	match:setData("nextPickupId", nextId)

	log("info", ("match %d: chest %d (%s) opened by src=%d"):format(match.id, chestIndex, chestType, src))
end)

GM:registerNetEvent("pickup.add", function(match, src, pickupHash, amount, coords)
	local pickups = match:getData("pickups") or {}
	local nextId = match:getData("nextPickupId") or 1

	pickups[nextId] = { hash = pickupHash, amount = amount, coords = coords }

	match:setData("pickups", pickups)
	match:setData("nextPickupId", nextId + 1)

	match:emitClients("pickup.created", nextId, pickupHash, coords)
end)

GM:registerNetEvent("pickup.take", function(match, src, pickupId)
	local pickups = match:getData("pickups") or {}

	if not pickups[pickupId] then
		return
	end

	local pickup = pickups[pickupId]
	local fromChest = pickup.fromChest == true

	pickups[pickupId] = nil
	match:setData("pickups", pickups)

	match:emitClients("pickup.taken", pickupId)

	local itemName = HASH_TO_ITEM[pickup.hash]

	if not itemName then
		return
	end

	local giveAmount = math.min(pickup.amount, GetItemMax(itemName))

	TriggerClientEvent(("net.%s:pickup.loot"):format(RESOURCE), src, itemName, giveAmount, fromChest)
end)

GM:registerNetEvent("inventory.update", function(match, src) end)
