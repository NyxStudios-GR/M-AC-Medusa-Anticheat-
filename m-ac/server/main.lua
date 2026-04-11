M_AC = M_AC or {}
M_AC.State = M_AC.State or {}
M_AC.Log = M_AC.Log or {}

local bypass = {}
local logFileName = Config.Logging.jsonFile or 'm-ac.log.jsonl'

function M_AC.State.IsBypassed(source)
    return bypass[source] == true
end

local function canBypass(source)
    local allow = {}
    for _, id in ipairs(Config.AdminIdentifiers or {}) do
        allow[id] = true
    end
    return M_AC.Utils.HasAnyIdentifier(source, allow)
end

function M_AC.Log.Emit(kind, source, reason, severity, context)
    local payload = {
        kind = kind,
        source = source,
        player = GetPlayerName(source) or 'unknown',
        reason = reason,
        severity = severity,
        context = context or {},
        ts = os.time(),
    }

    local line = M_AC.Utils.JsonEncode(payload)

    if Config.Logging.console then
        print(('[M-AC][%s] %s'):format(kind, line))
    end

    SaveResourceFile(GetCurrentResourceName(), logFileName, line .. '\n', -1)

    if Config.Logging.webhook and Config.Logging.webhook ~= '' then
        PerformHttpRequest(Config.Logging.webhook, function() end, 'POST', line, {
            ['Content-Type'] = 'application/json'
        })
    end
end

AddEventHandler('playerConnecting', function(_, _, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)

    for _, identifier in ipairs(M_AC.Utils.GetIdentifiers(src)) do
        if M_AC.Punishment.IsBanned(identifier) then
            deferrals.done('[M-AC] You are banned from this server.')
            return
        end
    end

    bypass[src] = canBypass(src)
    deferrals.done()
end)

RegisterNetEvent('m-ac:server:heartbeat', function(pos, hits)
    local src = source

    if type(pos) == 'table' and pos.x and pos.y and pos.z then
        M_AC.Detection.CheckMovement(src, pos)
    end

    if type(hits) == 'number' then
        M_AC.Detection.CheckCombat(src, hits)
    end

    M_AC.Detection.CheckEconomy(src)
end)

RegisterNetEvent('m-ac:server:protected', function(eventName, sessionToken, payload)
    local src = source
    M_AC.Detection.MarkEvent(src)

    if not M_AC.EventGuard.Validate(src, eventName, sessionToken) then
        return
    end

    -- Place TPZ-sensitive actions here behind EventGuard.
    -- Example payload validation stub:
    if type(payload) ~= 'table' then
        M_AC.Punishment.Evaluate(src, 'Malformed payload on protected event', 15, {
            flag = M_AC.Flags.EVENT_SPOOF,
            event = eventName,
        })
    end
end)

AddEventHandler('rconCommand', function(commandName)
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if src then
            M_AC.Detection.MarkCommand(src)
        end
    end

    if commandName and commandName:lower():find('exec') then
        CancelEvent()
    end
end)

AddEventHandler('entityCreating', function(entity)
    local owner = NetworkGetEntityOwner(entity)
    if owner and owner > 0 then
        M_AC.Detection.MarkEntitySpawn(owner)
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        print(('[M-AC] started v%s'):format(M_AC.VERSION or 'unknown'))
    elseif not Config.TrustedResources[resourceName] and Config.StrictMode then
        print(('[M-AC] untrusted resource started: %s'):format(resourceName))
    end
end)

AddEventHandler('playerDropped', function()
    bypass[source] = nil
end)
