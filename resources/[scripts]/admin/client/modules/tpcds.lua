---@param input string
---@return number | nil, number | nil, number | nil, number | nil
local function parseCoords(input)
    if type(input) ~= 'string' or input == '' then return nil end

    local nums = {}
    for n in input:gmatch('-?%d+%.?%d*') do
        nums[#nums + 1] = tonumber(n)
        if #nums >= 4 then break end
    end

    return nums[1], nums[2], nums[3], nums[4]
end

---@param ped number
---@param x number
---@param y number
---@param z number
---@param h number | nil
local function teleportTo(ped, x, y, z, h)
    DoScreenFadeOut(200)
    local fadeDeadline = GetGameTimer() + 400
    while not IsScreenFadedOut() and GetGameTimer() < fadeDeadline do Wait(0) end

    RequestCollisionAtCoord(x, y, z)
    NewLoadSceneStart(x, y, z, 0.0, 0.0, 0.0, 50.0, 0)
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    if h then SetEntityHeading(ped, h) end

    local collisionDeadline = GetGameTimer() + 5000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < collisionDeadline do
        RequestCollisionAtCoord(x, y, z)
        Wait(50)
    end
    NewLoadSceneStop()

    DoScreenFadeIn(500)
end

RegisterNetEvent('admin:tpcds:open', function()
    Admin:openNui('openTpcds')
end)

RegisterNUICallback('tpcds:teleport', function(data, cb)
    local input = (type(data) == 'table' and data.input) or nil
    local x, y, z, h = parseCoords(input)

    if not (x and y and z) then
        TriggerEvent('Notify', 'error',
            'Formato invalido. Use X Y Z [H] (espaco, virgula, vec3() ou vec4()).', 6)
        cb({ ok = false })
        return
    end

    Admin:closeNui()
    teleportTo(PlayerPedId(), x, y, z, h)

    TriggerEvent('Notify', 'success',
        ('TP -> %.2f, %.2f, %.2f%s'):format(x, y, z, h and (' h=' .. ('%.1f'):format(h)) or ''), 4)
    cb({ ok = true })
end)
