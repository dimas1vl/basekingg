local Plane = Game.module('plane')

local cfg = Config.BR.airplane
local cfgPara = Config.BR.parachute

local vehicle = nil
local pilot = nil
local blip = nil

local playerFollowing = false
local playersJumped = {}
local playerInVehicle = false
local flightActive = false
local parachuteActive = false
local hasLanded = false

local zoneMarkerIds = {}
local zoneBlipHandles = {}

local ZONES = {
    { tag = 'ACOUGUE',       sprite = 965,  pos = vec3(922.63, -2181.18, 30.34) },
    { tag = 'AEROPORTO',     sprite = 966,  pos = vec3(-987.95, -2647.37, 13.97) },
    { tag = 'ALIEN',         sprite = 967,  pos = vec3(2480.78, 3762.62, 41.60) },
    { tag = 'AUDITORIO',     sprite = 968,  pos = vec3(683.05, 565.28, 129.05) },
    { tag = 'BARRAGEM',      sprite = 969,  pos = vec3(1665.38, -15.02, 173.77) },
    { tag = 'BLOODS',        sprite = 970,  pos = vec3(-1139.19, -1578.56, 4.39) },
    { tag = 'BORBOLETA',     sprite = 971,  pos = vec3(796.98, -1183.30, 28.18) },
    { tag = 'CENTRAL',       sprite = 972,  pos = vec3(204.51, 197.07, 105.56) },
    { tag = 'CHILIAD',       sprite = 973,  pos = vec3(500.94, 5586.70, 794.10) },
    { tag = 'COLORIDO',      sprite = 974,  pos = vec3(-1220.15, -664.69, 25.90) },
    { tag = 'CRIPS',         sprite = 975,  pos = vec3(1341.53, -1606.85, 52.37) },
    { tag = 'GRAPE',         sprite = 976,  pos = vec3(1981.11, 4915.31, 43.58) },
    { tag = 'GROOVE',        sprite = 977,  pos = vec3(-118.92, -1527.52, 33.99) },
    { tag = 'IGREJA',        sprite = 978,  pos = vec3(-279.86, 2891.10, 45.72) },
    { tag = 'INDUSTRIA',     sprite = 979,  pos = vec3(2865.41, 4370.62, 49.22) },
    { tag = 'JOALHERIA',     sprite = 980,  pos = vec3(-634.65, -243.81, 38.24) },
    { tag = 'JUNINA',        sprite = 981,  pos = vec3(388.10, -343.48, 46.81) },
    { tag = 'LABIRINTO',     sprite = 982,  pos = vec3(-2252.85, 270.04, 174.60) },
    { tag = 'LOJINHA',       sprite = 983,  pos = vec3(1724.47, 6402.70, 34.61) },
    { tag = 'MADEIREIRA',    sprite = 984,  pos = vec3(-529.14, 5338.15, 73.89) },
    { tag = 'MANSOES',       sprite = 985,  pos = vec3(-93.75, 881.03, 236.44) },
    { tag = 'MAZE ARENA',    sprite = 986,  pos = vec3(-265.45, -1898.96, 27.76) },
    { tag = 'MERGULHADOR',   sprite = 987,  pos = vec3(2705.02, 1557.16, 24.52) },
    { tag = 'MINERACAO',     sprite = 1012, pos = vec3(3532.75, 3714.45, 36.05) },
    { tag = 'OBSERVATORIO',  sprite = 988,  pos = vec3(-413.17, 1168.60, 325.85) },
    { tag = 'PALETO',        sprite = 989,  pos = vec3(-137.50, 6325.52, 31.60) },
    { tag = 'PARQUINHO',     sprite = 990,  pos = vec3(-814.04, 866.36, 203.19) },
    { tag = 'PEDREIRA',      sprite = 991,  pos = vec3(2956.12, 2793.95, 40.77) },
    { tag = 'PELADOS',       sprite = 992,  pos = vec3(-1097.37, 4915.87, 215.58) },
    { tag = 'PIER',          sprite = 993,  pos = vec3(-1640.98, -1040.30, 13.15) },
    { tag = 'PIMENTAS',      sprite = 994,  pos = vec3(-637.86, -654.44, 35.00) },
    { tag = 'PLAYBOY',       sprite = 995,  pos = vec3(-1505.91, 139.02, 55.65) },
    { tag = 'PORTO',         sprite = 996,  pos = vec3(710.50, -2790.73, 6.38) },
    { tag = 'PRACA',         sprite = 997,  pos = vec3(201.90, -929.80, 30.71) },
    { tag = 'PRESIDIO',      sprite = 998,  pos = vec3(1707.95, 2606.01, 45.53) },
    { tag = 'RALLY',         sprite = 999,  pos = vec3(1017.15, 2361.57, 51.41) },
    { tag = 'ROTA 68',       sprite = 1000, pos = vec3(1205.45, 2687.94, 37.71) },
    { tag = 'COMERCIO',      sprite = 1001, pos = vec3(1125.88, -538.72, 62.43) },
    { tag = 'SANDY SHORES',  sprite = 1002, pos = vec3(479.01, 3024.33, 40.81) },
    { tag = 'SHOPING',       sprite = 1003, pos = vec3(-168.28, -195.54, 43.79) },
    { tag = 'TEQUILA-LA',    sprite = 1004, pos = vec3(-539.08, 254.95, 83.06) },
    { tag = 'TREVOR',        sprite = 1005, pos = vec3(1771.18, 3275.34, 41.48) },
    { tag = 'TRINCHEIRA',    sprite = 1006, pos = vec3(1808.24, 3790.36, 33.61) },
    { tag = 'VAGOS',         sprite = 1007, pos = vec3(335.68, -2041.65, 21.08) },
    { tag = 'CANAIS',        sprite = 1008, pos = vec3(-1032.08, -1071.42, 4.05) },
    { tag = 'VIDRO',         sprite = 1009, pos = vec3(-2000.10, -316.16, 48.09) },
    { tag = 'VINHEDO',       sprite = 1010, pos = vec3(-1911.89, 2029.77, 140.74) },
    { tag = 'ZANCUDO',       sprite = 1011, pos = vec3(-2039.87, 2999.22, 32.81) },
}

---@param state boolean
local function setPlayersInvisible(state)

    local ped = PlayerPedId()

    for _, pid in ipairs(GetActivePlayers()) do

        local otherPed = GetPlayerPed(pid)
        local coords = GetEntityCoords(otherPed)

        if otherPed ~= ped and (not state or coords.z >= 700.0) then

            if state then
                SetEntityLocallyInvisible(otherPed)
            else
                SetEntityLocallyVisible(otherPed)
            end

            SetEntityNoCollisionEntity(otherPed, ped, true)
        end
    end
end

---@return number
local function getPlayersInAirplane()

    local amount = 0

    for _, pid in ipairs(GetActivePlayers()) do

        local coords = GetEntityCoords(GetPlayerPed(pid))

        if coords.z > 790.0 and coords.z < 810.0 then
            amount = amount + 1
        end
    end

    return amount
end

local function removeZoneMarkers()

    for _, id in ipairs(zoneMarkerIds) do
        exports['waypoint']:remove(id)
    end

    zoneMarkerIds = {}

    for _, b in ipairs(zoneBlipHandles) do

        if DoesBlipExist(b) then
            RemoveBlip(b)
        end
    end

    zoneBlipHandles = {}
end

local function createZoneMarkers()

    removeZoneMarkers()

    for _, zone in ipairs(ZONES) do

        if isCoordsSafezone(zone.pos.x, zone.pos.y) then
            local _, gz = GetGroundZFor_3dCoord(zone.pos.x, zone.pos.y, zone.pos.z, false)

            local id = exports['waypoint']:create({
                type = 'checkpoint',
                coords = vec3(zone.pos.x, zone.pos.y, gz or zone.pos.z),
                label = zone.tag,
                color = '#ffffff',
                displayDistance = false,
                drawDistance = 15000.0,
                size = 1.5,
                groundZ = gz or zone.pos.z,
                labelZ = 400.0,
            })

            zoneMarkerIds[#zoneMarkerIds + 1] = id

            local b = AddBlipForCoord(zone.pos.x, zone.pos.y, zone.pos.z)
            SetBlipSprite(b, zone.sprite)
            SetBlipDisplay(b, 2)
            SetBlipScale(b, 0.50)
            SetBlipAsShortRange(b, true)
            SetBlipHiddenOnLegend(b, true)
            SetBlipHighDetail(b, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(zone.tag)
            EndTextCommandSetBlipName(b)

            zoneBlipHandles[#zoneBlipHandles + 1] = b
        end
    end
end

local function hideMeters()

    Game.ui.send('hud:meters', {
        visible = false,
        distance = 0,
        distanceLabel = '',
        vehicleSpeed = 0,
        altitude = 0,
        heading = 0,
    })
end

---@param ped number
---@return number
local function heightAboveGround(ped)

    local coords = GetEntityCoords(ped)
    local _, gz = GetGroundZExcludingObjectsFor_3dCoord(coords.x, coords.y, coords.z, true)

    return coords.z - gz
end

---@param ped number
local function forceEjectPed(ped)

    local coords = GetEntityCoords(ped)
    ClearPedTasksImmediately(ped)
    SetEntityCoords(ped, coords.x, coords.y, coords.z)
end

local function cleanup()

    flightActive = false
    playerInVehicle = false
    parachuteActive = false
    hasLanded = true

    if vehicle and DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
    if pilot and DoesEntityExist(pilot) then DeleteEntity(pilot) end
    if blip and DoesBlipExist(blip) then RemoveBlip(blip) end

    vehicle = nil
    pilot = nil
    blip = nil

    SetEntityInvincible(PlayerPedId(), false)
    removeZoneMarkers()
    ClearGpsCustomRoute()
    SetCloudsAlpha(1.0)

    Game.ui.send('hud:interaction', { visible = false, key = '', action = '', detail = '', detailValue = '' })
    hideMeters()
end

local function startParachuteTracking()

    if parachuteActive then return end

    parachuteActive = true
    hasLanded = false
    SetPlayerParachuteSmokeTrailColor(PlayerId(), math.random(0, 255), math.random(0, 255), math.random(0, 255))
    SetPlayerCanLeaveParachuteSmokeTrail(PlayerId(), true)
    CreateThread(function()

        local chuteHash = GetHashKey('GADGET_PARACHUTE')

        while parachuteActive do

            local ped = PlayerPedId()
            local paraState = GetPedParachuteState(ped)
            local inFreeFall = IsPedInParachuteFreeFall(ped)
            local falling = IsPedFalling(ped)

            if not inFreeFall and not falling and paraState == -1 and hasLanded then
                parachuteActive = false
                hideMeters()
                break
            end

            local height = heightAboveGround(ped)

            DisableControlAction(0, 145, height > cfgPara.forceOpenMin and height < cfgPara.autoOpenHeight)

            if inFreeFall or falling or (paraState >= 0 and paraState <= 2) then

                local speed = math.floor(GetEntitySpeed(ped))

                if not hasLanded and height <= cfgPara.groundSnap then
                    local coords = GetEntityCoords(ped)
                    local _, gz = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)

                    ClearPedTasksImmediately(ped)
                    SetEntityCoords(ped, coords.x, coords.y, gz)

                    hasLanded = true
                    parachuteActive = false
                    SetEntityInvincible(ped, false)
                    SetCloudsAlpha(1.0)
                    RemoveAllPedWeapons(ped)
                    removeZoneMarkers()
                    ClearGpsCustomRoute()
                    Game.session:send('airplane.landed')
                    hideMeters()
                    SetPedCanRagdoll(ped, true)
                    break
                end

                if not hasLanded and not HasPedGotWeapon(ped, chuteHash, false) then
                    GiveWeaponToPed(ped, chuteHash, 1, false, true)
                end

                if not hasLanded and height <= cfgPara.autoOpenHeight and height >= cfgPara.forceOpenMin then
                    print("auto open", height, inFreeFall)
                    if inFreeFall then
                        ForcePedToOpenParachute(ped)
                    end
                end

                for _, pid in ipairs(GetActivePlayers()) do

                    local otherPed = GetPlayerPed(pid)

                    if otherPed ~= ped then
                        SetEntityNoCollisionEntity(otherPed, ped, true)
                        SetEntityNoCollisionEntity(ped, otherPed, true)
                    end
                end

                Game.ui.send('hud:meters', {
                    visible = true,
                    distance = math.floor(height),
                    distanceLabel = 'CHAO',
                    vehicleSpeed = speed,
                    altitude = math.floor(height),
                    heading = math.floor(GetEntityHeading(ped)),
                })

                if not hasLanded and (inFreeFall and not HasEntityCollidedWithAnything(ped)) then
                    ApplyForceToEntity(ped, true, 0.0, 33.0, 3.0, 0.0, 0.0, 0.0, false, true, false, false, false, true)
                end

                Wait(0)
            else
                hideMeters()
                Wait(250)
            end
        end
    end)
end

-- follow system

local cooldownFollow = 0

---@param id number | false
local function setPlayerFollowing(id)

    if not id then
        playerFollowing = false
        Game.ui.send('hud:interaction', { visible = false, key = '', action = '', detail = '', detailValue = '' })
        return
    end

    playerFollowing = id

    local playerIdx = GetPlayerFromServerId(id)
    local name = (Game.session.names and Game.session.names[id]) or ((playerIdx ~= -1) and GetPlayerName(playerIdx)) or tostring(id)

    Game.ui.send('hud:interaction', {
        visible = true,
        key = '',
        action = ('SEGUINDO %s'):format(name),
        detail = '',
        detailValue = '',
    })
end

---@param value number
local function swapFollowPlayer(value)

    local phase = Game.session:currentPhase()

    if phase ~= MatchState.STARTED and phase ~= MatchState.AIRPLANE then return end

    local mySrc = GetPlayerServerId(PlayerId())

    if phase == MatchState.STARTED and playersJumped[mySrc] then return end

    local now = GetGameTimer()

    if now - cooldownFollow < 250 then return end

    cooldownFollow = now

    if value == 0 then
        setPlayerFollowing(false)
        return
    end

    local squad = Game.session.squad
    local available = {}

    for _, src in ipairs(squad) do

        if src ~= mySrc and not playersJumped[src] then
            available[#available + 1] = src
        end
    end

    if #available == 0 then
        setPlayerFollowing(false)
        return
    end

    if not playerFollowing then
        setPlayerFollowing(available[1])
        return
    end

    local currentIdx = 0

    for i, src in ipairs(available) do

        if src == playerFollowing then
            currentIdx = i
            break
        end
    end

    local nextIdx = currentIdx + value

    if nextIdx < 1 then
        nextIdx = #available
    elseif nextIdx > #available then
        nextIdx = 1
    end

    setPlayerFollowing(available[nextIdx])
end

RegisterCommand('royale:next.follow', function()
    swapFollowPlayer(1)
end)

RegisterCommand('royale:after.follow', function()
    swapFollowPlayer(-1)
end)

RegisterCommand('royale:toogle.follow', function()
    swapFollowPlayer(playerFollowing and 0 or 1)
end)

-- net events

Game.session:onNet('airplane.playerJumped', function(id)

    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    playersJumped[id] = true

    local mySrc = GetPlayerServerId(PlayerId())

    if id ~= playerFollowing or playersJumped[mySrc] then return end

    forceEjectPed(ped)
    SetPedCanRagdoll(ped, false)
end)

Game.session:onNet('airplane.start', function(from, to)

    playerFollowing = false
    playersJumped = {}
    flightActive = true
    playerInVehicle = true

    if not Game.requestAsset(cfg.model) or not Game.requestAsset(cfg.pilotModel) then
        flightActive = false
        return
    end

    local ped = PlayerPedId()

    SetEntityCoords(ped, from.x, from.y, cfg.altitude - 5.0)

    local heading = GetHeadingFromVector_2d(to.x - from.x, to.y - from.y)

    vehicle = CreateVehicle(GetHashKey(cfg.model), from.x, from.y, cfg.altitude, heading, false, false)

    while not DoesEntityExist(vehicle) do
        Wait(100)
    end

    SetEntityInvincible(vehicle, true)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleForwardSpeed(vehicle, cfg.speed)
    SetHeliBladesSpeed(vehicle, 100.0)
    SetEntityCollision(vehicle, false, true)
    SetEntityHeading(vehicle, heading)
    FreezeEntityPosition(vehicle, true)
    SetVehicleLandingGear(vehicle, 1)
    ControlLandingGear(vehicle, 0)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetCloudsAlpha(0.0)

    pilot = CreatePedInsideVehicle(vehicle, 26, GetHashKey(cfg.pilotModel), -1, false, true)

    while not DoesEntityExist(pilot) do
        Wait(100)
    end

    SetBlockingOfNonTemporaryEvents(pilot, true)

    blip = AddBlipForEntity(vehicle)
    SetBlipSprite(blip, cfg.blip.sprite)
    SetBlipDisplay(blip, cfg.blip.display)
    SetBlipScale(blip, cfg.blip.scale)
    SetBlipRotation(blip, math.floor(heading))

    ClearGpsCustomRoute()
    StartGpsMultiRoute(0, true, false)
    AddPointToGpsCustomRoute(to.x, to.y, to.z)
    AddPointToGpsCustomRoute(from.x, from.y, from.z)
    SetGpsCustomRouteRender(true, 25, 70)

    createZoneMarkers()

    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, true)
    SetPedIntoVehicle(ped, vehicle, 1)
    FreezeEntityPosition(vehicle, false)

    local capturedVeh = vehicle

    CreateThread(function()

        while flightActive and capturedVeh and DoesEntityExist(capturedVeh) do

            ped = PlayerPedId()

            local coords = GetEntityCoords(ped)
            local inVehicle = GetVehiclePedIsIn(ped, false) == capturedVeh
            local vehicleCoords = GetEntityCoords(capturedVeh)
            local distance = #(vector3(to.x, to.y, cfg.altitude) - vehicleCoords)

            GiveWeaponToPed(ped, GetHashKey('GADGET_PARACHUTE'), 1, false, true)

            if playerInVehicle and not inVehicle then

                playerInVehicle = false

                Game.session:send('airplane.jumped')
                Game.session:send('airplane.leaderJump', GetEntityHeading(ped))
                setPlayerFollowing(false)
                startParachuteTracking()
            end

            if inVehicle then

                EnableControlAction(0, 75, true)
                DisableControlAction(0, 140, true)
                DisableControlAction(0, 141, true)
                DisableControlAction(0, 142, true)

                if distance <= cfg.autoEjectDistance then
                    forceEjectPed(ped)
                end

                local n = getPlayersInAirplane()

                Game.ui.send('hud:interaction', {
                    visible = true,
                    key = 'F',
                    action = 'PULAR',
                    detail = '',
                    detailValue = ('%d no aviao'):format(n),
                })
            else
                Game.ui.send('hud:interaction', { visible = false, key = '', action = '', detail = '', detailValue = '' })
            end

            setPlayersInvisible(coords.z > 700.0)

            SetHeliBladesFullSpeed(capturedVeh)
            SetEntityRotation(capturedVeh, 0.0, 0.0, GetEntityHeading(capturedVeh), 2, true)
            SetVehicleForwardSpeed(capturedVeh, cfg.speed)

            Wait(0)
        end
    end)
end)


Game.session:listen('phaseChange', function(newState)

    if newState ~= MatchState.STARTED then return end

    local ped = PlayerPedId()

    if IsPedInParachuteFreeFall(ped) or IsPedFalling(ped) then
        startParachuteTracking()
    end
end)


Game.session:onNet('airplane.eject', function()
    print('airplane.eject')
    forceEjectPed(PlayerPedId())
end)

Game.session:onNet('airplane.leaderJumped', function(srcLeader, heading)

    if not playerFollowing then return end
    if not playerInVehicle then return end
    if srcLeader == GetPlayerServerId(PlayerId()) then return end

    Wait(500)

    if not vehicle or not DoesEntityExist(vehicle) then return end

    local ped = PlayerPedId()

    playerInVehicle = false

    Game.ui.send('hud:interaction', { visible = false, key = '', action = '', detail = '', detailValue = '' })
    forceEjectPed(ped)

    Wait(100)

    SetEntityHeading(PlayerPedId(), heading or 0.0)
    SetGameplayCamRelativeHeading(0.0)
end)


Game.session:listen('ended', function()

    playerFollowing = false
    playersJumped = {}
    cleanup()
end)
