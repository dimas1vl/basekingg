fx_version 'cerulean'
game 'gta5'
author 'KinGG'
lua54 'yes'

dependency 'kingg'

shared_scripts {
    '@kingg/shared/lib.lua',
    'shared/config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_init.lua',
    'server/sv_progression.lua',
    'server/sv_vehicles.lua',
    'server/sv_zones.lua',
    'server/sv_shop.lua',
    'server/sv_combat.lua',
    'server/sv_team.lua',
    'server/sv_admin.lua',
}

client_scripts {
    'client/cl_core.lua',
    'client/cl_loadout.lua',
    'client/cl_spectate.lua',
    'client/cl_respawn.lua',
    'client/cl_session.lua',
    'client/cl_menus.lua',
    'client/cl_vehicles.lua',
    'client/cl_flag.lua',
    'client/cl_team.lua',
    'client/cl_settings.lua',
    'client/cl_markers.lua',
    'client/cl_exports.lua',
}

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/**/*',
    'web/build/sounds/**/*',
}
