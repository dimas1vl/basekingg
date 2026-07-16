server_script '@oxmysql/lib/MySQL.lua'

game 'gta5'
fx_version 'cerulean'

dependencies { 'kingg', 'inventory', 'minimap-racco', 'waypoint' }

shared_scripts {
    '@kingg/shared/lib.lua',
    'shared/**/*',
}

server_scripts {
    'server/classes/match.lua',
    'server/classes/gamemode.lua',
    'server/modules/*.lua',
    'server/main.lua',
}

ui_page 'web/build/index.html'
files {
    'web/build/**/*',
}


client_scripts {
    'client/core/lib.lua',
    'client/core/tracker.lua',
    'client/core/ui.lua',
    'client/core/session.lua',
    'client/core/module.lua',
    'client/features/prompts.lua',
    'client/features/hud.lua',
    'client/features/combat.lua',
    'client/features/squad.lua',
    'client/features/loadout.lua',
    'client/features/loot.lua',
    'client/features/transport.lua',
    'client/features/totem.lua',
    'client/features/zone.lua',
    'client/features/scan.lua',
    'client/features/airdrop.lua',
    'client/features/plane.lua',
    'client/features/arena.lua',
    'client/features/observer.lua',
    'client/features/pregame.lua',
    'client/bootstrap.lua',
}
