M_AC = M_AC or {}
M_AC.EventGuard = M_AC.EventGuard or {}

local sessions = {}
local handlers = {}
local requests = {}

-- Tokens bind a session; they do not authorize money/items/jobs.
function M_AC.EventGuard.RefreshToken(src)
    local now = os.time()
    local data = sessions[src]
    if not data or data.expires <= now then
        data = {
            token = ('%s:%s:%s'):format(src, GetGameTimer(), math.random(1, 2147483647)),
            expires = now + Config.EventGuard.tokenTTL,
        }
        sessions[src] = data
    end
    TriggerClientEvent('m-ac:client:sessionToken', src, data.token)
end

function M_AC.EventGuard.Register(name, validator, handler)
    local resource = GetInvokingResource()
    if not resource or not Config.TrustedResources[resource] then
        return false
    end
    if type(name) ~= 'string' or #name > 128 then
        return false
    end
    if type(validator) ~= 'function' or type(handler) ~= 'function' or handlers[name] then
        return false
    end
    handlers[name] = {
        validator = validator,
        handler = handler,
        resource = resource,
    }
    return true
end
exports('RegisterProtectedAction', M_AC.EventGuard.Register)

function M_AC.EventGuard.Validate(src, name, inboundToken)
    if type(name) ~= 'string' or #name > 128 or not handlers[name] then
        return false
    end
    local data = sessions[src]
    if not data or data.expires <= os.time() then
        M_AC.EventGuard.RefreshToken(src)
        return false
    end
    if type(inboundToken) ~= 'string' or data.token ~= inboundToken then
        return false
    end
    return true
end

function M_AC.EventGuard.Dispatch(src, name, inboundToken, payload)
    if not M_AC.EventGuard.Validate(src, name, inboundToken) then
        return false
    end
    if type(payload) ~= 'table' then
        return false
    end
    local action = handlers[name]
    local ok, authorized = pcall(action.validator, src, payload)
    if not ok or authorized ~= true then
        return false
    end
    -- Pass captured source explicitly: never read the event-global source in callbacks.
    local executed, err = pcall(action.handler, src, payload)
    if not executed then
        print(('[M-AC] protected action failed: %s'):format(tostring(err)))
    end
    return executed
end

RegisterNetEvent('m-ac:server:requestToken', function()
    local src = source
    if not GetPlayerName(src) then
        return
    end
    local now = os.time()
    if requests[src] and now - requests[src] < 5 then
        return
    end
    requests[src] = now
    M_AC.EventGuard.RefreshToken(src)
end)

AddEventHandler('playerDropped', function()
    sessions[source] = nil
    requests[source] = nil
end)

AddEventHandler('onResourceStop', function(resource)
    for name, action in pairs(handlers) do
        if action.resource == resource then
            handlers[name] = nil
        end
    end
end)
