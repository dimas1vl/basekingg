--[[ Classe SpawnPanels: encapsula um painel 3D Scaleform+DUI ancorado em uma
     posicao/rotacao (com suporte a multiplas linhas de aproximacao), gerencia
     seu ciclo de vida e fornece utilitarios geometricos (base, dimensoes,
     pontos no plano do painel). ]]

SpawnPanels = {}
SpawnPanels.__index = SpawnPanels

function SpawnPanels:new(spawnIndex, settings, linePositions)
    local firstLine
    if linePositions then
        firstLine = linePositions[1]
    end

    local instance = {
        spawnIndex = spawnIndex,
        settings = settings,
        isActiveDuiLoop = false,
        duiObject = nil,
        sfHandle = nil,
        txd = nil,
        runtimeTexture = nil,
        txdName = nil,
        txnName = nil,
        linePositions = linePositions or {},
    }

    local position
    if firstLine and firstLine.position then
        position = firstLine.position
    else
        position = vector3(0.0, 0.0, 0.0)
    end
    instance.position = position

    local rotation
    if firstLine and firstLine.rotation then
        rotation = firstLine.rotation
    else
        rotation = vector3(0.0, 0.0, 0.0)
    end
    instance.rotation = rotation

    setmetatable(instance, SpawnPanels)
    return instance
end

function SpawnPanels:getNearestLineData(coords)
    local linePositions = self.linePositions
    if not linePositions or 0 == #linePositions then
        return {
            position = self.position,
            rotation = self.rotation,
        }
    end

    local nearest = linePositions[1]
    local nearestDistance = nil

    for _, line in ipairs(linePositions) do
        local distance = #(coords - line.position)
        if not nearestDistance or nearestDistance > distance then
            nearest = line
            nearestDistance = distance
        end
    end

    return nearest
end

function SpawnPanels:isExistDuiBySpawnIndex()
    if not self.isActiveDuiLoop then
        return false
    end
    if not self.duiObject then
        return false
    end
    return IsDuiAvailable(self.duiObject)
end

function SpawnPanels:getScaleformDrawScale()
    local settings = self.settings or {}
    local scale = settings.scale or 0.1
    local width = settings.width or 1280
    local height = settings.height or 720

    local drawScaleX = scale
    local drawScaleY = scale * (height / width)
    return drawScaleX, drawScaleY
end

function SpawnPanels:getScaleformDimensions()
    local settings = self.settings or {}
    local scale = settings.scale or 0.1
    local width = settings.width or 1280
    local height = settings.height or 720

    local divisor = 53.0
    local worldWidth = (width * scale) / divisor
    local worldHeight = (height * scale) / divisor
    return worldWidth, worldHeight
end

function SpawnPanels:getScaleformBasis()
    local rotation = self.rotation
    if not rotation then
        rotation = vector3(0.0, 0.0, 0.0)
    end

    local pitch = math.rad(rotation.x)
    local yaw = math.rad(rotation.z)

    local forward = vector3(
        -math.sin(yaw) * math.abs(math.cos(pitch)),
        math.cos(yaw) * math.abs(math.cos(pitch)),
        math.sin(pitch)
    )

    local right = vector3(math.cos(yaw), math.sin(yaw), 0.0)

    local up = vector3(
        right.y * forward.z - right.z * forward.y,
        right.z * forward.x - right.x * forward.z,
        right.x * forward.y - right.y * forward.x
    )

    return right, up, forward
end

function SpawnPanels:getScaleformCenterPosition()
    local position = self.position
    if not position then
        position = vector3(0.0, 0.0, 0.0)
    end

    local width, height = self:getScaleformDimensions()
    local right, up = self:getScaleformBasis()

    local half = 2.0

    return vector3(
        position.x + right.x * (width / half) - up.x * (height / half),
        position.y + right.y * (width / half) - up.y * (height / half),
        position.z + right.z * (width / half) - up.z * (height / half)
    )
end

function SpawnPanels:getScaleformPoint(localX, localY)
    local center = self:getScaleformCenterPosition()
    local width, height = self:getScaleformDimensions()
    local right, up = self:getScaleformBasis()

    local lx = localX or 0.0
    lx = lx * (width / 2.0)

    local ly = localY or 0.0
    ly = ly * (height / 2.0)

    return vector3(
        center.x + right.x * lx + up.x * ly,
        center.y + right.y * lx + up.y * ly,
        center.z + right.z * lx + up.z * ly
    )
end

function SpawnPanels:getScaleformVertices()
    local vertices = {}
    vertices.bottomLeft = self:getScaleformPoint(-1, -1)
    vertices.bottomRight = self:getScaleformPoint(1, -1)
    vertices.topRight = self:getScaleformPoint(1, 1)
    vertices.topLeft = self:getScaleformPoint(-1, 1)
    return vertices
end

function SpawnPanels:getScaleformArea()
    local vertices = self:getScaleformVertices()
    local area = {}
    area[1] = vertices.bottomLeft
    area[2] = vertices.bottomRight
    area[3] = vertices.topRight
    area[4] = vertices.topLeft
    return area
end

function SpawnPanels:configureTexture()
    local settings = self.settings
    if not settings or not self.sfHandle or not self.txdName or not self.txnName then
        return
    end

    PushScaleformMovieFunction(self.sfHandle, "SET_TEXTURE")
    PushScaleformMovieMethodParameterString(self.txdName)
    PushScaleformMovieMethodParameterString(self.txnName)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(settings.width)
    PushScaleformMovieFunctionParameterInt(settings.height)
    PopScaleformMovieFunctionVoid()
end

function SpawnPanels:resolveOpacity(playerCoords, panelData)
    local distance = #(playerCoords - self.position)
    local maxAimDistance = MultiTrackingGetPanelMaxAimDistance()
    if not maxAimDistance then
        maxAimDistance = 20.0
    end
    if distance > maxAimDistance then
        return 0.0
    end

    if not IsControlPressed(0, 25) then
        return 0.7
    end

    local camCoord = GetGameplayCamCoord()
    local camDir = MultiTrackingGetCamDir()

    local isAimingAtPanel
    if panelData then
        isAimingAtPanel = MultiTrackingIsCameraAimingAtPanel(camCoord, camDir, panelData, playerCoords)
    end

    if isAimingAtPanel then
        return 1.0
    end
    return 0.7
end

function SpawnPanels:findOwnPanelData()
    if not SPAWN_POSITIONS then
        return nil
    end
    return SPAWN_POSITIONS[self.spawnIndex]
end

function SpawnPanels:loopDui()
    if not self.settings or not self.sfHandle then
        return
    end

    local drawScaleX, drawScaleY = self:getScaleformDrawScale()
    local lastOpacity = nil
    local ownPanelData = self:findOwnPanelData()

    while true do
        if not self.isActiveDuiLoop then break end
        if not self.duiObject then break end

        local duiObject = self.duiObject
        if not duiObject then break end

        if not IsDuiAvailable(duiObject) then break end

        Wait(0)

        local playerCoords = GetEntityCoords(PlayerPedId())
        local nearestLine = self:getNearestLineData(playerCoords)
        self.position = nearestLine.position
        self.rotation = nearestLine.rotation

        if not ownPanelData then
            ownPanelData = self:findOwnPanelData()
        end

        local opacity = self:resolveOpacity(playerCoords, ownPanelData)
        if lastOpacity ~= opacity then
            SetTrackingDuiOpacity(duiObject, opacity)
            lastOpacity = opacity
        end

        local position = self.position
        local rotation = self.rotation
        DrawScaleformMovie_3dNonAdditive(
            self.sfHandle,
            position.x, position.y, position.z,
            rotation.x, rotation.y, rotation.z,
            2.0, 2.0, 2.0,
            drawScaleX, drawScaleY, 1.0,
            2
        )
    end

    if self.duiObject and IsDuiAvailable(self.duiObject) then
        DestroyDui(self.duiObject)
    end

    self.runtimeTexture = nil
    self.txd = nil

    if self.sfHandle then
        SetScaleformMovieAsNoLongerNeeded(self.sfHandle)
        self.sfHandle = nil
    end

    self.isActiveDuiLoop = false
    self.duiObject = nil
end

function SpawnPanels:loadScaleform(sfName)
    local attempts = 0
    local maxAttempts = 30
    local sfHandle = RequestScaleformMovie(sfName)

    while not HasScaleformMovieLoaded(sfHandle) and attempts < maxAttempts do
        Wait(100)
        attempts = attempts + 1
    end

    if maxAttempts <= attempts then
        return nil
    end

    return sfHandle
end

function SpawnPanels:destroy()
    self.isActiveDuiLoop = false
    self.isDestroyed = true
end

function SpawnPanels:applyRuntimeTexture()
    local duiObject = self.duiObject
    if not duiObject then
        return
    end

    self.txd = CreateRuntimeTxd(self.txdName)

    local duiHandle = GetDuiHandle(duiObject)
    self.runtimeTexture = CreateRuntimeTextureFromDuiHandle(self.txd, self.txnName, duiHandle)
    CommitRuntimeTexture(self.runtimeTexture)
end

function SpawnPanels:loopFallbackRender()
    local label = (self.settings and self.settings.panelData and self.settings.panelData.description) or ""
    while self.isActiveDuiLoop and not self.isDestroyed do
        Wait(0)

        local playerCoords = GetEntityCoords(PlayerPedId())
        local nearestLine  = self:getNearestLineData(playerCoords)
        self.position = nearestLine.position
        self.rotation = nearestLine.rotation

        local dist = #(playerCoords - self.position)
        if dist <= 60.0 then
            local center = self:getScaleformCenterPosition()
            local groundZ = center.z - 1.5

            DrawMarker(
                1,
                center.x, center.y, groundZ,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                2.5, 2.5, 1.5,
                200, 254, 78, 90,
                false, false, 2,
                false, nil, nil, false
            )

            if label ~= "" then
                local onScreen, sx, sy = World3dToScreen2d(center.x, center.y, center.z + 0.6)
                if onScreen then
                    SetTextScale(0.5, 0.5)
                    SetTextFont(4)
                    SetTextProportional(true)
                    SetTextColour(255, 255, 255, 220)
                    SetTextOutline()
                    SetTextCentre(true)
                    BeginTextCommandDisplayText("STRING")
                    AddTextComponentSubstringPlayerName(label)
                    EndTextCommandDisplayText(sx, sy)
                end
            end
        end
    end
end

function SpawnPanels:create()
    if self:isExistDuiBySpawnIndex() then
        return nil
    end

    local settings = self.settings
    local spawnIndex = self.spawnIndex
    if not spawnIndex or not settings then
        return nil
    end

    self.txdName = string.format("%s_%s", settings.identifierText, spawnIndex)
    self.txnName = string.format("%s_%s", settings.identifierText, spawnIndex)

    local sfHandle = self:loadScaleform(settings.sfName)
    self.sfHandle = sfHandle

    if not self.sfHandle or not HasScaleformMovieLoaded(self.sfHandle) then
        if self.sfHandle then
            SetScaleformMovieAsNoLongerNeeded(self.sfHandle)
            self.sfHandle = nil
        end
        -- FALLBACK: scaleform custom (assetpack) não disponível.
        -- Renderiza marker 3D + label no nome da zona pra player conseguir
        -- localizar e usar (mira+atira na posição = teleporta).
        print(('^3[tracking] scaleform "%s" indisponível — usando fallback de marker^7'):format(tostring(settings.sfName)))
        self.isFallback = true
        self.isActiveDuiLoop = true
        Citizen.CreateThread(function()
            self:loopFallbackRender()
        end)
        return self  -- retorna o objeto pra panelData.panel ficar setado (necessário pro aim/teleport)
    end

    local duiObject = CreateDui(('https://cfx-nui-%s/nui/index.html'):format(GetCurrentResourceName()), settings.width, settings.height)
    self.duiObject = duiObject

    local attempts = 0
    local maxAttempts = 30
    while not IsDuiAvailable(duiObject) and attempts < maxAttempts do
        Wait(100)
        attempts = attempts + 1
    end

    if maxAttempts <= attempts then
        print("^3[spawn-3d]^7 Timeout creating dui: " .. tostring(duiObject))
        return nil
    end

    self:applyRuntimeTexture()
    Wait(2000)
    SetTrackingDuiImageAndDescription(duiObject, settings.panelData.url, settings.panelData.description)
    self:configureTexture()

    self.isActiveDuiLoop = true
    self.duiObject = duiObject

    Citizen.CreateThread(function()
        self:loopDui()
    end)

    return duiObject
end
