fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Hub City Roleplay'
description 'Hub City Loans — department vehicle financing for HCPD officers (cadet vehicle loans)'
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
