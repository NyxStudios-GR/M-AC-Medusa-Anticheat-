Config = {}

Config.Debug = false
Config.StrictMode = true

Config.RiskProfiles = {
    low = {
        maxEventPerWindow = 22,
        eventWindowSeconds = 10,
        maxCommandsPerWindow = 8,
        maxEntitySpawnPerWindow = 14,
        maxSpeed = 12.5,
        maxTeleportDistance = 130.0,
    },
    medium = {
        maxEventPerWindow = 18,
        eventWindowSeconds = 10,
        maxCommandsPerWindow = 6,
        maxEntitySpawnPerWindow = 10,
        maxSpeed = 11.0,
        maxTeleportDistance = 95.0,
    },
    high = {
        maxEventPerWindow = 14,
        eventWindowSeconds = 10,
        maxCommandsPerWindow = 4,
        maxEntitySpawnPerWindow = 7,
        maxSpeed = 9.5,
        maxTeleportDistance = 70.0,
    }
}

Config.DefaultRiskProfile = 'medium'

Config.AdminIdentifiers = {
    -- "license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
}

Config.TrustedResources = {
    ['tpz_core'] = true,
    ['m-ac'] = true,
}

Config.EventGuard = {
    tokenTTL = 180,
    requireRegistered = true,
    protectedEvents = {
        'tpz_core:server:addMoney',
        'tpz_core:server:removeMoney',
        'tpz_core:server:addItem',
        'tpz_core:server:removeItem',
        'tpz_core:server:setJob',
    }
}

Config.Punishments = {
    scoreWarn = 35,
    scoreKick = 70,
    scoreBan = 100,
    decayPerMinute = 4,
}

Config.Logging = {
    console = true,
    jsonFile = 'm-ac.log.jsonl',
    webhook = '', -- optional Discord webhook
}

Config.Detectors = {
    movement = true,
    combat = true,
    eventSpam = true,
    commandSpam = true,
    entityFlood = true,
    impossibleEconomy = true,
}
