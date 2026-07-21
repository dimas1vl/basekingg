local Zone = Game.module("zone")

local cfgTimecycle = Config.BR.timecycles
local cfgSafe = Config.BR.safezone
local outsideZone = false
local gasDmgStart = 0
local hasRadar = false
local radarBlip = nil
local winCelebration = false
local currentStage = 0
local totalStages = 1
local dmgPerTick = 0
local phaseGen = 0

local function fmtTimer(secs)
	return ("%02d:%02d"):format(math.floor(secs / 60), secs % 60)
end

function isCoordsSafezone(x, y)
	local state = exports["kingg"]:getSafezoneState()
	if not state or not state.active or not state.gas then
		return true
	end
	local dx = x - state.gas.x
	local dy = y - state.gas.y
	return (dx * dx + dy * dy) < (state.gas.radius * state.gas.radius)
end

function Zone:setup(ctx)
	outsideZone = false
	gasDmgStart = 0
	hasRadar = false
	radarBlip = nil
	winCelebration = false
	currentStage = 0
	totalStages = 1
	dmgPerTick = 0
	phaseGen = phaseGen + 1
end

function Zone:teardown(ctx)
	Game.removeBlip(radarBlip)
	radarBlip = nil
	SetTimecycleModifier(cfgTimecycle.default)
	ClearTimecycleModifier()
	outsideZone = false
	gasDmgStart = 0
	hasRadar = false
	winCelebration = false
	currentStage = 0
	dmgPerTick = 0
	phaseGen = phaseGen + 1
	SetRadarZoom(0)
end

local RADAR_BASE_ZOOM = cfgSafe.radarZoomBase
local RADAR_ZOOM_DROP = cfgSafe.radarZoomDrop

function Zone:updateRadarZoom()
	if totalStages <= 3 then
		return
	end
	local t = 1 - (totalStages - currentStage) / (totalStages - 3)
	SetRadarZoom(RADAR_BASE_ZOOM - math.floor(RADAR_ZOOM_DROP * t))
end

RegisterNetEvent("kingg:safezone:start", function(data)
	print(
		("[zone] kingg:safezone:start received — damage=%s phase=%s"):format(
			tostring(data.damage),
			tostring(data.phase)
		)
	)
	if data.gas then
		print(("[zone] gas circle: x=%.1f y=%.1f r=%.1f"):format(data.gas.x, data.gas.y, data.gas.radius))
	end
	if data.safe then
		print(("[zone] safe circle: x=%.1f y=%.1f r=%.1f"):format(data.safe.x, data.safe.y, data.safe.radius))
	end
	dmgPerTick = data.damage or 0
	currentStage = data.phase or 1
	Wait(2000)
	SetTimecycleModifier(cfgTimecycle.default)
	SetTimecycleModifierStrength(1.0)
	Wait(2000)
	exports["kingg"]:setSafezoneHandlers({
		onOut = function()
			if winCelebration then
				return
			end
			outsideZone = true
			gasDmgStart = GetGameTimer()
			SetTimecycleModifier(cfgTimecycle.gas)
			SetTimecycleModifierStrength(1.0)
		end,
		onIn = function()
			outsideZone = false
			gasDmgStart = 0
			SetTimecycleModifier(cfgTimecycle.default)
			SetTimecycleModifierStrength(1.0)
		end,
		onDamageTick = function(baseDamage)
			local ped = PlayerPedId()
			if winCelebration or GetEntityHealth(ped) <= 0 then
				return
			end
			local elapsed = GetGameTimer() - gasDmgStart
			local extra = math.floor(elapsed / cfgSafe.damageDivisorMs)
			ApplyDamageToPed(ped, baseDamage + extra)
		end,
	})
end)

Game.session:onNet("safezone.countdown", function(phase, displayTime, totalPh)
	print(
		("[zone] safezone.countdown received — phase=%s displayTime=%s totalPh=%s"):format(
			tostring(phase),
			tostring(displayTime),
			tostring(totalPh)
		)
	)
	currentStage = phase
	phaseGen = phaseGen + 1
	if totalPh then
		totalStages = totalPh
	end
	local gen = phaseGen

	CreateThread(function()
		local rem = displayTime
		while rem >= 0 and gen == phaseGen do
			Game.ui.send("hud:phase", {
				timer = fmtTimer(rem),
				phase = currentStage,
				totalPhases = totalStages,
				progress = rem / displayTime,
			})
			Wait(1000)
			rem = rem - 1
		end
	end)
end)

RegisterNetEvent("kingg:safezone:phase", function(phase, damage)
	print(("[zone] kingg:safezone:phase received — phase=%s damage=%s"):format(tostring(phase), tostring(damage)))
	currentStage = phase
	dmgPerTick = damage
	Game.ui.send("hud:safezone", {
		visible = true,
		title = "ZONA DE GAS",
		message = ("Fase %d - A zona esta encolhendo!"):format(phase),
	})
	SetTimeout(5000, function()
		Game.ui.send("hud:safezone", { visible = false, title = "", message = "" })
	end)
	Zone:updateRadarZoom()
end)

RegisterNetEvent("kingg:safezone:shrink", function(_startTime, shrinkMs)
	print(("[zone] kingg:safezone:shrink received — shrinkMs=%s"):format(tostring(shrinkMs)))
	phaseGen = phaseGen + 1
	Game.ui.send("hud:safezone", {
		visible = true,
		title = "ZONA ENCOLHENDO",
		message = "Corra para a zona segura!",
	})
	SetTimeout(5000, function()
		Game.ui.send("hud:safezone", { visible = false, title = "", message = "" })
	end)

	if shrinkMs <= 0 then
		return
	end
	local gen = phaseGen
	local localStart = GetGameTimer()

	CreateThread(function()
		while gen == phaseGen do
			local elapsed = GetGameTimer() - localStart
			local pct = math.min(elapsed / shrinkMs, 1.0)
			local remSec = math.max(0, math.ceil((shrinkMs - elapsed) / 1000))
			Game.ui.send("hud:phase", {
				timer = fmtTimer(remSec),
				phase = currentStage,
				totalPhases = totalStages,
				progress = pct,
			})
			if pct >= 1.0 then
				break
			end
			Wait(100)
		end
	end)
end)

Game.session:onNet("safezone.radar.set", function(enabled)
	hasRadar = enabled
	if enabled then
		Game.ui.notify("Habilidade especial disponivel [X]", 5)
	end
end)

RegisterCommand("+br:radar", function()
	if not Game.session:active() then
		return
	end
	if not hasRadar then
		return
	end
	hasRadar = false
	Game.session:send("safezone.useRadar")
end, false)
RegisterKeyMapping("+br:radar", "Usar Radar", "keyboard", "X")

Game.session:onNet("safezone.radar.reveal", function(x, y, radius)
	Game.removeBlip(radarBlip)
	radarBlip = AddBlipForRadius(x, y, 0.0, radius * 1.0)
	SetBlipColour(radarBlip, 42)
	SetBlipSprite(radarBlip, 9)
	SetBlipAlpha(radarBlip, 170)
end)

Game.session:onNet("safezone.win", function()
	winCelebration = true
	Game.ui.send("hud:safezone", {
		visible = true,
		title = "VITORIA",
		message = "Parabens! Voce venceu a partida!",
	})
end)

Game.session:listen("ended", function()
	TriggerEvent("kingg:safezone:stop")
end)
