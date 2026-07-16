MinimapRaccoConfig = {
    clipType = 0,
    radarZoom = 1200,
    alignX = "L",
    alignY = "T",

    -- Mantem x/y/w/h com o mesmo tamanho em pixels da referencia abaixo,
    -- independente da resolucao ou proporcao da tela do jogador.
    fixedSize = true,
    referenceResolution = { width = 1920, height = 1080 },
    fixedPixels = {
        minimap = { w = 290, h = 205 },
        mask = { w = 213, h = 172 },
        blur = { w = 512, h = 256 }
    },
    -- Posicao principal no topo esquerdo.
    minimap = { x = 0.003, y = 0.042, w = 0.160417, h = 0.212035 },
    mask    = { x = 0.03, y = 0.11, w = 0.111000, h = 0.159000 },
    blur    = { x = -0.023, y = 0.015, w = 0.266000, h = 0.237000 },

    -- Posicao alternativa embaixo.
    -- minimap = { x = -0.004500, y = 0.002000, w = 0.150000, h = 0.188888 },
    -- mask    = { x =  0.020000, y = 0.030000, w = 0.111000, h = 0.159000 },
    -- blur    = { x = -0.030000, y = 0.022000, w = 0.266000, h = 0.237000 },
}

local textureDict = "circleminimap"
local masks = { "radarmasksm", "radarmask1g" }
local components = {
    minimap = "minimap",
    mask = "minimap_mask",
    blur = "minimap_blur"
}

local function CopyRect(rect)
    return {
        x = rect.x,
        y = rect.y,
        w = rect.w,
        h = rect.h
    }
end

local function GetScreenResolution()
    if GetActualScreenResolution then
        local actualW, actualH = GetActualScreenResolution()

        if actualW and actualH and actualW > 0 and actualH > 0 then
            return actualW, actualH
        end
    end

    return GetActiveScreenResolution()
end

local function GetAspectCorrection()
    local reference = MinimapRaccoConfig.referenceResolution
    local referenceW = reference.width or 1920
    local referenceH = reference.height or 1080
    local referenceAspect = referenceW / referenceH
    local currentAspect = GetAspectRatio and GetAspectRatio(false) or referenceAspect

    if not currentAspect or currentAspect <= 0 then
        return 1.0
    end

    return currentAspect / referenceAspect
end

local function GetAlignByte(value, fallback)
    local text = tostring(value or fallback)
    return string.byte(text:sub(1, 1):upper())
end

local function GetScreenRect(rect)
    local horizontal = tostring(MinimapRaccoConfig.alignX or "L"):sub(1, 1):upper()
    local vertical = tostring(MinimapRaccoConfig.alignY or "T"):sub(1, 1):upper()
    local leftX = rect.x
    local rightX = rect.x + rect.w
    local topY = rect.y
    local bottomY = rect.y + rect.h

    if horizontal == "R" then
        leftX = rect.x - rect.w
        rightX = rect.x
    elseif horizontal == "C" then
        leftX = rect.x - (rect.w / 2)
        rightX = rect.x + (rect.w / 2)
    end

    if vertical == "B" then
        topY = rect.y - rect.h
        bottomY = rect.y
    elseif vertical == "C" then
        topY = rect.y - (rect.h / 2)
        bottomY = rect.y + (rect.h / 2)
    end

    SetScriptGfxAlign(GetAlignByte(horizontal, "L"), GetAlignByte(vertical, "T"))

    local left, top = GetScriptGfxPosition(leftX, topY)
    local right, bottom = GetScriptGfxPosition(rightX, bottomY)

    ResetScriptGfxAlign()

    local screenW, screenH = GetActiveScreenResolution()

    return {
        x = left * screenW,
        y = top * screenH,
        w = (right - left) * screenW,
        h = (bottom - top) * screenH
    }
end

local function GetFixedRect(name, rect)
    if not MinimapRaccoConfig.fixedSize then
        return CopyRect(rect)
    end

    local screenW, screenH = GetActiveScreenResolution()
    if screenW <= 0 or screenH <= 0 then
        return CopyRect(rect)
    end

    local reference = MinimapRaccoConfig.referenceResolution
    local referenceW = reference.width or 1920
    local referenceH = reference.height or 1080
    local fixed = MinimapRaccoConfig.fixedPixels[name] or {}
    local aspectCorrection = GetAspectCorrection()
    local desiredW = (fixed.w or (rect.w * referenceW)) * aspectCorrection
    local desiredH = fixed.h or (rect.h * referenceH)
    local fixedRect = CopyRect(rect)
    fixedRect.x = fixedRect.x * aspectCorrection

    -- SetMinimapComponentPosition usa valores normalizados.
    -- GetScriptGfxPosition mostra como o GTA vai converter esse rect para
    -- pixels reais. Ajustamos por iteracao ate bater no tamanho desejado.
    -- A largura recebe aspectCorrection para compensar o stretch interno do minimap.
    -- Em telas mais estreitas que 16:9, como 16:10, essa correcao reduz a largura.
    for _ = 1, 6 do
        local screenRect = GetScreenRect(fixedRect)

        if screenRect.w ~= 0 and screenRect.h ~= 0 then
            fixedRect.w = fixedRect.w * desiredW / math.abs(screenRect.w)
            fixedRect.h = fixedRect.h * desiredH / math.abs(screenRect.h)
        end
    end

    return fixedRect
end

local function GetOverlayRect(name, rect)
    if not MinimapRaccoConfig.fixedSize then
        return CopyRect(rect)
    end

    local reference = MinimapRaccoConfig.referenceResolution
    local referenceW = reference.width or 1920
    local referenceH = reference.height or 1080
    local fixed = MinimapRaccoConfig.fixedPixels[name] or {}
    local desiredW = fixed.w or (rect.w * referenceW)
    local desiredH = fixed.h or (rect.h * referenceH)
    local overlayRect = CopyRect(rect)

    -- Rect para NUI/overlays: nao recebe aspectCorrection, porque PNG nao
    -- deve ser contra-distorcida como o componente interno do GTA.
    for _ = 1, 6 do
        local screenRect = GetScreenRect(overlayRect)

        if screenRect.w ~= 0 and screenRect.h ~= 0 then
            overlayRect.w = overlayRect.w * desiredW / math.abs(screenRect.w)
            overlayRect.h = overlayRect.h * desiredH / math.abs(screenRect.h)
        end
    end

    return overlayRect
end

local function GetScreenStateKey()
    local screenW, screenH = GetScreenResolution()
    local aspect = screenW / screenH
    local safeZone = GetSafeZoneSize and GetSafeZoneSize() or 1.0

    return ("%sx%s:%.6f:%.6f"):format(screenW, screenH, aspect, safeZone)
end

local function GetRuntimeMinimapConfig()
    return {
        clipType = MinimapRaccoConfig.clipType,
        radarZoom = MinimapRaccoConfig.radarZoom,
        alignX = MinimapRaccoConfig.alignX,
        alignY = MinimapRaccoConfig.alignY,
        fixedSize = MinimapRaccoConfig.fixedSize,
        referenceResolution = MinimapRaccoConfig.referenceResolution,
        minimap = GetFixedRect("minimap", MinimapRaccoConfig.minimap),
        mask = GetFixedRect("mask", MinimapRaccoConfig.mask),
        blur = GetFixedRect("blur", MinimapRaccoConfig.blur),
        overlay = {
            minimap = GetOverlayRect("minimap", MinimapRaccoConfig.minimap),
            mask = GetOverlayRect("mask", MinimapRaccoConfig.mask),
            blur = GetOverlayRect("blur", MinimapRaccoConfig.blur)
        }
    }
end

local function GetMinimapConfig()
    return GetRuntimeMinimapConfig()
end

exports("GetMinimapConfig", GetMinimapConfig)

local function GetMinimapScreenRect()
    local config = GetRuntimeMinimapConfig()
    local minimapRect = config.overlay.minimap
    return GetScreenRect(minimapRect)
end

exports("GetMinimapScreenRect", GetMinimapScreenRect)

local function LoadTextureDict()
    -- Nome do .ytd sem extensao.
    RequestStreamedTextureDict(textureDict, false)

    while not HasStreamedTextureDictLoaded(textureDict) do
        Wait(100)
    end
end

local function ReplaceRadarMasks()
    -- Troca as mascaras pequena e grande pela textura customizada.
    for _, maskName in ipairs(masks) do
        AddReplaceTexture("platform:/textures/graphics", maskName, textureDict, "radarmasksm")
    end
end

local function SetComponentPosition(componentName, rect)
    SetMinimapComponentPosition(componentName, MinimapRaccoConfig.alignX, MinimapRaccoConfig.alignY, rect.x, rect.y, rect.w, rect.h)
end

local function RefreshMinimap()
    local config = GetRuntimeMinimapConfig()

    -- 0 = recorte mais quadrado/retangular; 1 = recorte arredondado/circular.
    SetMinimapClipType(config.clipType)
    SetComponentPosition(components.minimap, config.minimap)
    SetComponentPosition(components.mask, config.mask)
    SetComponentPosition(components.blur, config.blur)

    SetBigmapActive(true, false)
    Wait(500)
    SetBigmapActive(false, false)
end

local debugBlurFrame = false

RegisterCommand("mapraccodebug", function()
    debugBlurFrame = not debugBlurFrame
    print("[minimap-racco] debug blur "..(debugBlurFrame and "ligado" or "desligado"))
end)

RegisterCommand("mapraccosize", function()
    local screenW, screenH = GetScreenResolution()
    local activeW, activeH = GetActiveScreenResolution()
    local aspectFalse = GetAspectRatio and GetAspectRatio(false) or 0.0
    local aspectTrue = GetAspectRatio and GetAspectRatio(true) or 0.0
    local aspectCorrection = GetAspectCorrection()
    local config = GetRuntimeMinimapConfig()

    print(("[minimap-racco] screen=%sx%s active=%sx%s aspect=false %.6f true %.6f correction %.6f fixedSize=%s reference=%sx%s"):format(
        screenW,
        screenH,
        activeW,
        activeH,
        aspectFalse,
        aspectTrue,
        aspectCorrection,
        tostring(MinimapRaccoConfig.fixedSize),
        MinimapRaccoConfig.referenceResolution.width,
        MinimapRaccoConfig.referenceResolution.height
    ))

    for _, name in ipairs({ "minimap", "mask", "blur" }) do
        local rect = config[name]
        local screenRect = GetScreenRect(rect)

        print(("[minimap-racco] %s x=%.6f y=%.6f w=%.6f h=%.6f screen=%.0fx%.0f"):format(
            name,
            rect.x,
            rect.y,
            rect.w,
            rect.h,
            screenRect.w,
            screenRect.h
        ))
    end

    if config.overlay then
        local rect = config.overlay.blur
        local screenRect = GetScreenRect(rect)

        print(("[minimap-racco] overlay.blur x=%.6f y=%.6f w=%.6f h=%.6f screen=%.0fx%.0f"):format(
            rect.x,
            rect.y,
            rect.w,
            rect.h,
            screenRect.w,
            screenRect.h
        ))
    end
end)

CreateThread(function()
    -- Espera o jogo/HUD carregar antes de aplicar a posicao.
    Wait(1000)
    LoadTextureDict()
    ReplaceRadarMasks()
    RefreshMinimap()

    local lastScreenStateKey = GetScreenStateKey()

    while true do
        local screenStateKey = GetScreenStateKey()

        if screenStateKey ~= lastScreenStateKey then
            lastScreenStateKey = screenStateKey
            RefreshMinimap()
        end

        local config = GetRuntimeMinimapConfig()
        SetMinimapClipType(config.clipType)
        SetComponentPosition(components.minimap, config.minimap)
        SetComponentPosition(components.mask, config.mask)
        SetComponentPosition(components.blur, config.blur)
        SetRadarZoom(MinimapRaccoConfig.radarZoom)
        Wait(1000)
    end
end)

local forceTopViewRadar = true

CreateThread(function()
    while true do
        if forceTopViewRadar and IsRadarEnabled() then
            Wait(0)
            DontTiltMinimapThisFrame()
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        if debugBlurFrame then
            local config = GetRuntimeMinimapConfig()
            local rect = config.blur
            local drawX = rect.x + (rect.w / 2)
            local drawY = rect.y + (rect.h / 2)

            DrawRect(drawX, drawY - (rect.h / 2), rect.w, 0.002, 0, 255, 0, 220)
            DrawRect(drawX, drawY + (rect.h / 2), rect.w, 0.002, 0, 255, 0, 220)
            DrawRect(drawX - (rect.w / 2), drawY, 0.002, rect.h, 0, 255, 0, 220)
            DrawRect(drawX + (rect.w / 2), drawY, 0.002, rect.h, 0, 255, 0, 220)
            Wait(0)
        else
            Wait(500)
        end
    end
end)