M_AC = M_AC or {}
M_AC.Client = M_AC.Client or {}

local hitWindow = {}

local function pruneHits()
    local now = GetGameTimer()
    local kept = {}
    for _, t in ipairs(hitWindow) do
        if now - t <= 5000 then
            kept[#kept + 1] = t
        end
    end
    hitWindow = kept
end

function M_AC.Client.RecordHit()
    hitWindow[#hitWindow + 1] = GetGameTimer()
    pruneHits()
end

function M_AC.Client.HitsInWindow()
    pruneHits()
    return #hitWindow
end

AddEventHandler('gameEventTriggered', function(name, data)
    if name == 'CEventNetworkEntityDamage' then
        if data and data[1] == PlayerPedId() then
            M_AC.Client.RecordHit()
        end
    end
end)
