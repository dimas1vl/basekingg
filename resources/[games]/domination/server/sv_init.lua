print("^3[dom-sv] script carregando, esperando Core...^7")

coreWaitStart = GetGameTimer()
CreateThread(function()
	while not Core do
		if GetGameTimer() - coreWaitStart > 3000 then
			print("^1[dom-sv] AVISO: Core ainda nil apos 3s — fxmanifest pode estar errado^7")
			coreWaitStart = GetGameTimer()
		end
		Wait(100)
	end
	print(("^2[dom-sv] Core disponivel apos %dms^7"):format(GetGameTimer() - coreWaitStart))
end)

while not Core do
	Wait(100)
end

print("^2[dom-sv] Core OK, alocando bucket...^7")

---@type table<number, table> sessions[src] = { zoneId, userId, xp, level, kills, deaths, owned, equipped, lastDeath }
sessions = {}
lastKiller = {}
reportAt = {}
SHARED_BUCKET = Core.allocateBucket()

LOCATION_BUCKETS = {}
do
	local locs = Config.Domination.locations or {}
	for i = 1, #locs do
		LOCATION_BUCKETS[locs[i].id] = Core.allocateBucket()
	end
end

print(
	("^2[dom-sv] SHARED_BUCKET=%d (+%d buckets ocultos), script pronto.^7"):format(
		SHARED_BUCKET,
		#(Config.Domination.locations or {})
	)
)

Sql = {}
function Sql.single(q, p)
	return exports["oxmysql"]:singleSync(q, p)
end
function Sql.query(q, p)
	return exports["oxmysql"]:querySync(q, p)
end
function Sql.execute(q, p)
	return exports["oxmysql"]:executeSync(q, p)
end
function Sql.insert(q, p)
	return exports["oxmysql"]:insertSync(q, p)
end

DDL = {
	domination_progress = [[
        CREATE TABLE IF NOT EXISTS `domination_progress` (
            `user_id` INT(11) NOT NULL,
            `xp`      INT(10) UNSIGNED NOT NULL DEFAULT 0,
            `money`   INT(10) UNSIGNED NOT NULL DEFAULT 0,
            PRIMARY KEY (`user_id`) USING BTREE,
            CONSTRAINT `fk_dom_progress_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
        ) COLLATE='utf8mb4_unicode_ci' ENGINE=InnoDB;
    ]],
	domination_weapons = [[
        CREATE TABLE IF NOT EXISTS `domination_weapons` (
            `user_id`     INT(11) NOT NULL,
            `weapon_id`   VARCHAR(64) NOT NULL,
            `acquired_at` TIMESTAMP NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`user_id`, `weapon_id`) USING BTREE,
            CONSTRAINT `fk_dom_weapons_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
        ) COLLATE='utf8mb4_unicode_ci' ENGINE=InnoDB;
    ]],
	domination_loadout = [[
        CREATE TABLE IF NOT EXISTS `domination_loadout` (
            `user_id`   INT(11) NOT NULL,
            `category`  VARCHAR(32) NOT NULL,
            `weapon_id` VARCHAR(64) NOT NULL,
            PRIMARY KEY (`user_id`, `category`) USING BTREE,
            CONSTRAINT `fk_dom_loadout_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
        ) COLLATE='utf8mb4_unicode_ci' ENGINE=InnoDB;
    ]],
	domination_vehicles = [[
        CREATE TABLE IF NOT EXISTS `domination_vehicles` (
            `user_id`     INT(11) NOT NULL,
            `vehicle_id`  VARCHAR(64) NOT NULL,
            `acquired_at` TIMESTAMP NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`user_id`, `vehicle_id`) USING BTREE,
            CONSTRAINT `fk_dom_vehicles_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
        ) COLLATE='utf8mb4_unicode_ci' ENGINE=InnoDB;
    ]],
	domination_vehicle_favorites = [[
        CREATE TABLE IF NOT EXISTS `domination_vehicle_favorites` (
            `user_id`    INT(11) NOT NULL,
            `vehicle_id` VARCHAR(64) NOT NULL,
            PRIMARY KEY (`user_id`, `vehicle_id`) USING BTREE,
            CONSTRAINT `fk_dom_vehfav_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
        ) COLLATE='utf8mb4_unicode_ci' ENGINE=InnoDB;
    ]],
	domination_teams = [[
        CREATE TABLE IF NOT EXISTS `domination_teams` (
            `id`         INT(11) NOT NULL AUTO_INCREMENT,
            `name`       VARCHAR(32) NOT NULL,
            `leader_id`  INT(11) NOT NULL,
            `discord`    VARCHAR(255) NULL DEFAULT NULL,
            `created_at` TIMESTAMP NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`id`) USING BTREE,
            UNIQUE INDEX `name` (`name`) USING BTREE
        ) COLLATE='utf8mb4_unicode_ci' ENGINE=InnoDB;
    ]],
	domination_team_members = [[
        CREATE TABLE IF NOT EXISTS `domination_team_members` (
            `user_id`   INT(11) NOT NULL,
            `team_id`   INT(11) NOT NULL,
            `role`      ENUM('lider','gerente','sublider','recrutador','membro') NOT NULL DEFAULT 'membro' COLLATE 'utf8mb4_unicode_ci',
            `joined_at` TIMESTAMP NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`user_id`) USING BTREE,
            INDEX `team_id` (`team_id`) USING BTREE,
            CONSTRAINT `fk_dom_team_member_team` FOREIGN KEY (`team_id`) REFERENCES `domination_teams` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
            CONSTRAINT `fk_dom_team_member_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
        ) COLLATE='utf8mb4_unicode_ci' ENGINE=InnoDB;
    ]],
}

MIGRATIONS = {
	[[ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `last_login` TIMESTAMP NULL DEFAULT NULL]],
	[[ALTER TABLE `domination_progress` ADD COLUMN IF NOT EXISTS `money` INT(10) UNSIGNED NOT NULL DEFAULT 0]],
}

CreateThread(function()
	Wait(500)

	local order = {
		"domination_progress",
		"domination_weapons",
		"domination_loadout",
		"domination_vehicles",
		"domination_vehicle_favorites",
		"domination_teams",
		"domination_team_members",
	}
	for _, name in ipairs(order) do
		local ddl = DDL[name]
		if ddl then
			local ok, err = pcall(Sql.execute, ddl)
			if ok then
				print(("^2[dom-sv] tabela %s OK^7"):format(name))
			else
				print(("^1[dom-sv] falha criando tabela %s: %s^7"):format(name, tostring(err)))
			end
		end
	end
	for _, m in ipairs(MIGRATIONS) do
		pcall(Sql.execute, m)
	end
end)
