while not Core do
    Wait(100)
end

RegisterCommand('sair', function(src)
    if not src or src == 0 then return end
    if not DoesPlayerExist(src) then return end

    TriggerEvent('kingg:player:leave', src)
end, false)
