M_AC = M_AC or {}
M_AC.Punishment = M_AC.Punishment or {}

local playerRiskScore = {}
local playerBans = {}
local evidence = {}
local banFile = Config.Punishments.banFile
local saved = LoadResourceFile(GetCurrentResourceName(), banFile)
if saved then
    local ok, decoded = pcall(json.decode, saved)
    if not ok or type(decoded) ~= 'table' then
        error('[M-AC] Invalid ban file; restore it before starting')
    end
    playerBans = decoded
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
    local nextBans = {}
    for id, record in pairs(playerBans) do
        nextBans[id] = record
    end
    local identifiers = M_AC.Utils.GetIdentifiers(source)
    local count = 0
    for _, id in ipairs(identifiers) do
        if id:match('^license:') or id:match('^license2:') or id:match('^steam:') then
            nextBans[id] = {
                reason = reason,
                ts = os.time(),
            }
            count = count + 1
        end
    end
    if count == 0 then
        print('[M-AC] ban refused: no stable identifier')
        return
    end
    if not SaveResourceFile(GetCurrentResourceName(), banFile, json.encode(nextBans), -1) then
        print('[M-AC] ban persistence failed; player was not banned')
        return
    end
    playerBans = nextBans

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

    if not GetPlayerName(source) then
        return
    end
    evidence[source] = evidence[source] or {}
    local key = context and context.flag or reason
    local now = os.time()
    if evidence[source][key] and now - evidence[source][key] < Config.Punishments.evidenceCooldown then
        return
    end
    evidence[source][key] = now
    local score = M_AC.Punishment.AddScore(source, scoreGain)
    if Config.ObserveOnly then
        M_AC.Log.Emit('observation', source, reason, M_AC.Severity.INFO, context)
        return
    end

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
    evidence[src] = nil
end)

CreateThread(function()
    while true do
        Wait(60000)
        M_AC.Punishment.Decay()
    end
end)
