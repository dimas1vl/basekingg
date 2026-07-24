local TEXTURE_DICT = "safezone"
local TEXTURE_NAME = "kingg_safezone"
local MARKER_HEIGHT = 9000.0
local WALL_ALPHA = 128 -- 0-255
local MARKER_COLOR = { 46, 125, 50, WALL_ALPHA }
local MARKER_SCALE = 1.98412

local WALL_MIN_HEIGHT = 1000.0
local WALL_MAX_HEIGHT = 15000.0
local WALL_MIN_TILE = 50.0
local WALL_MAX_TILE = 2500.0
local WALL_SEGMENTS_FAR = 32
local WALL_SEGMENTS_NEAR = 64
local WALL_TILE_WIDTH_SCALE = 2
local WALL_EDGE_CHECK_INTERVAL = 100

---@param a number
---@param b number
---@param t number
---@return number
local function lerp(a, b, t)
	return (1 - t) * a + t * b
end

---@param value number
---@param min number
---@param max number
---@return number
local function clamp(value, min, max)
	return math.min(math.max(value, min), max)
end

---@class SafeZoneHandlers
---@field onOut fun(damage: number) | nil
---@field onIn fun() | nil
---@field onPhaseChange fun(phase: number, damage: number) | nil

---@class SafeZoneGas
---@field x number
---@field y number
---@field radius number

---@class SafeZoneSafe
---@field x number
---@field y number
---@field radius number

---@class SafeZone
---@field active boolean
---@field gas SafeZoneGas | nil
---@field safe SafeZoneSafe | nil
---@field shrinking boolean
---@field shrinkStartAt number
---@field shrinkDuration number
---@field shrinkFromX number
---@field shrinkFromY number
---@field shrinkFromRadius number
---@field blip number | nil
---@field safeBlip number | nil
---@field blipsRevealed boolean
---@field textureLoaded boolean
---@field damage number
---@field phase number
---@field inGas boolean
---@field handlers SafeZoneHandlers
local SafeZone = {
	active = false,
	gas = nil,
	safe = nil,
	shrinking = false,
	shrinkStartAt = 0,
	shrinkDuration = 0,
	shrinkFromX = 0,
	shrinkFromY = 0,
	shrinkFromRadius = 0,
	blip = nil,
	safeBlip = nil,
	blipsRevealed = false,
	textureLoaded = false,
	damage = 0,
	phase = 0,
	inGas = false,
	handlers = {},
}

local wallMaxRadiusSeen = 0
local wallSegments = WALL_SEGMENTS_FAR
local wallIsOutside = false
local wallIsNearEdge = false
local wallLastCheckAt = 0

-- 2.3 addon blip multiplier

local function loadTexture()
	if SafeZone.textureLoaded then
		return
	end

	RequestStreamedTextureDict(TEXTURE_DICT, true)

	local timeout = GetGameTimer() + 5000

	while not HasStreamedTextureDictLoaded(TEXTURE_DICT) and GetGameTimer() < timeout do
		Wait(50)
	end

	SafeZone.textureLoaded = HasStreamedTextureDictLoaded(TEXTURE_DICT)
end

local function removeBlips()
	if SafeZone.blip then
		RemoveBlip(SafeZone.blip)
		SafeZone.blip = nil
	end

	if SafeZone.safeBlip then
		RemoveBlip(SafeZone.safeBlip)
		SafeZone.safeBlip = nil
	end
end
---@param x number
---@param y number
---@param radius number
local function createGasBlip(x, y, radius)
	if not SafeZone.blipsRevealed then
		return
	end

	if SafeZone.blip then
		RemoveBlip(SafeZone.blip)
	end

	local radiusBlip = AddBlipForRadius(x, y, 0.0, radius)
	SetBlipSprite(radiusBlip, 10)
	SetBlipColour(radiusBlip, 2)
	SetBlipAlpha(radiusBlip, 255)
	SetBlipAsShortRange(radiusBlip, true)
	SetBlipHiddenOnLegend(radiusBlip, true)
	SetBlipHighDetail(radiusBlip, true)
	SafeZone.blip = radiusBlip
end

-- CreateThread(function()
--     NetworkResurrectLocalPlayer(0, 0, 0, 0, 0, false)
--     SetEntityHealth(PlayerPedId(), 200)
-- end)

---@param x number
---@param y number
---@param radius number
local function createSafeBlip(x, y, radius)
	if not SafeZone.blipsRevealed then
		return
	end

	if SafeZone.safeBlip then
		RemoveBlip(SafeZone.safeBlip)
	end

	SafeZone.safeBlip = AddBlipForRadius(x, y, 0.0, radius)
	SetBlipSprite(SafeZone.safeBlip, 10)
	SetBlipColour(SafeZone.safeBlip, 0)
	SetBlipAlpha(SafeZone.safeBlip, 255)
	SetBlipScale(SafeZone.safeBlip, radius)
end

local function updateShrink()
	if not SafeZone.shrinking or not SafeZone.gas or not SafeZone.safe then
		return
	end

	local now = GetNetworkTimeAccurate()
	local elapsed = now - SafeZone.shrinkStartAt

	if elapsed >= SafeZone.shrinkDuration then
		SafeZone.gas.x = SafeZone.safe.x
		SafeZone.gas.y = SafeZone.safe.y
		SafeZone.gas.radius = SafeZone.safe.radius
		SafeZone.shrinking = false
		return
	end

	local t = clamp(elapsed / SafeZone.shrinkDuration, 0.0, 1.0)

	SafeZone.gas.x = lerp(SafeZone.shrinkFromX, SafeZone.safe.x, t)
	SafeZone.gas.y = lerp(SafeZone.shrinkFromY, SafeZone.safe.y, t)
	SafeZone.gas.radius = lerp(SafeZone.shrinkFromRadius, SafeZone.safe.radius, t)

	if SafeZone.blip then
		SetBlipCoords(SafeZone.blip, SafeZone.gas.x, SafeZone.gas.y, 0.0)
		SetBlipScale(SafeZone.blip, SafeZone.gas.radius)
	end
end

local function checkPlayerPosition()
	if not SafeZone.gas then
		return
	end
	if SafeZone.damage <= 0 then
		return
	end

	local ped = PlayerPedId()
	local coords = GetEntityCoords(ped)
	local dist = #(vector2(coords.x, coords.y) - vector2(SafeZone.gas.x, SafeZone.gas.y))
	local inGas = dist > SafeZone.gas.radius

	if inGas ~= SafeZone.inGas then
		SafeZone.inGas = inGas
		LocalPlayer.state:set("inSafeZone", not inGas, false)

		if inGas then
			if SafeZone.handlers.onOut then
				SafeZone.handlers.onOut(SafeZone.damage)
			end
		else
			if SafeZone.handlers.onIn then
				SafeZone.handlers.onIn()
			end
		end
	end

	if inGas then
		if SafeZone.handlers.onDamageTick then
			SafeZone.handlers.onDamageTick(SafeZone.damage)
		else
			ApplyDamageToPed(ped, SafeZone.damage, false)
		end
	end
end

---@param cz number
---@param topZ number
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param u1 number
---@param u2 number
---@param uvVertical number
---@param color number[]
local function drawWallFaces(cz, topZ, x1, y1, x2, y2, u1, u2, uvVertical, color)
	if wallIsNearEdge or wallIsOutside then
		DrawTexturedPoly(
			x2,
			y2,
			topZ,
			x1,
			y1,
			topZ,
			x1,
			y1,
			cz,
			color[1],
			color[2],
			color[3],
			color[4],
			TEXTURE_DICT,
			TEXTURE_NAME,
			u2,
			uvVertical,
			0.0,
			u1,
			uvVertical,
			0.0,
			u1,
			0.0,
			0.0
		)
		DrawTexturedPoly(
			x2,
			y2,
			cz,
			x2,
			y2,
			topZ,
			x1,
			y1,
			cz,
			color[1],
			color[2],
			color[3],
			color[4],
			TEXTURE_DICT,
			TEXTURE_NAME,
			u2,
			0.0,
			0.0,
			u2,
			uvVertical,
			0.0,
			u1,
			0.0,
			0.0
		)
	end

	if wallIsNearEdge or not wallIsOutside then
		DrawTexturedPoly(
			x1,
			y1,
			cz,
			x1,
			y1,
			topZ,
			x2,
			y2,
			topZ,
			color[1],
			color[2],
			color[3],
			color[4],
			TEXTURE_DICT,
			TEXTURE_NAME,
			u1,
			0.0,
			0.0,
			u1,
			uvVertical,
			0.0,
			u2,
			uvVertical,
			0.0
		)
		DrawTexturedPoly(
			x1,
			y1,
			cz,
			x2,
			y2,
			topZ,
			x2,
			y2,
			cz,
			color[1],
			color[2],
			color[3],
			color[4],
			TEXTURE_DICT,
			TEXTURE_NAME,
			u1,
			0.0,
			0.0,
			u2,
			uvVertical,
			0.0,
			u2,
			0.0,
			0.0
		)
	end
end

---@param radius number
local function updateWallEdgeState(cx, cy, radius)
	if GetGameTimer() - wallLastCheckAt < WALL_EDGE_CHECK_INTERVAL then
		return
	end

	wallLastCheckAt = GetGameTimer()

	local coords = GetEntityCoords(PlayerPedId())
	local dist = #(vector2(coords.x, coords.y) - vector2(cx, cy))

	wallIsOutside = dist > radius
	wallIsNearEdge = radius <= 100 or (dist > radius - math.min(radius * 0.01, 20) and dist < radius + 10)

	if
		radius <= 800 or (dist > radius - math.max(radius * 0.2, 200) and dist < radius + math.max(radius * 0.2, 200))
	then
		wallSegments = WALL_SEGMENTS_NEAR
	else
		wallSegments = WALL_SEGMENTS_FAR
	end
end

local function drawMarker()
	if not SafeZone.gas then
		return
	end

	local gasX = SafeZone.gas.x
	local gasY = SafeZone.gas.y
	local gasRadius = SafeZone.gas.radius
	local color = MARKER_COLOR

	if gasRadius > wallMaxRadiusSeen then
		wallMaxRadiusSeen = gasRadius
	end

	if not SafeZone.textureLoaded then
		local size = gasRadius * MARKER_SCALE

		DrawMarker(
			1,
			gasX,
			gasY,
			-200.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			size,
			size,
			MARKER_HEIGHT,
			color[1],
			color[2],
			color[3],
			color[4],
			false,
			false,
			2,
			false,
			nil,
			nil,
			false
		)

		return
	end

	updateWallEdgeState(gasX, gasY, gasRadius)

	local t = wallMaxRadiusSeen > 0 and math.min(gasRadius / wallMaxRadiusSeen, 1.0) or 1.0
	local height = WALL_MIN_HEIGHT + (WALL_MAX_HEIGHT - WALL_MIN_HEIGHT) * t
	local tile = WALL_MIN_TILE + (WALL_MAX_TILE - WALL_MIN_TILE) * t
	local tileWidth = tile * WALL_TILE_WIDTH_SCALE

	local circumference = 2.0 * math.pi * gasRadius
	local uvHorizontal = circumference / tileWidth
	local uvVertical = height / tile

	local cz = -200.0
	local topZ = cz + height

	local step = (2.0 * math.pi) / wallSegments
	local cosStep = math.cos(step)
	local sinStep = math.sin(step)

	local dx, dy = gasRadius, 0.0

	for i = 0, wallSegments - 1 do
		local x1, y1 = gasX + dx, gasY + dy

		local ndx = dx * cosStep - dy * sinStep
		local ndy = dx * sinStep + dy * cosStep
		dx, dy = ndx, ndy

		local x2, y2 = gasX + dx, gasY + dy

		local u1 = (i / wallSegments) * uvHorizontal
		local u2 = ((i + 1) / wallSegments) * uvHorizontal

		drawWallFaces(cz, topZ, x1, y1, x2, y2, u1, u2, uvVertical, color)
	end
end

local function safeZoneTick()
	loadTexture()

	local lastDamageCheck = 0

	while SafeZone.active do
		updateShrink()
		drawMarker()

		local now = GetGameTimer()

		if now - lastDamageCheck >= 1000 then
			lastDamageCheck = now
			checkPlayerPosition()
		end

		Wait(0)
	end

	removeBlips()

	if SafeZone.textureLoaded then
		SetStreamedTextureDictAsNoLongerNeeded(TEXTURE_DICT)
		SafeZone.textureLoaded = false
	end

	SafeZone.inGas = false
	LocalPlayer.state:set("inSafeZone", nil, false)
end

-- kingg:safezone:start { gas = {x,y,radius}, safe = {x,y,radius} | nil, damage, phase }
RegisterNetEvent("kingg:safezone:start", function(data)
	print("safezone:start", json.encode(data, { indent = true }))
	if SafeZone.active then
		return
	end

	SafeZone.active = true
	SafeZone.damage = data.damage or 0
	SafeZone.phase = data.phase or 1
	SafeZone.inGas = false
	SafeZone.shrinking = false
	SafeZone.blipsRevealed = false

	wallMaxRadiusSeen = 0
	wallSegments = WALL_SEGMENTS_FAR
	wallIsOutside = false
	wallIsNearEdge = false
	wallLastCheckAt = 0

	SafeZone.gas = {
		x = data.gas.x,
		y = data.gas.y,
		radius = data.gas.radius,
	}

	if data.safe then
		print("safe blip created")
		SafeZone.safe = {
			x = data.safe.x,
			y = data.safe.y,
			radius = data.safe.radius,
		}

		createSafeBlip(SafeZone.safe.x, SafeZone.safe.y, SafeZone.safe.radius)
	end

	createGasBlip(SafeZone.gas.x, SafeZone.gas.y, SafeZone.gas.radius)
	print("gas blip created")

	CreateThread(safeZoneTick)
end)

-- kingg:safezone:phase { phase, damage, target = {x,y,radius}, nextSafe = {x,y,radius} | nil }
RegisterNetEvent("kingg:safezone:phase", function(phase, damage, target, nextSafe)
	print("safezone:phase", json.encode({ phase, damage, target, nextSafe }, { indent = true }))
	if not SafeZone.active then
		return
	end

	SafeZone.phase = phase
	SafeZone.damage = damage

	if target then
		SafeZone.safe = {
			x = target.x,
			y = target.y,
			radius = target.radius,
		}
	end

	local preview = nextSafe or target

	if preview then
		createSafeBlip(preview.x, preview.y, preview.radius)
	end

	if SafeZone.handlers.onPhaseChange then
		SafeZone.handlers.onPhaseChange(phase, damage)
	end
end)

-- kingg:safezone:reveal { x, y, radius }
RegisterNetEvent("kingg:safezone:reveal", function(safe)
	if not SafeZone.active or not safe then
		return
	end

	SafeZone.safe = {
		x = safe.x,
		y = safe.y,
		radius = safe.radius,
	}

	createSafeBlip(safe.x, safe.y, safe.radius)
end)

-- kingg:safezone:showBlips {} — libera os blips de gas/safe no mapa (a borda em si ja e visivel antes disso)
RegisterNetEvent("kingg:safezone:showBlips", function()
	if not SafeZone.active or SafeZone.blipsRevealed then
		return
	end

	SafeZone.blipsRevealed = true

	if SafeZone.gas then
		createGasBlip(SafeZone.gas.x, SafeZone.gas.y, SafeZone.gas.radius)
	end

	if SafeZone.safe then
		createSafeBlip(SafeZone.safe.x, SafeZone.safe.y, SafeZone.safe.radius)
	end
end)

-- kingg:safezone:shrink { startAt (networkTime), duration (ms) }
RegisterNetEvent("kingg:safezone:shrink", function(_, duration)
	if not SafeZone.active or not SafeZone.gas or not SafeZone.safe then
		return
	end

	SafeZone.shrinkFromX = SafeZone.gas.x
	SafeZone.shrinkFromY = SafeZone.gas.y
	SafeZone.shrinkFromRadius = SafeZone.gas.radius
	SafeZone.shrinkStartAt = GetNetworkTimeAccurate()
	SafeZone.shrinkDuration = duration
	SafeZone.shrinking = true
end)

RegisterNetEvent("kingg:safezone:stop", function()
	SafeZone.active = false
	SafeZone.gas = nil
	SafeZone.safe = nil
	SafeZone.shrinking = false
	SafeZone.damage = 0
	SafeZone.phase = 0
	SafeZone.inGas = false
	SafeZone.blipsRevealed = false
	SafeZone.handlers = {}

	wallMaxRadiusSeen = 0
	wallSegments = WALL_SEGMENTS_FAR
	wallIsOutside = false
	wallIsNearEdge = false
	wallLastCheckAt = 0

	LocalPlayer.state:set("inSafeZone", nil, false)
end)

exports("setSafezoneHandlers", function(handlers)
	assert(type(handlers) == "table", "handlers must be a table")

	SafeZone.handlers = handlers
end)

exports("getSafezoneState", function()
	local gas = nil

	if SafeZone.gas then
		gas = {
			x = SafeZone.gas.x,
			y = SafeZone.gas.y,
			radius = SafeZone.gas.radius * MARKER_SCALE,
		}
	end

	return {
		active = SafeZone.active,
		gas = gas,
		safe = SafeZone.safe,
		damage = SafeZone.damage,
		phase = SafeZone.phase,
		inGas = SafeZone.inGas,
		shrinking = SafeZone.shrinking,
	}
end)

CreateThread(function()
	SetBlipAlpha(GetNorthRadarBlip(), 0)
end)
