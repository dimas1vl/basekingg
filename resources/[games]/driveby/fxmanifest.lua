game 'gta5'
fx_version 'cerulean'

dependency 'kingg'

shared_scripts {
    '@kingg/shared/lib.lua',
    'shared/**/*',
}

server_scripts {
    'server/classes/match.lua',
    'server/classes/gamemode.lua',
    'server/main.lua',
}

client_scripts {
    'client/classes/matchclient.lua',
    'client/main.lua',
}

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/**/*',
}
