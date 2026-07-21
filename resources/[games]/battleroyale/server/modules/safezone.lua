while not GM do
	Wait(0)
end

local cfgZone = Config.BR.safezone
local dynCfg = cfgZone.dynamic

---@param match Match
---@param eventName string
---@param ... any
local function emitSafezoneEvent(match, eventName, ...)
	for i = 1, #match.playerList do
		TriggerClientEvent(eventName, match.playerList[i], ...)
	end

	local globalId = match:getData("globalId")

	if globalId and Core.matches then
		local entry = Core.matches:getMatch(globalId)

		if entry then
			for src in pairs(entry.spectators) do
				TriggerClientEvent(eventName, src, ...)
			end
		end
	end
end

--- @param preset table
--- @return table
local function zoneMetaFromPreset(preset)
	return {
		damage = preset.damage,
		displayTime = preset.displayTime,
		shrinkTime = preset.shrinkTime,
	}
end

--- @param phase number
--- @return boolean
local function isFinalPhase(phase)
	local presets = cfgZone.presets
	local finalPhases = math.max(0, math.floor(dynCfg.finalPhases or 0))

	return phase > (#presets - finalPhases)
end

--- @param match Match
--- @param phase number
--- @return table zone
local function computeIncrementalZone(match, phase)
	local szData = match:getData("safezone")
	local zones = szData.zones
	local presets = cfgZone.presets
	local prevZone = zones[phase - 1]
	local preset = presets[phase]

	assert(prevZone and prevZone.center and prevZone.radius, ("prevZone for phase %d invalid"):format(phase))

	local opts = {
		candidates = dynCfg.candidates,
		areaRadius = dynCfg.areaRadius,
		minImprovement = dynCfg.minImprovement,
		gasOverlap = dynCfg.gasOverlap,
		radiusJitter = isFinalPhase(phase) and (dynCfg.finalRadiusJitter or dynCfg.radiusJitter) or dynCfg.radiusJitter,
	}

	local zone

	if isFinalPhase(phase) then
		zone = Core.getNextFinalSafeZone(prevZone, preset.radius, match.bucket, opts)
		log(
			"info",
			("match %d: safezone phase %d (final/gas) center=%.0f,%.0f r=%.0f"):format(
				match.id,
				phase,
				zone.center.x,
				zone.center.y,
				zone.radius
			)
		)
	else
		zone = Core.getNextSafeZone(prevZone, preset.radius, match.bucket, opts)
		log(
			"info",
			("match %d: safezone phase %d (dynamic) center=%.0f,%.0f r=%.0f"):format(
				match.id,
				phase,
				zone.center.x,
				zone.center.y,
				zone.radius
			)
		)
	end

	zones[phase] = {
		center = zone.center,
		radius = zone.radius,
		damage = preset.damage,
		displayTime = preset.displayTime,
		shrinkTime = preset.shrinkTime,
	}

	return zones[phase]
end

---@param match Match
local function calculateZones(match)
	local zones = {}
	local presets = cfgZone.presets

	local jitter = dynCfg.radiusJitter or 0
	local initialR = cfgZone.initialRadius
	local jitteredInitialR = initialR * (1 - jitter + math.random() * 2 * jitter)

	zones[1] = {
		center = cfgZone.initialCenter,
		radius = jitteredInitialR,
		damage = presets[1].damage,
		displayTime = presets[1].displayTime,
		shrinkTime = presets[1].shrinkTime,
	}

	local zoneOpts = {
		radiusJitter = jitter,
	}

	local next = Core.getNextSafeZone(zones[1], presets[2].radius, nil, zoneOpts)

	zones[2] = {
		center = next.center,
		radius = next.radius,
		damage = presets[2].damage,
		displayTime = presets[2].displayTime,
		shrinkTime = presets[2].shrinkTime,
	}

	for i = 3, #presets do
		zones[i] = zoneMetaFromPreset(presets[i])
	end

	match:setData("safezone", {
		zones = zones,
		currentPhase = 1,
		currentDamage = presets[1].damage,
	})

	return zones
end

---@param match Match
local function showInitialZone(match)
	local szData = match:getData("safezone")

	if not szData then
		return
	end

	local zones = szData.zones
	local first = zones[1]
	local second = zones[2]

	print(
		("[safezone] showInitialZone: match %d — gas(%.0f,%.0f r=%.0f) safe=%s playerCount=%d"):format(
			match.id,
			first.center.x,
			first.center.y,
			first.radius,
			second and ("%.0f,%.0f r=%.0f"):format(second.center.x, second.center.y, second.radius) or "nil",
			#match.playerList
		)
	)

	emitSafezoneEvent(match, "kingg:safezone:start", {
		gas = { x = first.center.x, y = first.center.y, radius = first.radius },
		safe = { x = first.center.x, y = first.center.y, radius = first.radius },
		damage = 0,
		phase = 1,
	})

	log("info", ("match %d: safezone visible (phase 1, no damage)"):format(match.id))
end

---@param szData table
---@param ms number
---@return boolean skipped
local function skippableWait(szData, ms)
	local elapsed = 0

	while elapsed < ms do
		if szData.skipPhase then
			szData.skipPhase = false
			return true
		end

		Wait(200)
		elapsed = elapsed + 200
	end

	return false
end

---@param match Match
local function revealNextZone(match)
	local szData = match:getData("safezone")

	if not szData then
		return
	end

	local next = szData.zones[2]

	if not next then
		return
	end

	CreateThread(function()
		local revealTime = cfgZone.initialReveal or 0

		if revealTime > 0 then
			skippableWait(szData, revealTime * 1000)
		end

		if match.state == MatchState.ENDING or match.state == MatchState.FINISHED then
			return
		end

		emitSafezoneEvent(match, "kingg:safezone:reveal", {
			x = next.center.x,
			y = next.center.y,
			radius = next.radius,
		})

		log("info", ("match %d: safezone next zone revealed (r=%.0f)"):format(match.id, next.radius))
	end)
end

---@param match Match
local function startPhaseProgression(match)
	local szData = match:getData("safezone")

	if not szData then
		return
	end

	local zones = szData.zones

	print(("[safezone] startPhaseProgression: match %d — %d phases total"):format(match.id, #zones))

	log("info", ("match %d: safezone phase progression started with %d phases"):format(match.id, #zones))

	CreateThread(function()
		for phase = 2, #zones do
			local prevZone = zones[phase - 1]

			if match.state ~= MatchState.STARTED then
				return
			end

			if not zones[phase].center then
				computeIncrementalZone(match, phase)
			end

			local currentZone = zones[phase]
			local nextZone = zones[phase + 1]
			local shrinkMs = currentZone.shrinkTime * 1000

			szData.currentPhase = phase
			szData.currentDamage = currentZone.damage

			GM:emit("phaseChanged", match, phase)

			emitSafezoneEvent(
				match,
				"kingg:safezone:phase",
				phase,
				currentZone.damage,
				{ x = currentZone.center.x, y = currentZone.center.y, radius = currentZone.radius },
				nextZone
						and nextZone.center
						and { x = nextZone.center.x, y = nextZone.center.y, radius = nextZone.radius }
					or nil
			)

			if prevZone.displayTime > 0 then
				match:emitClients("safezone.countdown", phase, prevZone.displayTime, #zones)

				skippableWait(szData, prevZone.displayTime * 1000)
			end

			local startAt = GetGameTimer()

			emitSafezoneEvent(match, "kingg:safezone:shrink", startAt, shrinkMs)

			log(
				"info",
				("match %d: safezone phase %d (radius=%.0f, damage=%d, shrink=%ds)"):format(
					match.id,
					phase,
					currentZone.radius,
					currentZone.damage,
					currentZone.shrinkTime
				)
			)

			if shrinkMs > 0 then
				skippableWait(szData, shrinkMs)
			end

			if match.state ~= MatchState.STARTED then
				return
			end
		end

		log("info", ("match %d: all safezone phases completed"):format(match.id))
	end)
end

GM:on("matchCreated", function(match)
	calculateZones(match)
end)

GM:on("airplaneStarted", function(match)
	showInitialZone(match)
	revealNextZone(match)
end)

GM:on("matchStarted", function(match)
	startPhaseProgression(match)
end)

GM:registerNetEvent("safezone.useRadar", function(match, src)
	local szData = match:getData("safezone")

	if not szData then
		return
	end

	local phase = szData.currentPhase or 1
	local zones = szData.zones
	local nextPhase = phase + 1

	if nextPhase > #zones then
		return
	end

	local nextZone = zones[nextPhase]

	if not nextZone or not nextZone.center then
		nextZone = computeIncrementalZone(match, nextPhase)
	end

	if not nextZone or not nextZone.center then
		return
	end

	local squadIndex = match.playerSquad[src]
	local targets = squadIndex and match.squads[squadIndex] and match.squads[squadIndex].players or { src }
	local eventName = ("net.%s:safezone.radar.reveal"):format(GetCurrentResourceName())

	for i = 1, #targets do
		local target = targets[i]
		if match:getPlayerState(target) == PlayerState.ALIVE then
			TriggerClientEvent(eventName, target, nextZone.center.x, nextZone.center.y, nextZone.radius)
		end
	end

	log("info", ("match %d: radar used by src=%d (phase %d -> %d, squad-wide)"):format(match.id, src, phase, nextPhase))
end)

GM:on("matchEnding", function(match)
	emitSafezoneEvent(match, "kingg:safezone:stop")
end)
