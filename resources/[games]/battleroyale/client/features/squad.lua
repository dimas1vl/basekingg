local Squad = Game.module('squad')

local cfgPing = Config.BR.ping
local NAMETAG_BONE = Config.BR.bones.head

local PING_COOLDOWN = Config.ping.cooldown
local MARKER_DURATION = Config.ping.markerDuration
local PING_EXPIRE = 12000
local PING_TEXTURE = cfgPing.texture
local PING_SPRITE_ENEMY = cfgPing.spriteEnemy

---@type table<number, { blipColor: number, blipSprite: number, textCode: string, rgb: number[], sprite: string }>
local eSquadConfig = {
    { blipColor = 57, blipSprite = 960, textCode = '~b~', rgb = {   0, 150, 255 }, sprite = 'azul'     },
    { blipColor = 36, blipSprite = 961, textCode = '~o~', rgb = { 255, 140,   0 }, sprite = 'laranja'  },
    { blipColor =  7, blipSprite = 962, textCode = '~p~', rgb = { 180,   0, 255 }, sprite = 'roxo'     },
    { blipColor =  2, blipSprite = 963, textCode = '~g~', rgb = {  50, 255,  50 }, sprite = 'verde'    },
    { blipColor =  1, blipSprite = 964, textCode = '~r~', rgb = { 255,  50,  50 }, sprite = 'vermelho' },
}


---@type table<number, { blip: number, entity: boolean }>
local gSquadBlips = {}

---@type table<number, { state: string, health: number, armor: number }>
local gSquadInfo = {}

---@type table<number, string>
local gNameCache = {}

---@type table<number, vector3>
local gServerCoords = {}

local gRelGroupHash = nil
local gKills = 0
local gAssists = 0
local gShowNametags = true

---@type table<number, table[]>
local gPings = {}

---@type table<number, { x: number, y: number, expiresAt: number }>
local gMarkers = {}

local gLastPingTime = 0

---@type table<number, { blip: number, expiresAt: number }>
local gActiveBlips = {}

---@param src number
---@return number
local function getMemberSlot(src)

    for i, id in ipairs(Game.session.squad) do

        if id == src then return i end
    end

    return 1
end

---@param src number
---@return string
local function getMemberName(src)

    if gNameCache[src] then return gNameCache[src] end

    local playerId = GetPlayerFromServerId(src)

    if playerId ~= -1 then

        local name = GetPlayerName(playerId)

        if name then return name end
    end

    return ('Player %d'):format(src)
end

---@param ped number
---@return number sprite
local function getVehicleBlipSprite(ped)

    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then return 1 end

    local class = GetVehicleClass(vehicle)

    if class == 14 then return 471 end
    if class == 8 then return 226 end
    if class == 16 then return 307 end

    return 225
end

local function setupRelationshipGroup()

    local groupName = ('SQUAD_%d_%d'):format(Game.session.matchId, Game.session.squadIdx)
    local groupHash = GetHashKey(groupName)
    local _, hash = AddRelationshipGroup(groupName)

    gRelGroupHash = hash or groupHash

    local ped = PlayerPedId()

    SetPedRelationshipGroupHash(ped, gRelGroupHash)
    SetEntityCanBeDamagedByRelationshipGroup(ped, false, gRelGroupHash)
    NetworkSetFriendlyFireOption(true)
    SetCanAttackFriendly(ped, true)
    local selfSrc = GetPlayerServerId(PlayerId())
    for _, src in ipairs(Game.session.squad) do

        local playerId = GetPlayerFromServerId(src)

        if playerId and playerId > 0 and playerId ~= selfSrc then

            local allyPed = GetPlayerPed(playerId)

            if DoesEntityExist(allyPed) then
                SetPedRelationshipGroupHash(allyPed, gRelGroupHash)
                SetEntityCanBeDamagedByRelationshipGroup(allyPed, false, gRelGroupHash)
            end
        end
    end

end

---@param src number
local function removeBlipEntry(src)

    local entry = gSquadBlips[src]

    if entry and DoesBlipExist(entry.blip) then
        RemoveBlip(entry.blip)
    end

    gSquadBlips[src] = nil
end

local function removeAllBlips()

    for src in pairs(gSquadBlips) do
        removeBlipEntry(src)
    end
end

---@param src number
---@param blipHandle number
---@param isEntity boolean
---@param memberColor table
---@param info table | nil
local function applySquadBlip(src, blipHandle, isEntity, memberColor, info)

    local injured = info and info.state == PlayerState.INJURED

    SetBlipColour(blipHandle, injured and 1 or memberColor.blipColor)
    SetBlipScale(blipHandle, 0.8)
    gSquadBlips[src] = { blip = blipHandle, entity = isEntity }
end

local function updateSquadBlips()

    local selfSrc = GetPlayerServerId(PlayerId())

    for _, src in ipairs(Game.session.squad) do

        if src == selfSrc then goto continue end

        local info = gSquadInfo[src]
        local memberColor = eSquadConfig[getMemberSlot(src)]

        if info and (info.state == PlayerState.DEAD or info.state == PlayerState.SPECTATING) then
            removeBlipEntry(src)
            goto continue
        end

        local playerId = GetPlayerFromServerId(src)
        local ped = (playerId ~= -1) and GetPlayerPed(playerId) or 0
        local inScope = ped ~= 0 and DoesEntityExist(ped)
        local entry = gSquadBlips[src]

        if inScope then

            gServerCoords[src] = GetEntityCoords(ped)

            local sprite = memberColor.blipSprite

            if not entry or not entry.entity or not DoesBlipExist(entry.blip) then

                removeBlipEntry(src)

                local blip = AddBlipForEntity(ped)

                SetBlipSprite(blip, sprite)
                applySquadBlip(src, blip, true, memberColor, info)
            else

                SetBlipSprite(entry.blip, sprite)

                local injured = info and info.state == PlayerState.INJURED

                SetBlipColour(entry.blip, injured and 1 or memberColor.blipColor)
            end
        else

            local coords = gServerCoords[src]

            if not coords then goto continue end

            if not entry or entry.entity or not DoesBlipExist(entry.blip) then

                removeBlipEntry(src)

                local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

                SetBlipSprite(blip, memberColor.blipSprite)
                applySquadBlip(src, blip, false, memberColor, info)
            else

                SetBlipCoords(entry.blip, coords.x, coords.y, coords.z)

                local injured = info and info.state == PlayerState.INJURED

                SetBlipColour(entry.blip, injured and 1 or memberColor.blipColor)
            end
        end

        ::continue::
    end
end

local function sendSquadToNUI()

    local squadData = {}

    for idx, src in ipairs(Game.session.squad) do

        local name = getMemberName(src)
        local info = gSquadInfo[src]
        local isAlive = true
        local health = 100
        local armor = 0

        if info then
            isAlive = info.state == PlayerState.ALIVE or info.state == PlayerState.INJURED
            health = info.health or 100
            armor = info.armor or 0
        end

        local color = eSquadConfig[getMemberSlot(src)]

        squadData[#squadData + 1] = {
            slot = idx,
            name = name,
            health = health,
            armor = armor,
            alive = isAlive,
            speaking = false,
            badgeColor = ('rgb(%d,%d,%d)'):format(color.rgb[1], color.rgb[2], color.rgb[3]),
        }
    end

    Game.ui.send('hud:squad', squadData)
end

local function sendStatsToNUI()

    local ped = PlayerPedId()
    local health = math.max(0, GetEntityHealth(ped) - 100)
    local armor = GetPedArmour(ped)

    Game.ui.send('hud:update', {
        health = health,
        armor = armor,
        kills = gKills,
        speed = IsPedInAnyVehicle(ped, false) and math.floor(GetEntitySpeed(ped) * 3.6) or -1,
    })
end

---@param pos vector3|table
---@param text string
---@param distance number
---@param opts? { zDiv?: number, scaleMin?: number, scaleMax?: number, scaleDist?: number, alpha?: number }
local function drawWorldText(pos, text, distance, opts)
    opts = opts or {}
    local zDiv = opts.zDiv or 55
    local scaleMin = opts.scaleMin or 0.15
    local scaleMax = opts.scaleMax or 0.3
    local scaleDist = opts.scaleDist or 300
    local alpha = opts.alpha or 210

    local zOff = distance / zDiv
    local ok, sx, sy = World3dToScreen2d(pos.x or pos[1], pos.y or pos[2], (pos.z or pos[3]) + zOff)
    if not ok then return end

    local scale = math.max(scaleMin, scaleMax * (1 - distance / scaleDist))

    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(scale, scale)
    SetTextColour(255, 255, 255, alpha)
    SetTextEdge(1, 0, 0, 0, 150)
    SetTextDropshadow()
    SetTextOutline()
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(sx, sy)
end

local function drawNames()

    local selfSrc = GetPlayerServerId(PlayerId())
    local camCoords = GetFinalRenderedCamCoord()

    for _, src in ipairs(Game.session.squad) do

        if src == selfSrc then goto continue end

        local playerId = GetPlayerFromServerId(src)

        if not playerId or playerId <= 0 then goto continue end

        local ped = GetPlayerPed(playerId)

        if not DoesEntityExist(ped) then goto continue end
        if GetEntityHealth(ped) <= 100 then goto continue end

        local pedCoords = GetEntityCoords(ped)

        local distance = #(pedCoords - camCoords)

        if distance < 5.0 then goto continue end

        local color = eSquadConfig[getMemberSlot(src)]
        local bx, by, bz = table.unpack(GetPedBoneCoords(ped, NAMETAG_BONE))
        local name = getMemberName(src)
        local roundedDist = math.floor(distance)
        local text = ('%s[%dm]~w~ %s'):format(color.textCode, roundedDist, name)

        drawWorldText(vector3(bx, by, bz + 0.35), text, roundedDist)

        ::continue::
    end
end

---@param camPos vector3
---@param targetPos vector3
---@return vector3
local function calcZOffset(camPos, targetPos)

    local distance = #(camPos - targetPos)
    local zShift = math.min(distance * 0.03, 1.8)

    return targetPos + vector3(0.0, 0.0, zShift)
end

---@param targetPed number | nil
---@return table config
local function resolvePingConfig(targetPed)

    local isPed = targetPed ~= nil and DoesEntityExist(targetPed)
    local inVehicle = isPed and IsPedInAnyVehicle(targetPed, false)

    local vehicleSprite = 1

    if inVehicle then

        local veh = GetVehiclePedIsIn(targetPed, false)

        if DoesEntityExist(veh) then

            local model = GetEntityModel(veh)
            local cls = GetVehicleClass(veh)

            if cls == 14 then
                vehicleSprite = 471
            elseif cls == 8 or IsThisModelABike(model) then
                vehicleSprite = 226
            elseif cls == 16 or IsThisModelAPlane(model) then
                vehicleSprite = 307
            else
                vehicleSprite = 225
            end
        end
    end

    return {
        expiresAt = GetGameTimer() + (isPed and 2500 or PING_EXPIRE),
        blipSprite = isPed and (inVehicle and vehicleSprite or 1) or 162,
        blipColour = isPed and 1 or 3,
        blipScale = isPed and 0.7 or 1.0,
    }
end

---@param blip number
---@param config table
local function applyPingBlipConfig(blip, config)

    SetBlipSprite(blip, config.blipSprite)
    SetBlipColour(blip, config.blipColour)
    SetBlipScale(blip, config.blipScale)
end

---@param coords vector3
---@param targetPed number | nil
---@param color table | nil
---@return table pingData
local function attachPingBlip(coords, targetPed, color)

    local blip

    if targetPed and DoesEntityExist(targetPed) then
        blip = AddBlipForEntity(targetPed)
    else
        blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    end

    local config = resolvePingConfig(targetPed)

    if color then
        config.blipColour = color.blipColor
    end

    local pingData = {
        targetPed = targetPed,
        coords = coords,
        blip = blip,
        expiresAt = config.expiresAt,
        blipSprite = config.blipSprite,
        blipColour = config.blipColour,
        blipScale = config.blipScale,
        color = color,
        inVehicle = false,
    }

    gActiveBlips[#gActiveBlips + 1] = {
        blip = blip,
        expiresAt = config.expiresAt,
    }

    applyPingBlipConfig(blip, config)

    return pingData
end

---@param coords vector3
---@param spriteName string
local function renderPingIcon(coords, spriteName)

    local camCoords = GetGameplayCamCoord()
    local distance = #(camCoords.xy - coords.xy)
    local scale = math.max(0.14, 0.28 * (1 - distance / 280))

    if not HasStreamedTextureDictLoaded(PING_TEXTURE) then

        RequestStreamedTextureDict(PING_TEXTURE, true)

        local timeout = 1000

        while not HasStreamedTextureDictLoaded(PING_TEXTURE) and timeout > 0 do
            timeout = timeout - 1
            Wait(100)
        end
    end

    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    DrawSprite(PING_TEXTURE, spriteName, 0, 0, cfgPing.scaleX * scale, cfgPing.scaleY * scale, 0, 255, 255, 255, 255)
    ClearDrawOrigin()
end

---@param entity number
---@return string | nil
local function classifyEntity(entity)

    if IsEntityAVehicle(entity) then
        return 'vehicle'
    elseif IsPedAPlayer(entity) then
        return 'ped'
    end

    return nil
end

---@param serverId number
---@return boolean
local function isSquadMember(serverId)

    if not Game.session.squad or not serverId then return false end

    for _, id in ipairs(Game.session.squad) do

        if id == serverId then return true end
    end

    return false
end

---@return vector3
local function getCamDirection()

    local rot = GetGameplayCamRot()
    local radRot = vector3(math.pi / 180 * rot.x, math.pi / 180 * rot.y, math.pi / 180 * rot.z)

    return vector3(
        -math.sin(radRot.z) * math.abs(math.cos(radRot.x)),
        math.cos(radRot.z) * math.abs(math.cos(radRot.x)),
        math.sin(radRot.x)
    )
end

---@return vector3|nil endCoords
---@return number|nil entityHit
local function rayCastCamera()

    local coord = GetGameplayCamCoord()
    local dir = getCamDirection()
    local dist = 2500

    local target = vector3(
        coord.x + dir.x * dist,
        coord.y + dir.y * dist,
        coord.z + dir.z * dist
    )

    local rayHandle = StartShapeTestLosProbe(coord.x, coord.y, coord.z, target.x, target.y, target.z, -1, PlayerPedId(), 1)

    local retval = 1
    local _, _, endCoords, _, entityHit

    while retval == 1 do
        retval, _, endCoords, _, entityHit = GetShapeTestResult(rayHandle)
        if retval == 1 then Wait(0) end
    end

    if retval ~= 2 then
        return nil, nil
    end

    return endCoords, entityHit
end

local function emitPing()

    if not Game.session:active() then return end
    if Game.session:currentPhase() ~= MatchState.STARTED then return end
    if Game.combat and Game.combat.status and Game.combat.status() ~= Status.STANDING then return end
    if gLastPingTime > GetGameTimer() then return end

    gLastPingTime = GetGameTimer() + PING_COOLDOWN

    CreateThread(function()

        local hitCoords, hitEntity = rayCastCamera()
        if not hitCoords then return end

        local targetServerId = nil

        if hitEntity and hitEntity ~= 0 then

            local entityType = classifyEntity(hitEntity)
            local targetPed = nil

            if entityType == 'vehicle' then

                local driver = GetPedInVehicleSeat(hitEntity, -1)

                if driver ~= 0 then
                    targetPed = driver
                end
            elseif entityType == 'ped' then
                targetPed = hitEntity
            end

            if targetPed then

                local player = NetworkGetPlayerIndexFromPed(targetPed)
                local serverId = GetPlayerServerId(player)

                if player ~= -1 and player ~= PlayerId() then

                    if not isSquadMember(serverId) then
                        targetServerId = serverId
                        hitCoords = GetEntityCoords(targetPed)
                    end
                end
            end
        end

        Game.session:send('ping.create', hitCoords.x, hitCoords.y, hitCoords.z, targetServerId)
    end)
end

function Squad:setup(ctx)

    ctx.tracker = Game.Tracker.new()

    gSquadBlips = {}
    gSquadInfo = {}
    gNameCache = Game.session.names or {}
    gServerCoords = {}
    gRelGroupHash = nil
    gKills = 0
    gAssists = 0
    gShowNametags = true

    gPings = {}
    gMarkers = {}
    gLastPingTime = 0
    gActiveBlips = {}

    for _, src in ipairs(Game.session.squad) do
        gSquadInfo[src] = { state = PlayerState.ALIVE, health = 200, armor = 0 }
        getMemberName(src)
    end

    exports['kingg']:addGroup(15, Game.session.squad)

    setupRelationshipGroup()
    sendSquadToNUI()
end

function Squad:activate(ctx)

    ctx:poll(200, function()
        updateSquadBlips()
        sendStatsToNUI()
    end)

    ctx:poll(1000, function()
        sendSquadToNUI()
    end)


    ctx:tick(function()

        if gShowNametags and Game.session:currentPhase() == MatchState.STARTED then
            drawNames()
        end
    end)

    ctx:poll(1000, function()

        for index = #gActiveBlips, 1, -1 do

            local blipData = gActiveBlips[index]

            if blipData.expiresAt < GetGameTimer() then

                if DoesBlipExist(blipData.blip) then
                    RemoveBlip(blipData.blip)
                end

                table.remove(gActiveBlips, index)
            end
        end
    end)

    -- Ping render loop
    ctx:tick(function()

        if not Game.session:active() then return end
        if Game.session:currentPhase() ~= MatchState.STARTED then return end

        local camCoords = GetFinalRenderedCamCoord()
        local localServerId = GetPlayerServerId(PlayerId())

        for teamId, teamPings in pairs(gPings) do

            for pingIndex = #teamPings, 1, -1 do

                local ping = teamPings[pingIndex]
                local targetPed = ping.targetPed
                local pedExists = targetPed and DoesEntityExist(targetPed)

                if pedExists then

                    local inVehicle = IsPedInAnyVehicle(targetPed, false)
                    local entity = inVehicle and GetVehiclePedIsIn(targetPed, false) or targetPed
                    local entityCoords = GetEntityCoords(entity)
                    local adjustedCoords = calcZOffset(camCoords, entityCoords)

                    if inVehicle then
                        adjustedCoords = adjustedCoords + vector3(0.0, 0.0, 0.5)
                    end

                    ping.coords = adjustedCoords or entityCoords

                    if inVehicle ~= ping.inVehicle then
                        applyPingBlipConfig(ping.blip, resolvePingConfig(ping.targetPed))
                    end

                    ping.inVehicle = inVehicle
                else
                    ping.inVehicle = false
                end

                if DoesBlipExist(ping.blip) then

                    local currentSprite = GetBlipSprite(ping.blip)

                    if currentSprite ~= ping.blipSprite then

                        RemoveBlip(ping.blip)

                        local newBlip

                        if ping.targetPed and DoesEntityExist(ping.targetPed) then
                            newBlip = AddBlipForEntity(ping.targetPed)
                        end

                        if not newBlip then
                            newBlip = AddBlipForCoord(ping.coords.x, ping.coords.y, ping.coords.z)
                        end

                        ping.blip = newBlip
                        applyPingBlipConfig(ping.blip, resolvePingConfig(ping.targetPed))

                        gActiveBlips[#gActiveBlips + 1] = {
                            blip = ping.blip,
                            expiresAt = ping.expiresAt,
                        }
                    end
                end

                local camXY = vec(camCoords.x, camCoords.y)
                local pingXY = vec(ping.coords.x, ping.coords.y)
                local distance2d = #(camXY - pingXY)

                if distance2d <= cfgPing.renderDist then

                    local spriteName = ping.targetPed and PING_SPRITE_ENEMY or (ping.color and ping.color.sprite or 'azul')

                    local onScreen = World3dToScreen2d(ping.coords[1], ping.coords[2], ping.coords[3])

                    if onScreen then

                        local pingAlpha = IsPlayerFreeAiming(PlayerId()) and 150 or 220
                        drawWorldText(ping.coords, math.ceil(#(camCoords - ping.coords)) .. 'm', distance2d,
                            { zDiv = 250, scaleMin = 0.14, scaleMax = 0.28, scaleDist = 280, alpha = pingAlpha })

                        renderPingIcon(
                            ping.coords + vector3(0.0, 0.0, distance2d / 100),
                            spriteName
                        )
                    end
                end

                if ping.expiresAt < GetGameTimer() then

                    if ping.blip and DoesBlipExist(ping.blip) then
                        RemoveBlip(ping.blip)
                    end

                    table.remove(teamPings, pingIndex)
                end
            end
        end

        -- Waypoint auto-share
        local waypointBlip = GetFirstBlipInfoId(8)
        local waypointCoords = GetBlipInfoIdCoord(waypointBlip)

        if gLastPingTime < GetGameTimer() then

            local myMarker = gMarkers[localServerId]

            if not myMarker then
                gMarkers[localServerId] = { vec(0, 0), 0 }
                myMarker = gMarkers[localServerId]
            end

            local markerPos = myMarker[1]

            if #(markerPos - waypointCoords.xy) > 2 then

                if 0 ~= waypointCoords.x then
                    gLastPingTime = GetGameTimer() + PING_COOLDOWN
                    Game.session:send('marker.create', waypointCoords.xy)
                end
            end
        end

        -- Render team markers
        for serverId, markerData in pairs(gMarkers) do

            local markerPos = markerData[1]
            local distance = #(markerPos - camCoords.xy)
            local expiresAt = markerData[2]

            if expiresAt > GetGameTimer() and distance > 50 then

                if 0 ~= markerPos.x then

                    local mc = eSquadConfig[getMemberSlot(serverId)]
                    local mSize = math.max(3.5, distance * 0.018)

                    DrawMarker(1, markerPos.x, markerPos.y, cfgPing.markerZ, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        mSize, mSize, cfgPing.markerHeight, mc.rgb[1], mc.rgb[2], mc.rgb[3], 100)
                end
            end
        end
    end)
end

function Squad:teardown(ctx)

    print("Squad:teardown")
    exports['kingg']:clearGroup()

    -- Team
    removeAllBlips()
    NetworkSetFriendlyFireOption(false)

    gSquadBlips = {}
    gSquadInfo = {}
    gNameCache = {}
    gServerCoords = {}
    gRelGroupHash = nil
    gKills = 0
    gAssists = 0
    gShowNametags = true
    Game.session.names = nil

    -- Pings
    for _, teamPings in pairs(gPings) do

        for _, ping in pairs(teamPings) do

            if ping.blip and DoesBlipExist(ping.blip) then
                RemoveBlip(ping.blip)
            end
        end
    end

    for _, blipData in pairs(gActiveBlips) do

        if DoesBlipExist(blipData.blip) then
            RemoveBlip(blipData.blip)
        end
    end

    gPings = {}
    gMarkers = {}
    gActiveBlips = {}
    gLastPingTime = 0

    ctx.tracker:flush()
end

Game.session:onNet('team.setup', function(namesData)

    if not Game.session.names then Game.session.names = {} end

    for src, name in pairs(namesData) do
        print("received name", src, name, type(src))
        local id = tonumber(src)
        gNameCache[id] = name
        Game.session.names[id] = name
    end
end)

Game.session:onNet('team.coords', function(coordsData)

    for src, coords in pairs(coordsData) do
        gServerCoords[src] = vector3(coords[1], coords[2], coords[3])
    end
end)

Game.session:onNet('team.kills', function(killerSrc)

    local selfSrc = GetPlayerServerId(PlayerId())

    if killerSrc == selfSrc then
        gKills = gKills + 1
    else
        gAssists = gAssists + 1
    end
end)

Game.session:onNet('ping.show', function(coords, teamServerId, targetServerId)

    if not gPings[teamServerId] then
        gPings[teamServerId] = {}
    end

    local targetPed = nil

    if targetServerId then

        local player = GetPlayerFromServerId(targetServerId)

        if player and player ~= -1 then
            targetPed = GetPlayerPed(player)
        end
    end

    local memberColor = eSquadConfig[getMemberSlot(teamServerId)]
    local coordsVec = vector3(coords.x, coords.y, coords.z)
    local teamPings = gPings[teamServerId]

    if #teamPings >= 1 then
        table.sort(teamPings, function(a, b) return a.expiresAt < b.expiresAt end)
        local expired = table.remove(teamPings, 1)
        if expired and expired.blip and DoesBlipExist(expired.blip) then
            RemoveBlip(expired.blip)
        end
    end

    teamPings[#teamPings + 1] = attachPingBlip(coordsVec, targetPed, memberColor)

    PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end)

Game.session:onNet('marker.create', function(serverId, position)

    gMarkers[serverId] = { position, GetGameTimer() + MARKER_DURATION }
end)

Game.session:listen('playerLeft', function(src)

    removeBlipEntry(src)
    exports['kingg']:removePlayer(src)
    gSquadInfo[src] = nil
    gServerCoords[src] = nil
end)


RegisterCommand('stateNametag', function()

    if not Game.session:active() then return end

    gShowNametags = not gShowNametags
end, false)

RegisterKeyMapping('stateNametag', 'Ativar/desativar nametag', 'keyboard', 'B')

RegisterCommand('+br:ping', emitPing, false)
RegisterKeyMapping('+br:ping', 'Ping', 'MOUSE_BUTTON', cfgPing.key)
