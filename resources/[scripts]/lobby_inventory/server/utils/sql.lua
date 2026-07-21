---@class InventarioSql
Sql = {}

---@param query string
---@param params? any[]
---@return table | nil
function Sql.single(query, params)
	return exports["oxmysql"]:singleSync(query, params)
end

---@param query string
---@param params? any[]
---@return table
function Sql.query(query, params)
	return exports["oxmysql"]:querySync(query, params)
end

---@param query string
---@param params? any[]
---@return any
function Sql.execute(query, params)
	return exports["oxmysql"]:executeSync(query, params)
end

---@param query string
---@param params? any[]
---@return number
function Sql.insert(query, params)
	return exports["oxmysql"]:insertSync(query, params)
end

---@param queries table[]
---@return boolean
function Sql.transaction(queries)
	return MySQL.transaction.await(queries)
end

---@param userId number
---@return table
function Sql.readAppearance(userId)
	if Core and Core.users_info and Core.users_info[userId] then
		return Core.users_info[userId].appearance or {}
	end

	local row = Sql.single("SELECT `appearance` FROM `users` WHERE `id` = ?", { userId })

	if not row or not row.appearance then
		return {}
	end

	if type(row.appearance) == "table" then
		return row.appearance
	end

	local ok, parsed = pcall(json.decode, row.appearance)

	return (ok and type(parsed) == "table") and parsed or {}
end

---@param userId number
---@param appearance table
function Sql.writeAppearance(userId, appearance)
	local jsonText = json.encode(appearance or {})

	Sql.execute("UPDATE `users` SET `appearance` = ? WHERE `id` = ?", { jsonText, userId })

	if Core and Core.users_info and Core.users_info[userId] then
		Core.users_info[userId].appearance = appearance
	end
end

local function log(level, msg)
	if Core and Core.log then
		return Core.log(level, ("[inventario] %s"):format(msg))
	end
	print(("[inventario] [%s] %s"):format(level, msg))
end
Sql.log = log

local DDL = {
	cosmetic_items = [[
        CREATE TABLE IF NOT EXISTS `cosmetic_items` (
            `id`          VARCHAR(80) NOT NULL,
            `name`        VARCHAR(120) NOT NULL,
            `category`    VARCHAR(40) NOT NULL,
            `subcategory` VARCHAR(40) NOT NULL,
            `rarity`      ENUM('common','rare','epic','legendary','mythic') NOT NULL DEFAULT 'common',
            `price`       INT(10) UNSIGNED NULL DEFAULT NULL,
            `purchasable` TINYINT(1) NOT NULL DEFAULT 0,
            `image`       VARCHAR(255) NULL DEFAULT NULL,
            `metadata`    LONGTEXT NOT NULL,
            `enabled`     TINYINT(1) NOT NULL DEFAULT 1,
            `created_at`  TIMESTAMP NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`id`) USING BTREE,
            INDEX `idx_category_subcategory` (`category`, `subcategory`) USING BTREE,
            INDEX `idx_purchasable_enabled` (`purchasable`, `enabled`) USING BTREE,
            FULLTEXT INDEX `idx_name` (`name`),
            CONSTRAINT `metadata_json` CHECK (json_valid(`metadata`))
        )
        COLLATE='utf8mb4_unicode_ci'
        ENGINE=InnoDB
        ;
    ]],

	player_inventory = [[
        CREATE TABLE IF NOT EXISTS `player_inventory` (
            `user_id`      INT(11) NOT NULL,
            `item_id`      VARCHAR(80) NOT NULL,
            `source`       ENUM('shop','lootbox','event','reward','admin','migration','system') NOT NULL DEFAULT 'system',
            `source_ref`   VARCHAR(120) NULL DEFAULT NULL,
            `acquired_at`  TIMESTAMP NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`user_id`, `item_id`) USING BTREE,
            INDEX `idx_item` (`item_id`) USING BTREE,
            CONSTRAINT `fk_player_inventory_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
            CONSTRAINT `fk_player_inventory_item` FOREIGN KEY (`item_id`) REFERENCES `cosmetic_items` (`id`) ON UPDATE NO ACTION ON DELETE RESTRICT
        )
        COLLATE='utf8mb4_unicode_ci'
        ENGINE=InnoDB
        ;
    ]],
}

CreateThread(function()
	while not Core do
		Wait(100)
	end
	Wait(500)

	for name, ddl in pairs(DDL) do
		log("info", ("Creating table ^2%s^7 if not exists"):format(name))
		local ok, err = pcall(Sql.execute, ddl)
		if not ok then
			log("error", ("failed to create table %s: %s"):format(name, tostring(err)))
		end
	end

	pcall(Sql.execute, "DROP TABLE IF EXISTS `player_equipped_inventario`")
end)
