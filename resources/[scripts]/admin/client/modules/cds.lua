-- Opens the CDS (coordinates) helper, pre-filled with the admin's current position.

RegisterNetEvent('admin:cds:open', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    Admin:openNui('openCds', {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        h = heading,
    })
end)
