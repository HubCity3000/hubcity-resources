fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Hub City Roleplay 5M (Muse for Daniel)'
description 'Hub City Crafting — players craft their own backpacks at workbenches (Home Ground, Sandy Shores, the Depot District). Server-validated materials, ox_inventory container backpacks in three tiers.'
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
    'ox_inventory',
    'ox_target',
}
