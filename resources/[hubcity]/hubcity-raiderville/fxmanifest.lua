fx_version 'cerulean'
game 'gta5'

name 'hubcity-raiderville'
author 'Hub City Roleplay 5M'
description 'Raiderville Stadium — Texas Tech University (the ULSA stadium, Richman) dressed Hub City style: map blip, tent city tailgate camp, flags and event barriers. Plus GAME DAY mode: a busy tailgate layer every other day.'
version '1.2.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua',
    'client_gameday.lua'
}

server_scripts {
    'server_gameday.lua'
}
