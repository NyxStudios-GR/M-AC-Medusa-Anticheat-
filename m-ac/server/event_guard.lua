M_AC = M_AC or {}
M_AC.EventGuard = M_AC.EventGuard or {}

local sessionTokens = {}
local allowedEvents = {}

for _, evt in ipairs(Config.EventGuard.protectedEvents or {}) do
    allowedEvents[evt] = true
end

local function token()
    local chars = 'abcdef0123456789'
    local out = {}
    for i = 1, 40 do
        local index = math.random(1, #chars)
        out[i] = chars:sub(index, index)
    end
    return table.concat(out)
end

function M_AC.EventGuard.RefreshToken(source)
    local t = token()
    sessionTokens[source] = {
        token = t,
        expires = os.time() + (Config.EventGuard.tokenTTL or 120),
    }

    TriggerClientEvent('m-ac:client:sessionToken', source, t)
end

function M_AC.EventGuard.Validate(source, eventName, inboundToken)
    if M_AC.State.IsBypassed(source) then
        return true
    end

    if Config.EventGuard.requireRegistered and not allowedEvents[eventName] then
        M_AC.Punishment.Evaluate(source, 'Unregistered protected event attempt', 30, {
            flag = M_AC.Flags.EVENT_SPOOF,
            event = eventName,
        })
        return false
    end

    local data = sessionTokens[source]
    if not data then
        M_AC.Punishment.Evaluate(source, 'Missing event token', 25, {
            flag = M_AC.Flags.EVENT_SPOOF,
            event = eventName,
        })
        return false
    end

    if data.expires < os.time() then
        M_AC.EventGuard.RefreshToken(source)
        M_AC.Punishment.Evaluate(source, 'Expired event token usage', 20, {
            flag = M_AC.Flags.EVENT_SPOOF,
            event = eventName,
        })
        return false
    end

    if data.token ~= inboundToken then
        M_AC.Punishment.Evaluate(source, 'Invalid event token', 35, {
            flag = M_AC.Flags.EVENT_SPOOF,
            event = eventName,
        })
        return false
    end

    return true
end

AddEventHandler('playerJoining', function(source)
    M_AC.EventGuard.RefreshToken(source)
end)

RegisterNetEvent('m-ac:server:requestToken', function()
    local src = source
    M_AC.EventGuard.RefreshToken(src)
end)
