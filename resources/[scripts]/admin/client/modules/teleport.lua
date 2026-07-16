-- Receives a teleport target from the server (already placed in the right bucket).

RegisterNetEvent('admin:teleport', function(coords)
    if type(coords) ~= 'table' or not coords.x then return end

    local ped = PlayerPedId()

    RequestCollisionAtCoord(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    SetEntityCoordsNoOffset(ped, coords.x + 0.0, coords.y + 0.0, coords.z + 0.0, false, false, false)

    -- Wait for the ground/collision around the destination to stream in.
    CreateThread(function()
        local deadline = GetGameTimer() + 3000
        while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < deadline do
            Wait(0)
        end
    end)
end)
