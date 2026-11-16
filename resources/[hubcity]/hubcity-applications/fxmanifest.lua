fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Hub City Roleplay 5M (Muse for Daniel)'
description 'Hub City job applications — apply for HCPD or EMS at the Mission Row front desk. Saves to the database and posts to Discord.'
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
    'ox_target',
    'oxmysql',
}
