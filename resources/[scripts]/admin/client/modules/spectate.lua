-- Spectate client: enters spectator mode on the target ped (already in the same
-- bucket thanks to the server) and streams the target HP/armor to the spec HUD.

local spec = {
    active = false,
    targetSrc = nil,
    name = nil,
}

local function stopLocal()
    if not spec.active then return end
    spec.active = false

    local ped = PlayerPedId()
    NetworkSetInSpectatorMode(false, ped)
    SetMinimapInSpectatorMode(false, ped)

    spec.targetSrc = nil
    spec.name = nil

    SendNUIMessage({ action = 'specStop' })
end

RegisterNetEvent('admin:spec:start', function(data)
    if type(data) ~= 'table' or not data.targetSrc then return end

    -- Switching target while already spectating.
    if spec.active then
        NetworkSetInSpectatorMode(false, PlayerPedId())
        SetMinimapInSpectatorMode(false, PlayerPedId())
    end

    spec.active = true
    spec.targetSrc = data.targetSrc
    spec.name = data.targetName

    SendNUIMessage({
        action = 'specStart',
        data = { name = data.targetName, userId = data.targetUserId },
    })

    CreateThread(function()
        -- Wait for the target ped to stream in (bucket just changed server-side).
        local playerId = -1
        local deadline = GetGameTimer() + 5000
        repeat
            playerId = GetPlayerFromServerId(spec.targetSrc)
            Wait(100)
        until (playerId ~= -1 and DoesEntityExist(GetPlayerPed(playerId))) or GetGameTimer() > deadline

        if playerId == -1 or not DoesEntityExist(GetPlayerPed(playerId)) then
            TriggerEvent('Notify', 'error', 'Nao foi possivel spectar o jogador.', 5)
            TriggerServerEvent('net.admin:spec:stop')
            stopLocal()
            return
        end

        NetworkSetInSpectatorMode(true, GetPlayerPed(playerId))
        SetMinimapInSpectatorMode(true, GetPlayerPed(playerId))

        while spec.active do
            local pid = GetPlayerFromServerId(spec.targetSrc)
            if pid == -1 then break end

            local tped = GetPlayerPed(pid)
            if DoesEntityExist(tped) then
                local health = GetEntityHealth(tped)
                local maxHealth = GetEntityMaxHealth(tped)
                local armor = GetPedArmour(tped)

                SendNUIMessage({
                    action = 'specUpdate',
                    data = {
                        name = spec.name,
                        health = health,
                        maxHealth = maxHealth,
                        armor = armor,
                    },
                })

                -- Keep camera on the target if it switched peds (respawn).
                NetworkSetInSpectatorMode(true, tped)
            end

            -- Backspace leaves spectate.
            if IsControlJustPressed(0, 177) then
                TriggerServerEvent('net.admin:spec:stop')
                stopLocal()
                break
            end

            Wait(200)
        end
    end)
end)

RegisterNetEvent('admin:spec:stop', function()
    if not spec.active then return end
    TriggerServerEvent('net.admin:spec:stop')
    stopLocal()
end)
