--[[ Gerencia blips extras configurados em MultitrackingExtraBlipsMap.
     Cria/destroi de acordo com eventos de entrada/saida do modo. ]]

local resourceName = GetCurrentResourceName()

local baseBlipsColor = GetConvarInt("baseBlipsColor", 0)
if not (baseBlipsColor and baseBlipsColor > 0) then
    baseBlipsColor = 46
end

local createdBlips = {}

local function CreateExtraBlip(blipId, blipData)
    if not (blipId and type(blipData) == "table") then
        return
    end

    if createdBlips[blipId] then
        return
    end

    local coords = blipData.coords
    if not coords then
        return
    end

    local blip = AddBlipForCoord(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    if not blip or blip == 0 then
        return
    end

    local sprite = tonumber(blipData.sprite) or 477
    local color = tonumber(blipData.color) or baseBlipsColor
    local scale = tonumber(blipData.scale) or 0.7
    local display = tonumber(blipData.display) or 2
    local shortRange = blipData.shortRange == true
    local name = blipData.name or tostring(blipId)
    local showCone = blipData.showCone ~= false
    local secondaryColor = blipData.secondaryColor or {r = 255, g = 255, b = 255}
    local showOutlineIndicator = blipData.showOutlineIndicator == true

    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipScale(blip, scale)
    SetBlipDisplay(blip, display)
    SetBlipAsShortRange(blip, shortRange)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)
    SetBlipShowCone(blip, showCone)
    SetBlipSecondaryColour(blip, secondaryColor.r, secondaryColor.g, secondaryColor.b)
    ShowOutlineIndicatorOnBlip(blip, showOutlineIndicator)

    createdBlips[blipId] = blip
end

local function CreateAllExtraBlips()
    if not IsSpawnBlipsEnabled() then
        return
    end

    local blipsMap = MultitrackingExtraBlipsMap or {}
    if type(blipsMap) ~= "table" then
        return
    end

    for blipId, blipData in pairs(blipsMap) do
        CreateExtraBlip(blipId, blipData)
    end
end
_G.CreateAllExtraBlips = CreateAllExtraBlips

local function RemoveAllExtraBlips()
    for blipId, blip in pairs(createdBlips) do
        if blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
        createdBlips[blipId] = nil
    end
end

AddEventHandler("multiTracking:whenEnter", CreateAllExtraBlips)
AddEventHandler("multiTracking:whenLeave", RemoveAllExtraBlips)

AddEventHandler("multiTracking:spawnBlips:changed", function(enabled)
    if not IsEnabledMultiTracking() then
        return
    end
    if enabled then
        CreateAllExtraBlips()
    else
        RemoveAllExtraBlips()
    end
end)

AddEventHandler("onResourceStop", function(stoppedResource)
    if stoppedResource ~= resourceName then
        return
    end
    RemoveAllExtraBlips()
end)
