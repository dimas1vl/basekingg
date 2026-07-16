while not GM do Wait(0) end

local VANT_RADIUS = 200.0

GM:registerNetEvent('vant.use', function(match, src)

    local userPed = GetPlayerPed(src)

    if not DoesEntityExist(userPed) then return end

    local userCoords = GetEntityCoords(userPed)
    local positions = {}

    for i = 1, #match.playerList do

        local targetSrc = match.playerList[i]

        if targetSrc == src then goto continue end

        local targetSquad = match.playerSquad[targetSrc]
        local srcSquad = match.playerSquad[src]

        if targetSquad == srcSquad then goto continue end

        local targetPed = GetPlayerPed(targetSrc)

        if not DoesEntityExist(targetPed) then goto continue end

        local targetCoords = GetEntityCoords(targetPed)
        local dist = #(vector2(userCoords.x, userCoords.y) - vector2(targetCoords.x, targetCoords.y))

        if dist <= VANT_RADIUS then

            positions[#positions + 1] = {
                x = targetCoords.x,
                y = targetCoords.y,
                z = targetCoords.z,
            }
        end

        ::continue::
    end

    local squadIndex = match.playerSquad[src]
    local targets = squadIndex and match.squads[squadIndex] and match.squads[squadIndex].players or { src }
    local eventName = ('net.%s:vant.result'):format(GetCurrentResourceName())

    for i = 1, #targets do
        local target = targets[i]
        if match:getPlayerState(target) == PlayerState.ALIVE then
            TriggerClientEvent(eventName, target, positions, VANT_RADIUS)
        end
    end

    log('info', ('match %d: vant used by src=%d, found %d enemies (squad-wide)'):format(match.id, src, #positions))
end)
