M_AC = M_AC or {}
M_AC.Adapter = M_AC.Adapter or {}

function M_AC.Adapter.GetPlayer(src)
    if GetResourceState('tpz_core') ~= 'started' then
        return nil
    end

    local ok, player = pcall(function()
        local api = exports['tpz_core']:getCoreAPI()
        local result = api.GetPlayer(src)
        if not result or not result.loaded() then
            return nil
        end
        return result
    end)

    if not ok then
        return nil
    end
    return player
end

function M_AC.Adapter.GetMoney(src)
    local player = M_AC.Adapter.GetPlayer(src)
    if not player then
        return nil
    end
    local ok, money = pcall(player.getAccount, 0)
    if not ok or not M_AC.Utils.IsFinite(money) then
        return nil
    end
    return money
end

function M_AC.Adapter.GetJob(src)
    local player = M_AC.Adapter.GetPlayer(src)
    if not player then
        return nil
    end
    local ok, job = pcall(player.getJob)
    if not ok then
        return nil
    end
    return job
end
