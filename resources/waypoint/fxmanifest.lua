fx_version 'cerulean'
game 'gta5'

version '1.1.0'
lua54 'yes'
author 'DemiAutomatic'

files {
    'config.lua',
    'web/*',
    'client/modules/*.lua',
    'server/modules/*.lua',
}

shared_scripts {
    'module_loader.lua',
    'config.lua',
    'test.lua' -- Uncomment this line to enable test commands
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/version.lua',
    'server/main.lua',
}
