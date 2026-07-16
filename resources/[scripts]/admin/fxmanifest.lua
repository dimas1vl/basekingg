server_script '@oxmysql/lib/MySQL.lua'

game 'gta5'
fx_version 'cerulean'

dependency 'kingg'

shared_scripts {
    '@kingg/shared/lib.lua',
    'shared/**/*',
}

server_scripts {
    'server/main.lua',
    'server/utils/**',
    'server/modules/**',
}

client_scripts {
    'client/main.lua',
    'client/modules/**',
}

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/**/*',
}
