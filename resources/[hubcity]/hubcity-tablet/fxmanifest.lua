fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Hub City Roleplay 5M (Muse for Daniel)'
description 'Hub City Tablet — the phone flips out into tablet mode: wide app grid with Black Market, Vibez and Need 2 Speed (street racing). Open it from the phone (Tablet Mode app / tablettoggle keybind) or with the standalone tablet item. Includes the rotating black-market dealer system.'
version '1.2.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_inventory',
    'ox_target',
}
