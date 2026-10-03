local events = {}
local apiExports = {}
local storage = {}
local encoded = {}
local tokens = {}
local drops = 0
local calls = 0
local clock = 1000
local resource = 'tpz_core'
local loaded = false
local failWrite = false
os.time = function()
    return clock
end
json = {
    encode = function(value)
        local key = 'json:' .. tostring(#encoded + 1)
        encoded[#encoded + 1] = value
        encoded[key] = value
        return key
    end,
    decode = function(value)
        return encoded[value]
    end,
}
function GetConvar(_, default)
    return default
end
function GetCurrentResourceName()
    return 'm-ac'
end
function GetInvokingResource()
    return resource
end
function GetResourceState()
    return 'started'
end
function GetGameTimer()
    return clock * 1000
end
function GetPlayerName(src)
    if src == 7 then
        return 'tester'
    end
end
function GetPlayerIdentifiers()
    return { 'license:test', 'ip:127.0.0.1' }
end
function LoadResourceFile(_, path)
    return storage[path]
end
function SaveResourceFile(_, path, value)
    if failWrite then
        return false
    end
    storage[path] = value
    return true
end
function CreateThread() end
function Wait() end
function AddEventHandler(name, callback)
    events[name] = events[name] or {}
    table.insert(events[name], callback)
end
RegisterNetEvent = AddEventHandler
function TriggerClientEvent(name, src, value)
    if name == 'm-ac:client:sessionToken' then
        tokens[src] = value
    end
end
function DropPlayer()
    drops = drops + 1
end
exports = setmetatable({
    tpz_core = {
        getCoreAPI = function()
            return {
                GetPlayer = function()
                    return {
                        loaded = function()
                            return loaded
                        end,
                        getAccount = function(currency)
                            assert(currency == 0)
                            return 42
                        end,
                        getJob = function()
                            return 'sheriff'
                        end,
                    }
                end,
            }
        end,
    },
}, {
    __call = function(_, name, callback)
        apiExports[name] = callback
    end,
})
local function fire(name, ...)
    source = 7
    for _, callback in ipairs(events[name] or {}) do
        callback(...)
    end
end
for _, path in ipairs({
    'config.lua', 'shared/constants.lua', 'shared/utils.lua',
    'server/adapters/tpz_core.lua', 'server/punishment.lua',
    'server/event_guard.lua', 'server/detection_engine.lua', 'server/main.lua',
}) do
    dofile('m-ac/' .. path)
end
Config.Logging.console = false
assert(M_AC.Adapter.GetMoney(7) == nil)
loaded = true
assert(M_AC.Adapter.GetMoney(7) == 42)
assert(M_AC.Adapter.GetJob(7) == 'sheriff')
assert(apiExports.RegisterProtectedAction('test:claim', function(_, payload)
    return payload.allowed == true
end, function(src)
    assert(src == 7)
    calls = calls + 1
end))
resource = 'untrusted'
assert(not apiExports.RegisterProtectedAction('evil', function() end, function() end))
resource = 'tpz_core'
fire('m-ac:server:requestToken')
local token = tokens[7]
assert(token)
assert(not M_AC.EventGuard.Dispatch(7, 'test:claim', 'bad', { allowed = true }))
assert(not M_AC.EventGuard.Dispatch(7, 'unknown', token, {}))
assert(not M_AC.EventGuard.Dispatch(7, 'test:claim', token, 12))
assert(not M_AC.EventGuard.Dispatch(7, 'test:claim', token, { allowed = false }))
assert(M_AC.EventGuard.Dispatch(7, 'test:claim', token, { allowed = true }))
assert(calls == 1)
clock = clock + 6
fire('m-ac:server:requestToken')
assert(tokens[7] == token)
clock = clock + 181
assert(not M_AC.EventGuard.Dispatch(7, 'test:claim', token, { allowed = true }))
assert(tokens[7] ~= token)
assert(M_AC.Punishment.GetScore(7) == 0)
-- Forged heartbeat inputs never reach movement/combat/economy evaluation.
fire('m-ac:server:heartbeat', { x = 'bad', y = 0/0, z = math.huge }, math.huge)
assert(M_AC.Punishment.GetScore(7) == 0)
for _ = 1, 100 do
    fire('m-ac:server:protected', 'test:claim', tokens[7], { allowed = true })
end
assert(calls == 31)
assert(M_AC.Punishment.GetScore(7) == 15)
assert(drops == 0)
assert(events.rconCommand == nil)
M_AC.Log.Emit('test', 7, 'first', 1, {})
local first = storage[Config.Logging.jsonFile]
M_AC.Log.Emit('test', 7, 'second', 1, {})
assert(storage[Config.Logging.jsonFile]:sub(1, #first) == first)
failWrite = true
M_AC.Punishment.Ban(7, 'test', {})
assert(not M_AC.Punishment.IsBanned('license:test'))
assert(drops == 0)
failWrite = false
M_AC.Punishment.Ban(7, 'test', {})
assert(drops == 1)
assert(not M_AC.Punishment.IsBanned('ip:127.0.0.1'))
dofile('m-ac/server/punishment.lua')
assert(M_AC.Punishment.IsBanned('license:test'))
fire('playerDropped')
assert(M_AC.Punishment.GetScore(7) == 0)
assert(not M_AC.EventGuard.Validate(7, 'test:claim', tokens[7]))
print('Runtime regressions passed: TPZ adapter, guard, renewal, ingress, observation, logs, ban persistence, disconnect cleanup')
