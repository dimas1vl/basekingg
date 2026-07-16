server_script '@oxmysql/lib/MySQL.lua'

game 'gta5'
fx_version 'cerulean'

shared_script 'shared/**'

server_scripts {
    'server/utils/log.lua',
    'server/modules/**',
    'server/main.lua',
    'server/utils/**'
}

client_scripts {'client/**'}