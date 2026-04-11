local sessionToken = nil

RegisterNetEvent('m-ac:client:sessionToken', function(token)
    sessionToken = token
end)

CreateThread(function()
    Wait(2500)
    TriggerServerEvent('m-ac:server:requestToken')

    while true do
        Wait(3000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        TriggerServerEvent('m-ac:server:heartbeat', {
            x = coords.x,
            y = coords.y,
            z = coords.z,
        }, M_AC.Client.HitsInWindow())
    end
end)

function M_AC_ProtectedTrigger(eventName, payload)
    if not sessionToken then
        TriggerServerEvent('m-ac:server:requestToken')
        return false
    end

    TriggerServerEvent('m-ac:server:protected', eventName, sessionToken, payload or {})
    return true
end

exports('ProtectedTrigger', M_AC_ProtectedTrigger)
