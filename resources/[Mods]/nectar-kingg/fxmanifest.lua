fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Lucas'
description 'NECTAR'
discord 'discord.gg/nectar'

escrow_ignore {
    'stream/**/*.ytd',
	'data/**/*.meta',
}

files {
	"data/**/*.meta"
}

data_file 'WEAPONINFO_FILE_PATCH' 'data/weapons.meta'
data_file "VEHICLE_LAYOUTS_FILE" "data/**/vehiclelayouts.meta"
data_file "HANDLING_FILE" "data/**/handling.meta"
data_file "VEHICLE_METADATA_FILE" "data/**/vehicles.meta"
data_file "CARCOLS_FILE" "data/**/carcols.meta"
data_file "VEHICLE_VARIATION_FILE" "data/**/carvariations.meta"