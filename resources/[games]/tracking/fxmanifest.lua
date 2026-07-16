fx_version 'cerulean'
game 'gta5'
author 'Wesley'
lua54 'yes'

dependency 'kingg'

ui_page 'nui/index.html'

shared_scripts {
    '@kingg/shared/lib.lua',
    'config/*.lua',
    'config/**/**/*.lua',
}

client_scripts {
    'client/lib/circlezone.lua',
    'client/bucket.lua',
    'client/state.lua',
    'client/interface/**/*.lua',
    'client/modules/**/*.lua',
    'client/cannonImpulse/**/*.lua',
    'client/modes/**/**/*.lua',
}

server_scripts {
    'server/main.lua',
}

files {
    'nui/index.html',
    'nui/styles.css',
    'nui/displayController.js',
    'nui/app.js',
    'nui/config-panel.js',
    'nui/react-hud/index.html',
    'nui/react-hud/**/*',
    'images/*.png',
}
