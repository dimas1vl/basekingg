---@class AdminClient
---@field nuiOpen boolean Whether a focused NUI view (cds/ban) is currently open
Admin = {
    nuiOpen = false,
}

-- Register the RPC response listener (net.admin:res) on the client so awaiting
-- client->server calls (RPC.getPlayers / RPC.getBans) actually resolve.
RPC:bind({})

---Open a focused NUI view.
---@param action 'openCds' | 'openBan' | 'openPanel' | 'openZonePoints'
---@param data? table
function Admin:openNui(action, data)
    self.nuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = action, data = data })
end

---Close the focused NUI view (toasts keep working).
function Admin:closeNui()
    if not self.nuiOpen then return end
    self.nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('close', function(_, cb)
    Admin:closeNui()
    cb({ ok = true })
end)



local isRunning = false
RegisterCommand("pegarcoords", function()
    if isRunning then return end
    isRunning = true
    TriggerServerEvent("admin:change_bucket", 1)
end)

function drawTxt(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end
RegisterNetEvent("create_box", function(coords)
    local obj = CreateObject('prop_box_ammo04a', coords.x, coords.y, coords.z, false, false, false)
    FreezeEntityPosition(obj, true)
    PlaceObjectOnGroundProperly(obj)
    SetEntityHeading(obj, coords.w)
    SetEntityCollision(obj, false, false)
end)

RegisterNetEvent("create_all_box", function(coords)
    for k,v in pairs(GetAllObjects()) do
        DeleteEntity(v)
    end
    for k,v in pairs(coords) do
        local obj = CreateObject('prop_box_ammo04a', v[1], v[2], v[3], false, false, false)
        FreezeEntityPosition(obj, true)
        PlaceObjectOnGroundProperly(obj)
        SetEntityHeading(obj, v[4])
        SetEntityCollision(obj, false, false)
    end
end)

CreateThread(function()
    local count = 0
    while true do
        if isRunning then
            local coords = GetEntityCoords(PlayerPedId())
            local heading = GetEntityHeading(PlayerPedId())
            drawTxt("~g~E~w~ PARA POSICIONAR ("..count..")", 4, 0.10, 0.8, 0.50, 255, 255, 255, 180)
            drawTxt("~r~BACKSPACE~w~ PARA CANCELAR.", 4, 0.10, 0.86, 0.50, 255, 255, 255, 180)
            if IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38) then
                TriggerServerEvent('admin:save_coords', vec4(coords.x, coords.y, coords.z, heading))
                local obj = CreateObject('prop_box_ammo04a', coords.x, coords.y, coords.z, false, false, false)
                FreezeEntityPosition(obj, true)
                PlaceObjectOnGroundProperly(obj)
                SetEntityHeading(obj, heading)
                SetEntityCollision(obj, false, false)
                count = count + 1
            end
            if IsControlJustPressed(0, 177) then
                isRunning = false
                count = 0
            end
            Wait(0)
        else
            Wait(1000)
        end
    end
end)