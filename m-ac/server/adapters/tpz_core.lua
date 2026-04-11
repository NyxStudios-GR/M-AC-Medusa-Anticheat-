M_AC = M_AC or {}
M_AC.Adapter = M_AC.Adapter or {}

local TPZ = nil

CreateThread(function()
    while TPZ == nil do
        if exports and exports['tpz_core'] and exports['tpz_core'].getCoreObject then
            TPZ = exports['tpz_core']:getCoreObject()
        end
        Wait(1000)
    end
end)

function M_AC.Adapter.GetPlayer(source)
    if not TPZ or not TPZ.GetPlayer then return nil end
    return TPZ.GetPlayer(source)
end

function M_AC.Adapter.GetMoney(source)
    local player = M_AC.Adapter.GetPlayer(source)
    if not player then return 0 end
    if player.getMoney then
        return tonumber(player.getMoney()) or 0
    end
    return 0
end

function M_AC.Adapter.GetJob(source)
    local player = M_AC.Adapter.GetPlayer(source)
    if not player then return 'unknown' end
    if player.getJob then
        local job = player.getJob()
        if type(job) == 'table' then return job.name or 'unknown' end
        return tostring(job)
    end
    return 'unknown'
end
