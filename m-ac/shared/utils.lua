M_AC = M_AC or {}
M_AC.Utils = M_AC.Utils or {}

function M_AC.Utils.Now()
    return os.time()
end

function M_AC.Utils.Clamp(v, minV, maxV)
    if v < minV then return minV end
    if v > maxV then return maxV end
    return v
end

function M_AC.Utils.JsonEncode(payload)
    if json and json.encode then
        return json.encode(payload)
    end
    return '{}'
end

function M_AC.Utils.TableLength(t)
    local n = 0
    for _ in pairs(t or {}) do
        n = n + 1
    end
    return n
end

function M_AC.Utils.Contains(list, value)
    for _, v in ipairs(list or {}) do
        if v == value then return true end
    end
    return false
end

function M_AC.Utils.GetIdentifiers(source)
    local out = {}
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        out[#out + 1] = identifier
    end
    return out
end

function M_AC.Utils.HasAnyIdentifier(source, allowList)
    local ids = M_AC.Utils.GetIdentifiers(source)
    for _, id in ipairs(ids) do
        if allowList[id] then
            return true
        end
    end
    return false
end
