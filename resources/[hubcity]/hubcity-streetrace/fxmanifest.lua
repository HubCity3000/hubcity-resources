fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Hub City Roleplay 5M (Muse for Daniel)'
description 'Hub City Street Racing — the "Need 2 Speed" app in the tablet (phone tablet mode) is the ONLY way in. Fast & Furious style street races: preset routes, checkpoint racing, live positions, records, and an NPC blocker crew that seals side streets along the route while a race runs.'
version '1.0.0'

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
    'oxmysql',
    'hubcity-tablet',
}
