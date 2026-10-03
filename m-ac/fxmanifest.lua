fx_version 'cerulean'
game 'rdr3'

name 'm-ac'
author 'Medusa Security Team'
description 'M-AC (Medusa Anticheat) for TPZ Core RedM'
version '1.0.0'

lua54 'yes'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
dependency 'tpz_core'

shared_scripts {
    'shared/constants.lua',
    'shared/utils.lua'
}

server_scripts {
    'config.lua',
    'server/adapters/tpz_core.lua',
    'server/punishment.lua',
    'server/event_guard.lua',
    'server/detection_engine.lua',
    'server/main.lua'
}

client_scripts {
    'client/probes.lua',
    'client/main.lua'
}
