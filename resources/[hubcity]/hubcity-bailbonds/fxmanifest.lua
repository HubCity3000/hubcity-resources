fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Hub City Roleplay 5M (Muse for Daniel)'
description 'Hub City Bail Bonds — bail bonds office + bounty hunter gameplay (starter skeleton, Qbox port)'
version '0.1.0'

shared_scripts {
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
    'oxmysql',
}
