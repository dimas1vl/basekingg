local gNoclip = false

---@return number dx
---@return number dy
---@return number dz
local function getCamDirection()
    local rot = GetGameplayCamRot(2)
    local radX = rot.x * math.pi / 180.0
    local radZ = rot.z * math.pi / 180.0
    local cosX = math.cos(radX)

    return -math.sin(radZ) * cosX, math.cos(radZ) * cosX, math.sin(radX)
end

local function startNoclip()
    CreateThread(function()
        while gNoclip do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local dx, dy, dz = getCamDirection()
            local speed = 1.0

            DisablePlayerFiring(PlayerId(), true)
            SetEntityVelocity(ped, 0.0001, 0.0001, 0.0001)

            if IsControlPressed(0, 21) then -- shift
                speed = 5.0
            end

            if IsControlPressed(0, 22) then -- space
                speed = 30.0
            end

            if IsControlPressed(0, 19) then -- alt
                speed = 100.0
            end

            if IsControlPressed(0, 210) then -- left ctrl
                speed = 0.2
            end

            if IsControlPressed(1, 32) then -- W
                coords = coords + vector3(dx, dy, dz) * speed
            end

            if IsControlPressed(1, 269) then -- S
                coords = coords - vector3(dx, dy, dz) * speed
            end

            if IsControlPressed(1, 10) then -- page up
                coords = coords + vector3(0.0, 0.0, 1.0)
            end

            if IsControlPressed(1, 11) then -- page down
                coords = coords - vector3(0.0, 0.0, 1.0)
            end

            SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, true, true, true)

            Wait(4)
        end
    end)
end

RegisterNetEvent('admin:noclip:toggle', function()
    gNoclip = not gNoclip

    local ped = PlayerPedId()
    SetEntityVisible(ped, not gNoclip, false)
    SetEntityInvincible(ped, gNoclip)
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, not gNoclip, not gNoclip)

    if gNoclip then
        startNoclip()
    end
end)
