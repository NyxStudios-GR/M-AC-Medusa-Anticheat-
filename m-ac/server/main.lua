M_AC = M_AC or {}
M_AC.State = M_AC.State or {}
M_AC.Log = M_AC.Log or {}

local logFileName = Config.Logging.jsonFile or 'm-ac.log.jsonl'

function M_AC.State.IsBypassed(src)
    local allow = {}
    for _, id in ipairs(Config.AdminIdentifiers or {}) do
        allow[id] = true
    end
    return M_AC.Utils.HasAnyIdentifier(src, allow)
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

    local existing = LoadResourceFile(GetCurrentResourceName(), logFileName) or ''
    if #existing + #line > Config.Logging.maxBytes then
        if not SaveResourceFile(GetCurrentResourceName(), logFileName .. '.1', existing, -1) then
            print('[M-AC] log rotation failed')
        end
        existing = ''
    end
    if not SaveResourceFile(GetCurrentResourceName(), logFileName, existing .. line .. '\n', -1) then
        print('[M-AC] log write failed')
    end

    if Config.Logging.webhook and Config.Logging.webhook ~= '' then
        local body = M_AC.Utils.JsonEncode({
            content = line:sub(1, 1900),
            allowed_mentions = {
                parse = {},
            },
        })
        PerformHttpRequest(Config.Logging.webhook, function()
        end, 'POST', body, {
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

    deferrals.done()
end)

local ingress = {}

local function admit(src, channel, limit)
    if not GetPlayerName(src) then
        return false
    end
    ingress[src] = ingress[src] or {}
    local window = ingress[src][channel]
    local now = os.time()
    if not window or now - window.started >= 10 then
        window = {
            started = now,
            count = 0,
        }
        ingress[src][channel] = window
    end
    if window.count >= limit then
        return false
    end
    window.count = window.count + 1
    return true
end

RegisterNetEvent('m-ac:server:heartbeat', function()
    -- Liveness only. Client coordinates and hit counts are attacker controlled.
    admit(source, 'heartbeat', 5)
end)

RegisterNetEvent('m-ac:server:protected', function(eventName, sessionToken, payload)
    local src = source
    if not admit(src, 'protected', 30) then
        return
    end
    M_AC.Detection.MarkEvent(src)
    M_AC.EventGuard.Dispatch(src, eventName, sessionToken, payload)
end)

-- Command owners must call this from their own server command callback.
exports('MarkCommand', function(src)
    local resource = GetInvokingResource()
    if resource and Config.TrustedResources[resource] and GetPlayerName(src) then
        M_AC.Detection.MarkCommand(src)
    end
end)

CreateThread(function()
    while true do
        Wait(3000)
        for _, id in ipairs(GetPlayers()) do
            local src = tonumber(id)
            if src and M_AC.Adapter.GetPlayer(src) then
                M_AC.Detection.CheckEconomy(src)
                if Config.Detectors.movement then
                    local ped = GetPlayerPed(src)
                    if ped and ped ~= 0 and DoesEntityExist(ped) then
                        local pos = GetEntityCoords(ped)
                        if M_AC.Utils.IsFinite(pos.x) and M_AC.Utils.IsFinite(pos.y) and M_AC.Utils.IsFinite(pos.z) then
                            M_AC.Detection.CheckMovement(src, pos)
                        end
                    end
                end
            end
        end
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
    ingress[source] = nil
end)
