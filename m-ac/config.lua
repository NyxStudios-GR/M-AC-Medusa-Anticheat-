Config = {}

Config.Debug = false
Config.StrictMode = false
Config.ObserveOnly = true

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
    protectedEvents = {} -- Registered server callbacks define the allowlist.
}

Config.Punishments = {
    scoreWarn = 35,
    scoreKick = 70,
    scoreBan = 100,
    decayPerMinute = 4,
    evidenceCooldown = 10,
    banFile = 'm-ac.bans.json',
}

Config.Logging = {
    console = true,
    jsonFile = 'm-ac.log.jsonl',
    maxBytes = 1048576,
    webhook = GetConvar('m_ac_webhook', ''), -- Server-only secret
}

Config.Detectors = {
    movement = false, -- Enable only after tuning horses, wagons and teleports.
    combat = false, -- Client damage probes are not authoritative.
    eventSpam = true,
    commandSpam = true,
    entityFlood = true,
    impossibleEconomy = false, -- Legitimate payouts need transaction integration.
}
