fx_version 'cerulean'
game 'gta5'

author 'ykaa'
description 'Drive Thru script for your FiveM server'
version '2.1.0'

lua54 'yes'

files {
    'locales/cs.lua',
    'locales/en.lua',
    'locales/hu.lua'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    'config/webhook.lua',
    'server/server.lua'
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_iventory'
}
