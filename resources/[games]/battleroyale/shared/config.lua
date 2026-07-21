Config = Config or {}
Config.ping = {
	cooldown = 1000,
	markerDuration = 10000,
}
Config.BR = {
	airplane = {
		model = "Addon002",
		pilotModel = "s_m_y_pilot_01",
		altitude = 800.0,
		speed = 100.0,
		autoEjectDistance = 150.0,
	},

	parachute = {
		autoOpenHeight = 80.0,
		forceOpenMin = 20.0,
		forceOpenMax = 85.0,
		groundSnap = 5.0,
	},

	injury = {
		bleedDamage = 4,
		bleedOutTime = 30000,
		reviveTime = 5000,
		reviveHealth = 0.4,
		reviveRange = 3.0,
		idleAnim = { dict = "anim@scripted@ulp_missions@injured_agent@", name = "idle" },
		getupAnim = { dict = "get_up@directional@movement@from_knees@injured", name = "getup_l_0" },
	},

	safezone = {
		initialCenter = vector3(-396.65084838867, -850.35668945312, 0.0),
		initialRadius = 1500.0,
		initialReveal = 30.0,
		dynamic = {
			candidates = 8,
			areaRadius = 250.0,
			minImprovement = 0.25,
			finalPhases = 2,
			gasOverlap = 0.5,
			radiusJitter = 0.15,
			finalRadiusJitter = 0.30,
		},
		presets = {
			{ radius = 1500.0, damage = 5, displayTime = 60, shrinkTime = 120 },
			{ radius = 1150.0, damage = 5, displayTime = 120, shrinkTime = 60 },
			{ radius = 900.0, damage = 5, displayTime = 120, shrinkTime = 60 },
			{ radius = 750.0, damage = 5, displayTime = 120, shrinkTime = 60 },
			{ radius = 500.0, damage = 5, displayTime = 120, shrinkTime = 60 },
			{ radius = 350.0, damage = 10, displayTime = 90, shrinkTime = 60 },
			{ radius = 250.0, damage = 15, displayTime = 90, shrinkTime = 60 },
			{ radius = 150.0, damage = 20, displayTime = 90, shrinkTime = 60 },
			{ radius = 100.0, damage = 25, displayTime = 90, shrinkTime = 60 },
			{ radius = 50.0, damage = 30, displayTime = 90, shrinkTime = 60 },
			{ radius = 25.0, damage = 50, displayTime = 90, shrinkTime = 60 },
			{ radius = 0.01, damage = 50, displayTime = 90, shrinkTime = 60 },
		},
	},

	warmup = {
		parachuteAltitude = 450.0,
		countdown = 10,
		lobbySpawns = {
			vec4(-3784.38, -1684.13, 13.24, 199.3),
			vec4(-3765.98, -1675.14, 13.24, 175.8),
			vec4(-3796.88, -1663.54, 12.49, 201.7),
			vec4(-3814.09, -1688.53, 13.21, 225.2),
		},
		warmupSpawns = {
			vec(2722.42, 1341.24, 24.52, 184.8),
			vec(2742.17, 1351.51, 24.52, 251.2),
			vec(2724.32, 1368.50, 24.52, 101.8),
			vec(2700.98, 1362.96, 24.52, 233.1),
			vec(2684.98, 1351.54, 24.52, 110.6),
		},
	},

	timecycles = {
		default = "cinema",
		gas = "glasses_purple",
	},

	vehicles = {
		spawnChance = 0.7,
		lodDistance = 250,
		unlockRange = 5.0,
	},

	loot = {
		chestSpawnChance = 0.8,
		chestLod = 100,
		chestOpenTime = 1500,
		chestInteractRange = 2.5,
		pickupLod = 50,
		pickupInteractRange = 2.0,
		radarRange = 200,
		radarBlipDuration = 10000,
	},

	inventory = {
		slots = 5,
		cancelCooldown = 1500,
		maxHealth = 400,
		healPerUse = 150,
		armourCap = 100,
		useTime = 5000,
	},

	collectables = {
		spawnChance = 0.5,
		lodDistance = 100,
		collectRange = 1.5,
		collectTime = 1000,
	},

	airdrop = {
		descentDuration = 50000,
		startHeight = 180.0,
		collectRange = 3.0,
		collectTime = 5000,
		openDuration = 10000,
		spawnDelayMin = 60,
		spawnDelayMax = 120,
	},

	vant = {
		radius = 200,
		duration = 10000,
	},

	ping = {
		cooldown = 500,
		markerDuration = 15000,
	},

	duel = {
		damagePhaseTime = 90000,
		damageTick = 75,
		damageAmount = 1,
		forfeitHoldTime = 1500,
	},

	revive = {
		reviveRange = 2.0,
		reviveTime = 5000,
		totemCooldown = 180000,
		totemInteractRange = 3.0,
		reviveHealth = 0.4,
		reviveWeapon = "WEAPON_PISTOL_MK2",
		reviveAmmo = 12,
	},
}

Config.BR.anims = {
	revive = "amb@medic@standing@tendtodead@idle_a",
}

Config.BR.bones = {
	head = 31086,
}

Config.BR.airplane.ejectDivisor = 115
Config.BR.airplane.ejectFlag = 16
Config.BR.airplane.blip = { sprite = 307, scale = 0.85, display = 8 }

Config.BR.prone = {
	disabledControls = { 24, 25, 144 },
	key = "Z",
	crawlMs = {
		belly = { fwd = 800, bwd = 1050 },
		supine = { fwd = 1150, bwd = 1150 },
	},
	rotations = {
		belly = { left = -12.0, right = 12.0 },
		supine = { left = 22.0, right = -22.0 },
	},
	flipRot = { toBelly = 14.0, toSupine = -20.0 },
}

Config.BR.smoke = {
	duration = 28000,
	fadeIn = 250,
	fadeOut = 4500,
	scale = 5.0,
}

Config.BR.ping.texture = "pings_kingg"
Config.BR.ping.spriteEnemy = "enemy"
Config.BR.ping.scaleX = 0.055
Config.BR.ping.scaleY = 0.095
Config.BR.ping.markerZ = -50.0
Config.BR.ping.markerHeight = 1000.0
Config.BR.ping.renderDist = 650
Config.BR.ping.key = "MOUSE_MIDDLE"

Config.BR.loot.chests = {
	{ category = "RIFLE", model = "kingg_lootbox_red" },
	{ category = "SUB", model = "kingg_lootbox_blue" },
	{ category = "HEALTH", model = "kingg_lootbox_grenn" },
	{ category = "AMMO", model = "kingg_lootbox_yellow" },
	{ category = "GRENADES", model = "kingg_lootbox_purple" },
}

Config.BR.safezone.radarZoomBase = 1250
Config.BR.safezone.radarZoomDrop = 188
Config.BR.safezone.damageDivisorMs = 25000

Config.BR.injury.disabledControls = { 21, 22, 24, 25 }
