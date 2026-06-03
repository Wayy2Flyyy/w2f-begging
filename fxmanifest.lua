fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'w2f-begging'
author 'W2F'
version '1.1.0'
description 'Passive homeless begging roleplay — Qbox-first with QBCore and ESX support'

dependency 'ox_lib'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/item_use.lua',
}

server_scripts {
    'server/main.lua',
}
