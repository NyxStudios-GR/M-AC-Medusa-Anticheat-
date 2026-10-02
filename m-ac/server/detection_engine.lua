M_AC = M_AC or {}
M_AC.Detection = M_AC.Detection or {}

local playerState = {}

local function getProfile(source)
    local profile = Config.DefaultRiskProfile
    local state = playerState[source]
    if state and state.profile then
        profile = state.profile
    end
    return Config.RiskProfiles[profile]
end

local function getState(source)
    if not playerState[source] then
        playerState[source] = {
            profile = Config.DefaultRiskProfile,
            events = {},
            commands = {},
            entities = {},
            lastPos = nil,
            lastPosTs = nil,
            lastMoney = nil,
            lastDamageWindow = {},
        }
    end
    return playerState[source]
end

local function pruneWindow(list, windowSec)
    local now = os.time()
    local nextList = {}
    for _, t in ipairs(list) do
        if now - t <= windowSec then
            nextList[#nextList + 1] = t
        end
    end
    return nextList
end

function M_AC.Detection.MarkEvent(source)
    local state = getState(source)
    local profile = getProfile(source)
    state.events = pruneWindow(state.events, profile.eventWindowSeconds)
    if #state.events < profile.maxEventPerWindow + 1 then
        state.events[#state.events + 1] = os.time()
    end

    if Config.Detectors.eventSpam and #state.events > profile.maxEventPerWindow then
        M_AC.Punishment.Evaluate(source, 'Event flood detected', 15, {
            flag = M_AC.Flags.EVENT_FLOOD,
            count = #state.events,
        })
    end
end

function M_AC.Detection.MarkCommand(source)
    local state = getState(source)
    local profile = getProfile(source)
    state.commands = pruneWindow(state.commands, profile.eventWindowSeconds)
    if #state.commands < profile.maxCommandsPerWindow + 1 then
        state.commands[#state.commands + 1] = os.time()
    end

    if Config.Detectors.commandSpam and #state.commands > profile.maxCommandsPerWindow then
        M_AC.Punishment.Evaluate(source, 'Command flood detected', 15, {
            flag = M_AC.Flags.COMMAND_FLOOD,
            count = #state.commands,
        })
    end
end

function M_AC.Detection.MarkEntitySpawn(source)
    local state = getState(source)
    local profile = getProfile(source)
    state.entities = pruneWindow(state.entities, profile.eventWindowSeconds)
    if #state.entities < profile.maxEntitySpawnPerWindow + 1 then
        state.entities[#state.entities + 1] = os.time()
    end

    if Config.Detectors.entityFlood and #state.entities > profile.maxEntitySpawnPerWindow then
        M_AC.Punishment.Evaluate(source, 'Entity spawn flood detected', 20, {
            flag = M_AC.Flags.ENTITY_FLOOD,
            count = #state.entities,
        })
    end
end

function M_AC.Detection.CheckMovement(source, pos)
    if not Config.Detectors.movement then
        return
    end
    local state = getState(source)
    local profile = getProfile(source)
    local nowMs = GetGameTimer()

    if state.lastPos and state.lastPosTs then
        local dx = pos.x - state.lastPos.x
        local dy = pos.y - state.lastPos.y
        local dz = pos.z - state.lastPos.z
        local dist = math.sqrt(dx * dx + dy * dy + dz * dz)

        local dt = math.max((nowMs - state.lastPosTs) / 1000.0, 0.05)
        local speed = dist / dt

        if dist > profile.maxTeleportDistance then
            M_AC.Punishment.Evaluate(source, 'Teleport anomaly', 20, {
                flag = M_AC.Flags.TELEPORT_ANOMALY,
                distance = dist,
            })
        end

        if speed > profile.maxSpeed then
            M_AC.Punishment.Evaluate(source, 'Speed anomaly', 15, {
                flag = M_AC.Flags.SPEED_ANOMALY,
                speed = speed,
            })
        end
    end

    state.lastPos = pos
    state.lastPosTs = nowMs
end

function M_AC.Detection.CheckEconomy(source)
    if not Config.Detectors.impossibleEconomy then
        return
    end
    local state = getState(source)
    local money = M_AC.Adapter.GetMoney(source)

    if money == nil then
        state.lastMoney = nil
        return
    end

    if state.lastMoney ~= nil then
        local delta = money - state.lastMoney
        if delta > 5000 then
            M_AC.Punishment.Evaluate(source, 'Impossible economy delta', 35, {
                flag = M_AC.Flags.ECONOMY_ANOMALY,
                delta = delta,
                money = money,
            })
        end
    end

    state.lastMoney = money
end

function M_AC.Detection.CheckCombat(source, hitsInLastWindow)
    if not Config.Detectors.combat then
        return
    end
    if hitsInLastWindow > 20 then
        M_AC.Punishment.Evaluate(source, 'Combat anomaly', 20, {
            flag = M_AC.Flags.COMBAT_ANOMALY,
            hits = hitsInLastWindow,
        })
    end
end

AddEventHandler('playerDropped', function()
    playerState[source] = nil
end)
