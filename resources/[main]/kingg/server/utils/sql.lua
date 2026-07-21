--TODO: Trocar pra dependencia do oxmysql pra chamar via MySQL.Async / Sync

---@param query string
---@param params any[]
---@return table
---Synchronous query
function Core.Query(query, params)
	return exports["oxmysql"]:querySync(query, params)
end

---@param query string
---@param params any[]
---@return table
---Asynchronous query
function Core._Query(query, params)
	return exports["oxmysql"]:query(query, params)
end

function Core.single(query, params)
	return exports["oxmysql"]:singleSync(query, params)
end

---@param query string
---@param params any[]
---@return table
---Asynchronous execute
function Core._Execute(query, params)
	return exports["oxmysql"]:execute(query, params)
end

---@param query string
---@param params any[]
---@return table
---Asynchronous insert
function Core._Insert(query, params)
	return exports["oxmysql"]:insert(query, params)
end

---@param query string
---@param params any[]
---@return table
---Asynchronous update
function Core._Update(query, params)
	return exports["oxmysql"]:update(query, params)
end

---@param query string
---@param params any[]
---@return table
---Synchronous insert
function Core.Insert(query, params)
	return exports["oxmysql"]:insertSync(query, params)
end

CreateThread(function()
	local tables = {
		users = [[
            CREATE TABLE IF NOT EXISTS `users` (
                `id` INT(11) NOT NULL AUTO_INCREMENT,
                `xp` INT(10) UNSIGNED NULL DEFAULT '0',
                `gems` INT(10) UNSIGNED NULL DEFAULT '0',
                `premium` TINYINT(3) UNSIGNED NULL DEFAULT '0',
                `crew_id` INT(10) UNSIGNED NULL DEFAULT '0',
                `role` ENUM('user','admin','spec') NULL DEFAULT 'user' COLLATE 'utf8mb4_unicode_ci',
                `banner` INT(11) NULL DEFAULT '1' COMMENT 'Selected banner',
                `badges` LONGTEXT NULL DEFAULT json_array() COMMENT 'BadgesId[]' COLLATE 'utf8mb4_bin',
                `wins` INT(10) UNSIGNED NULL DEFAULT '0',
                `loss` INT(10) UNSIGNED NULL DEFAULT '0',
                `kills` INT(10) UNSIGNED NULL DEFAULT '0',
                `deaths` INT(10) UNSIGNED NULL DEFAULT '0',
                `name` VARCHAR(150) NULL DEFAULT NULL COLLATE 'utf8mb4_unicode_ci',
                `gender` ENUM('male','female') NULL DEFAULT NULL COLLATE 'utf8mb4_unicode_ci',
                `birthdate` DATE NULL DEFAULT NULL,
                `appearance` LONGTEXT NULL DEFAULT NULL COLLATE 'utf8mb4_bin',
                `allowed` TINYINT(1) NOT NULL DEFAULT '0',
                PRIMARY KEY (`id`) USING BTREE,
                CONSTRAINT `badges` CHECK (json_valid(`badges`)),
                CONSTRAINT `appearance_json` CHECK (`appearance` IS NULL OR json_valid(`appearance`))
            )
            COLLATE='utf8mb4_unicode_ci'
            ENGINE=InnoDB
            AUTO_INCREMENT=4
            ;
        ]],
		bans = [[
        CREATE TABLE IF NOT EXISTS `bans` (
            `user_id` INT(11) NOT NULL,
            `reason` VARCHAR(255) NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
            `staff_id` INT(11) NULL DEFAULT '0',
            `created_at` TIMESTAMP NULL DEFAULT current_timestamp(),
            `expires_at` TIMESTAMP NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`user_id`) USING BTREE
        )
        COLLATE='utf8mb4_unicode_ci'
        ENGINE=InnoDB
        ;
        ]],
		identifiers = [[
        CREATE TABLE IF NOT EXISTS `identifiers` (
            `user_id` INT(11) NULL DEFAULT NULL,
            `identifier` VARCHAR(255) NULL DEFAULT NULL COLLATE 'utf8mb4_unicode_ci',
            UNIQUE INDEX `identifier` (`identifier`) USING BTREE
        )
        COLLATE='utf8mb4_unicode_ci'
        ENGINE=InnoDB
        ;
        ]],
		friends = [[
        CREATE TABLE IF NOT EXISTS `friends` (
                `id` INT(11) NOT NULL AUTO_INCREMENT,
                `user_id` INT(11) NULL DEFAULT NULL,
                `friend_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
                `createdAt` TIMESTAMP NULL DEFAULT current_timestamp(),
                PRIMARY KEY (`id`) USING BTREE,
                UNIQUE INDEX `user_id_friend_id` (`user_id`, `friend_id`) USING BTREE
            )
            COLLATE='utf8mb4_unicode_ci'
            ENGINE=InnoDB
            ;
        ]],
		weapons = [[
            CREATE TABLE IF NOT EXISTS `weapons` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`user_id` INT(11) NULL DEFAULT NULL,
	`category` ENUM('smg','rifle','pistol') NULL DEFAULT NULL COLLATE 'utf8mb4_unicode_ci',
	`skin_id` VARCHAR(255) NULL DEFAULT NULL COLLATE 'utf8mb4_unicode_ci',
	`equipped` TINYINT(4) NULL DEFAULT '0',
	PRIMARY KEY (`id`) USING BTREE,
	UNIQUE INDEX `user_id_category_skin_id` (`user_id`, `category`, `skin_id`) USING BTREE,
	CONSTRAINT `FK__users` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
)
COLLATE='utf8mb4_unicode_ci'
ENGINE=InnoDB
;

        ]],
	}
	for k, v in pairs(tables) do
		log("info", ("Creating table ^2%s^7 if not exists"):format(k))
		Core._Execute(v)
	end

	local migrations = {
		[[ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `gender` ENUM('male','female') NULL DEFAULT NULL COLLATE 'utf8mb4_unicode_ci' AFTER `name`]],
		[[ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `birthdate` DATE NULL DEFAULT NULL AFTER `gender`]],
		[[ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `appearance` LONGTEXT NULL DEFAULT NULL COLLATE 'utf8mb4_bin' AFTER `birthdate`]],
		[[ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `allowed` TINYINT(1) NOT NULL DEFAULT 0 AFTER `appearance`]],
	}
	for _, m in ipairs(migrations) do
		Core._Execute(m)
	end
end)
