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
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

ui_page 'web/build/index.html'

files {
    'nui/overlay.html',
    'nui/overlay.css',
    'nui/overlay.js',
    'nui/assets/**/*',
    'web/build/index.html',
    'web/build/**/*',
}
