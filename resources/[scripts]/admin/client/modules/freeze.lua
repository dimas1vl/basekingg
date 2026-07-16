-- Freeze toggle. Server keeps the authoritative state and tells the target client
-- whether it should be frozen or not.

local frozen = false

RegisterNetEvent('admin:freeze', function(state)
    frozen = state == true

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, frozen)

    if not frozen then return end

    -- Keep the freeze enforced (it can be cleared by respawns / vehicle changes).
    CreateThread(function()
        while frozen do
            local p = PlayerPedId()
            if not IsEntityPositionFrozen(p) then
                FreezeEntityPosition(p, true)
            end
            Wait(500)
        end
    end)
end)
