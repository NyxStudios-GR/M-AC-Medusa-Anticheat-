M_AC = M_AC or {}
M_AC.Punishment = M_AC.Punishment or {}

local playerRiskScore = {}
local playerBans = {}

local function getName(src)
    return GetPlayerName(src) or ('src:' .. tostring(src))
end

function M_AC.Punishment.GetScore(source)
    return playerRiskScore[source] or 0
end

function M_AC.Punishment.AddScore(source, amount)
    local current = playerRiskScore[source] or 0
    playerRiskScore[source] = current + amount
    return playerRiskScore[source]
end

function M_AC.Punishment.Decay()
    local decay = Config.Punishments.decayPerMinute or 0
    for src, score in pairs(playerRiskScore) do
        playerRiskScore[src] = math.max(score - decay, 0)
    end
end

function M_AC.Punishment.IsBanned(identifier)
    return playerBans[identifier] ~= nil
end

function M_AC.Punishment.Ban(source, reason, context)
    local identifiers = M_AC.Utils.GetIdentifiers(source)
    for _, id in ipairs(identifiers) do
        playerBans[id] = {
            reason = reason,
            context = context,
            ts = os.time(),
        }
    end

    DropPlayer(source, ('[M-AC] Banned: %s'):format(reason))
end

function M_AC.Punishment.Kick(source, reason)
    DropPlayer(source, ('[M-AC] Kicked: %s'):format(reason))
end

function M_AC.Punishment.Warn(source, reason)
    TriggerClientEvent('chat:addMessage', source, {
        args = {'^1M-AC', reason}
    })
end

function M_AC.Punishment.Evaluate(source, reason, scoreGain, context)
    if M_AC.State.IsBypassed(source) then
        return
    end

    local score = M_AC.Punishment.AddScore(source, scoreGain)

    if score >= Config.Punishments.scoreBan then
        M_AC.Log.Emit('punishment', source, reason, M_AC.Severity.CRITICAL, context)
        return M_AC.Punishment.Ban(source, reason, context)
    end

    if score >= Config.Punishments.scoreKick then
        M_AC.Log.Emit('punishment', source, reason, M_AC.Severity.HIGH, context)
        return M_AC.Punishment.Kick(source, reason)
    end

    if score >= Config.Punishments.scoreWarn then
        M_AC.Log.Emit('punishment', source, reason, M_AC.Severity.WARNING, context)
        return M_AC.Punishment.Warn(source, reason)
    end

    M_AC.Log.Emit('score', source, reason, M_AC.Severity.INFO, context)
end

AddEventHandler('playerDropped', function()
    local src = source
    playerRiskScore[src] = nil
end)

CreateThread(function()
    while true do
        Wait(60000)
        M_AC.Punishment.Decay()
    end
end)
