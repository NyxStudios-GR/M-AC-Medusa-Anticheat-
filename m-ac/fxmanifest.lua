fx_version 'cerulean'
game 'rdr3'

name 'm-ac'
author 'Medusa Security Team'
description 'M-AC (Medusa Anticheat) for TPZ Core RedM'
version '1.0.0'

lua54 'yes'

shared_scripts {
    'config.lua',
    'shared/constants.lua',
    'shared/utils.lua'
}

server_scripts {
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
