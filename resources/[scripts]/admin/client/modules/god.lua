-- God mode: max health/armor + invincibility while enabled.

local godEnabled = false

RegisterNetEvent('admin:god', function(state)
    godEnabled = state == true

    local ped = PlayerPedId()
    SetEntityInvincible(ped, godEnabled)
    SetPlayerInvincible(PlayerId(), godEnabled)

    if not godEnabled then
        return
    end

    local maxHealth = GetEntityMaxHealth(ped)
    SetEntityHealth(ped, maxHealth)
    SetPedArmour(ped, 100)

    -- Keep health/armor topped up while god mode is on.
    CreateThread(function()
        while godEnabled do
            local p = PlayerPedId()
            local mh = GetEntityMaxHealth(p)
            if GetEntityHealth(p) < mh then
                SetEntityHealth(p, mh)
            end
            if GetPedArmour(p) < 100 then
                SetPedArmour(p, 100)
            end
            Wait(500)
        end
    end)
end)
