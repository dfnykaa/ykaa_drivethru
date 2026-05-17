fx_version 'cerulean'
game 'gta5'

author 'ykaa'
description 'Simple Drive Thru'
version '2.0.0'

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