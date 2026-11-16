fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Hub City Roleplay'
description 'Hub City Laundering — wash marked bills into clean bank money at hidden spots advertised only in the tablet Black Market app'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_target',
    'ox_inventory',
}
