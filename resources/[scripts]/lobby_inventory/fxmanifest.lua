server_script '@oxmysql/lib/MySQL.lua'

game 'gta5'
fx_version 'cerulean'

dependency 'kingg'

shared_scripts {
    '@kingg/shared/lib.lua',
    'shared/config.lua',
    'shared/events.lua',
    'shared/lib.lua',
    'shared/catalog/**/*.lua',
}

server_scripts {
    'server/utils/**/*.lua',
    'server/modules/**/*.lua',
    'server/main.lua',
}

client_scripts {
    'client/**/*.lua',
}
