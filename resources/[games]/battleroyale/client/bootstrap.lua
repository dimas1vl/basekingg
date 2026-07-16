local gWeatherActive = false

Game.session:listen('joined', function(matchId, state, squadIndex)

    exports['lobby']:closeLobby()
    DisplayRadar(true)
    Game.ui.send('show', true)

    gWeatherActive = true

    CreateThread(function()

        while gWeatherActive do
            SetWeatherTypeNow('CLEAR')
            SetWeatherTypePersist('CLEAR')
            SetWeatherTypeNowPersist('CLEAR')
            NetworkOverrideClockTime(12, 0, 0)
            Wait(5000)
        end
    end)
end)

Game.session:listen('ended', function()

    gWeatherActive = false

    DisplayRadar(false)
    Game.ui.send('close', true)

    local ped = PlayerPedId()

    if IsEntityDead(ped) then
        local pos = GetEntityCoords(ped)
        NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, GetEntityHeading(ped), true, false)
        ped = PlayerPedId()
    end

    ClearPedTasks(ped)
    ClearPedBloodDamage(ped)
    RemoveAllPedWeapons(ped, true)
    SetEntityInvincible(ped, false)
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true)
    SetPlayerInvincible(PlayerId(), false)
    NetworkOverrideClockTime(12, 0, 0)
end)

Game.session:onNet('debug.hurt', function()
    SetEntityHealth(PlayerPedId(), 101)
end)

Game.session:onNet('debug.damage', function()
    local ped = PlayerPedId()
    ApplyDamageToPed(ped, 10, false)
end)
