--[[ Constroi e gerencia paineis 3D (DUI + Scaleform) para cada zona de spawn:
     calcula posicao/rotacao com base nas linhas de spawn, controla o ciclo de vida
     (criar/destruir), e fornece deteccao de mira/proximidade para aim assist. ]]

local spawn3dEnabled = GetConvarBool("multiTrackingSpawn3dEnabled", true)
local PANEL_MAX_AIM_DISTANCE = 30.0
local PANEL_INTERACT_DISTANCE = 3.0

SPAWN_POSITIONS = nil
PANEL_SHOOT_ANGLE = 180.0

local function ComputeNormalizedDirection(fromCoords, toCoords)
    local dx = toCoords.x - fromCoords.x
    local dy = toCoords.y - fromCoords.y
    local dz = toCoords.z - fromCoords.z
    local length = math.sqrt(dx * dx + dy * dy + dz * dz)
    if length > 0 then
        dx = dx / length
        dy = dy / length
        dz = dz / length
    end
    return dx, dy, dz
end

local function ResolveLineEndpoints(line)
    local spawnDirection = line.spawnDirection
    if not spawnDirection then
        spawnDirection = "AB"
    end
    local isReverse = "BA" == spawnDirection

    local startCds
    if isReverse and line.endCds then
        startCds = line.endCds
    else
        startCds = line.startCds
    end

    local endCds
    if isReverse and line.startCds then
        endCds = line.startCds
    else
        endCds = line.endCds
    end

    return startCds, endCds
end

local function ComputePanelHeading(dirX, dirY, panelSide)
    local yawDeg = math.deg(math.atan(dirY, dirX))
    local side = panelSide
    if not panelSide then
        side = 1
    end
    local offset
    if -1 == side then
        offset = 180.0
    else
        offset = 0.0
    end
    return yawDeg + offset
end

local function OffsetCoords(origin, dirX, dirY, dirZ, distance)
    return vector3(
        origin.x + dirX * distance,
        origin.y + dirY * distance,
        origin.z + dirZ * distance
    )
end

local function AreBothNonEmptyTables(a, b)
    if "table" ~= type(a) or "table" ~= type(b) then
        return false
    end
    if 0 == #a or 0 == #b then
        return false
    end
    return true
end

local function BuildPanelLayout()
    local layout = {}
    local zones = MultitrackingSpawnZones
    local panelLocations = MultitrackingSpawn3dPanelsLocations

    if not AreBothNonEmptyTables(zones, panelLocations) then
        return layout
    end

    local panelSpacing = 2.5
    local panelGap = 0.2

    for zoneIndex, zone in ipairs(zones) do
        local spawn3d = zone.spawn3d
        if spawn3d then
            local distanceOffset = (zoneIndex - 1) * (panelSpacing + panelGap)
            local linePositions = {}

            for _, panelLocation in ipairs(panelLocations) do
                local startCds, endCds = ResolveLineEndpoints(panelLocation)
                local dirX, dirY, dirZ = ComputeNormalizedDirection(startCds, endCds)
                local heading = ComputePanelHeading(dirX, dirY, panelLocation.panelSide)
                local position = OffsetCoords(startCds, dirX, dirY, dirZ, distanceOffset)

                local idx = #linePositions + 1
                linePositions[idx] = {
                    position = position,
                    rotation = vector3(-40.0, 0.0, heading),
                }
            end

            local panelIndex = spawn3d.index
            layout[panelIndex] = {
                linePositions = linePositions,
                imageUrl = spawn3d.imageUrl,
                description = spawn3d.description,
                sfName = "kinggGroupTrackingPanel" .. zoneIndex,
                spawns = zone.spawns,
                centerZoneCds = zone.centerZoneCds,
                zoneName = zone.name,
                zoneLabel = zone.label,
            }
        end
    end

    return layout
end

local function BuildPanelSettings(panelData)
    if not panelData then
        return nil
    end

    return {
        identifierText = "multiTracking",
        scale = 0.1,
        width = 1280,
        height = 720,
        sfName = panelData.sfName,
        panelData = {
            url = panelData.imageUrl,
            description = panelData.description,
        },
    }
end

local function GetPanelDataBySpawnIndex(spawnIndex)
    if not spawnIndex or not SPAWN_POSITIONS then
        return nil
    end
    return SPAWN_POSITIONS[spawnIndex]
end

local function CreatePanelForSpawnIndex(spawnIndex)
    local panelData = GetPanelDataBySpawnIndex(spawnIndex)
    if not panelData then
        return nil
    end

    local settings = BuildPanelSettings(panelData)
    if not settings then
        return nil
    end

    local panel = SpawnPanels:new(spawnIndex, settings, panelData.linePositions)
    if not panel or not panel.create then
        return nil
    end

    panelData.panel = panel
    return panel:create()
end

local function SendPanelDuiMessage(duiObject, action, data)
    if not duiObject then
        return
    end
    local payload = {
        action = action,
        data = data or {},
    }
    SendDuiMessage(duiObject, json.encode(payload))
end

local function SetTrackingDuiOpacity(duiObject, value)
    SendPanelDuiMessage(duiObject, "setOpacity", { value = value })
end
_G.SetTrackingDuiOpacity = SetTrackingDuiOpacity

local function SetTrackingDuiImageAndDescription(duiObject, url, description)
    SendPanelDuiMessage(duiObject, "setImage", {
        url = url,
        description = description,
    })
end
_G.SetTrackingDuiImageAndDescription = SetTrackingDuiImageAndDescription

local function DestroyAllPanels()
    if not SPAWN_POSITIONS then
        return
    end
    for _, panelData in pairs(SPAWN_POSITIONS) do
        if panelData.panel and panelData.panel.destroy then
            panelData.panel:destroy()
        end
    end
    SPAWN_POSITIONS = nil
end

local function CreateAllPanels()
    if not spawn3dEnabled then
        return
    end

    DestroyAllPanels()

    SPAWN_POSITIONS = BuildPanelLayout()

    for spawnIndex in pairs(SPAWN_POSITIONS) do
        Citizen.CreateThread(function()
            Wait(100)
            CreatePanelForSpawnIndex(spawnIndex)
        end)
    end
end

AddEventHandler("multiTracking:whenEnter", CreateAllPanels)
AddEventHandler("multiTracking:whenLeave", DestroyAllPanels)

local function DrawSpawn3dLine(panelLocation)
    if not panelLocation or not panelLocation.startCds or not panelLocation.endCds then
        return
    end

    DrawLine(
        panelLocation.startCds.x, panelLocation.startCds.y, panelLocation.startCds.z,
        panelLocation.endCds.x, panelLocation.endCds.y, panelLocation.endCds.z,
        255, 0, 0, 255
    )
end

local function MultiTrackingDrawSpawn3dLines()
    local panelLocations = MultitrackingSpawn3dPanelsLocations
    if "table" ~= type(panelLocations) then
        return
    end
    for _, panelLocation in ipairs(panelLocations) do
        DrawSpawn3dLine(panelLocation)
    end
end
_G.MultiTrackingDrawSpawn3dLines = MultiTrackingDrawSpawn3dLines

local function TeleportPlayerToPanelSpawn(panelData)
    if not panelData then
        return
    end

    local destination = nil
    local spawns = panelData.spawns
    if "table" == type(spawns) and #spawns > 0 then
        math.randomseed(GetGameTimer())
        destination = spawns[math.random(1, #spawns)]
    else
        destination = panelData.centerZoneCds
    end

    if not destination then
        return
    end

    local playerPed = PlayerPedId()
    RequestCollisionAtCoord(destination.x, destination.y, destination.z)
    SetEntityCoordsNoOffset(playerPed, destination.x, destination.y, destination.z, false, false, false)
    FreezeEntityPosition(playerPed, true)

    local waited = 0
    while not HasCollisionLoadedAroundEntity(playerPed) and waited < 80 do
        Wait(100)
        waited = waited + 1
    end

    -- Always unfreeze after teleport (never restore prior frozen state).
    FreezeEntityPosition(playerPed, false)
end

local function FindNearestPanelByLines(coords, maxDistance)
    if not SPAWN_POSITIONS then
        return nil
    end

    local nearestPanel = nil
    local nearestDistance = maxDistance

    for _, panelData in pairs(SPAWN_POSITIONS) do
        local linePositions = panelData.linePositions
        if not linePositions then
            linePositions = {}
        end
        for _, line in ipairs(linePositions) do
            local distance = #(coords - line.position)
            if nearestDistance > distance then
                nearestDistance = distance
                nearestPanel = panelData
            end
        end
    end

    return nearestPanel
end

local function ComputeRayPanelIntersection(rayOrigin, rayDirection, panelData)
    if not panelData.panel then
        return nil
    end

    local right, up, normal = panelData.panel:getScaleformBasis()
    local center = panelData.panel:getScaleformCenterPosition()

    local denom = normal.x * rayDirection.x + normal.y * rayDirection.y + normal.z * rayDirection.z
    if math.abs(denom) < 1.0E-4 then
        return nil
    end

    local numer = (center.x - rayOrigin.x) * normal.x
                + (center.y - rayOrigin.y) * normal.y
                + (center.z - rayOrigin.z) * normal.z
    local t = numer / denom

    if t < 0 then
        return nil
    end

    local hitX = rayOrigin.x + rayDirection.x * t
    local hitY = rayOrigin.y + rayDirection.y * t
    local hitZ = rayOrigin.z + rayDirection.z * t
    local hitPoint = vector3(hitX, hitY, hitZ)

    local width, height = panelData.panel:getScaleformDimensions()

    local dx = hitX - center.x
    local dy = hitY - center.y
    local dz = hitZ - center.z

    local localX = (dx * right.x + dy * right.y + dz * right.z) / (width / 2)
    local localY = (dx * up.x + dy * up.y + dz * up.z) / (height / 2)

    if math.abs(localX) <= 1 and math.abs(localY) <= 1 then
        return hitPoint
    end

    return nil
end

local function MultiTrackingGetPanelPointAt(panelData, localX, localY)
    if not panelData or not panelData.panel or not panelData.panel.getScaleformPoint then
        return nil
    end
    return panelData.panel:getScaleformPoint(localX, localY)
end
_G.MultiTrackingGetPanelPointAt = MultiTrackingGetPanelPointAt

local function MultiTrackingGetCamDir()
    local rot = GetGameplayCamRot(2)
    local pitch = math.rad(rot.x)
    local yaw = math.rad(rot.z)

    local x = -math.sin(yaw) * math.abs(math.cos(pitch))
    local y = math.cos(yaw) * math.abs(math.cos(pitch))
    local z = math.sin(pitch)

    return vector3(x, y, z)
end
_G.MultiTrackingGetCamDir = MultiTrackingGetCamDir

local function MultiTrackingGetPanelAimContact(rayOrigin, rayDirection, panelData, playerCoords)
    if not playerCoords then
        playerCoords = GetEntityCoords(PlayerPedId())
    end

    local hitPoint = ComputeRayPanelIntersection(rayOrigin, rayDirection, panelData)
    if not hitPoint then
        return nil
    end

    local distance = #(playerCoords - hitPoint)
    if distance > PANEL_MAX_AIM_DISTANCE then
        return nil
    end

    return hitPoint
end
_G.MultiTrackingGetPanelAimContact = MultiTrackingGetPanelAimContact

local function MultiTrackingIsCameraAimingAtPanel(rayOrigin, rayDirection, panelData, playerCoords)
    local hitPoint = MultiTrackingGetPanelAimContact(rayOrigin, rayDirection, panelData, playerCoords)
    return nil ~= hitPoint
end
_G.MultiTrackingIsCameraAimingAtPanel = MultiTrackingIsCameraAimingAtPanel

local function MultiTrackingGetPanelMaxAimDistance()
    return PANEL_MAX_AIM_DISTANCE
end
_G.MultiTrackingGetPanelMaxAimDistance = MultiTrackingGetPanelMaxAimDistance

local function FindPanelUnderCameraAim()
    if not SPAWN_POSITIONS then
        return nil, nil
    end

    local camCoord = GetGameplayCamCoord()
    local camDir = MultiTrackingGetCamDir()
    local playerCoords = GetEntityCoords(PlayerPedId())

    local nearestPanel = nil
    local nearestDistance = nil
    local nearestHit = nil

    for _, panelData in pairs(SPAWN_POSITIONS) do
        local hitPoint = MultiTrackingGetPanelAimContact(camCoord, camDir, panelData, playerCoords)
        if hitPoint then
            local distance = #(camCoord - hitPoint)
            if not nearestDistance or nearestDistance > distance then
                nearestPanel = panelData
                nearestDistance = distance
                nearestHit = hitPoint
            end
        end
    end

    return nearestPanel, nearestHit
end

Citizen.CreateThread(function()
    while true do
        Wait(0)

        if not IsEnabledMultiTracking() or not SPAWN_POSITIONS then
            Wait(500)
        else
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            local nearbyPanel = FindNearestPanelByLines(playerCoords, PANEL_INTERACT_DISTANCE)
            if nearbyPanel then
                if IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38) then
                    TeleportPlayerToPanelSpawn(nearbyPanel)
                end
            end

            if IsControlJustPressed(0, 24) or IsDisabledControlJustPressed(0, 24) then
                local aimedPanel = FindPanelUnderCameraAim()
                if aimedPanel then
                    TeleportPlayerToPanelSpawn(aimedPanel)
                end
            end
        end
    end
end)

AddConvarChangeListener("multiTrackingSpawn3dEnabled", function()
    if not IsEnabledMultiTracking() then
        return
    end

    spawn3dEnabled = GetConvarBool("multiTrackingSpawn3dEnabled", true)
    if not spawn3dEnabled then
        DestroyAllPanels()
    else
        CreateAllPanels()
    end
end)
