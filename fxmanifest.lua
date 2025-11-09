fx_version 'cerulean'
game 'gta5'

author 'LB Scripts'
description 'Modern QB-Core Multicharacter System'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

files {
    'html/index.html',
    'html/assets/**/*'
}

dependencies {
    'qb-core',
    'oxmysql'
}

lua54 'yes'
