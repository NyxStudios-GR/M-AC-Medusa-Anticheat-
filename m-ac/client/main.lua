local sessionToken = nil

RegisterNetEvent('m-ac:client:sessionToken', function(token)
    sessionToken = token
end)

CreateThread(function()
    Wait(2500)
    TriggerServerEvent('m-ac:server:requestToken')

    while true do
        Wait(3000)
        TriggerServerEvent('m-ac:server:requestToken')
        TriggerServerEvent('m-ac:server:heartbeat')
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
