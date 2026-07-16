--[[ Cria e remove blips fixos no mapa para cada rota configurada. ]]

local resourceName = GetCurrentResourceName()
local baseBlipsColor = GetConvarInt("baseBlipsColor", 0)
local defaultBlipColor = baseBlipsColor
if not (baseBlipsColor and baseBlipsColor > 0) or not baseBlipsColor then
    defaultBlipColor = 46
end

local routeBlips = {}

local function createRouteBlip(routeKey, route)
    if not routeKey or not route then
        return
    end
    local blipConfig = route.routeBlipConfig
    if type(blipConfig) ~= "table" then
        return
    end
    local coords = blipConfig.coords
    if not coords then
        return
    end

    local sprite = tonumber(blipConfig.sprite) or 477
    local color = tonumber(blipConfig.color) or defaultBlipColor
    local scale = tonumber(blipConfig.scale) or 0.7
    local display = tonumber(blipConfig.display) or 2
    local shortRange = blipConfig.shortRange == true
    local name = blipConfig.name or route.label or tostring(routeKey)
    local showCone = blipConfig.showCone ~= false
    local secondaryColor = blipConfig.secondaryColor or {r = 255, g = 255, b = 255}
    local showOutlineIndicator = blipConfig.showOutlineIndicator and true or false

    local blip = AddBlipForCoord(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    if not blip or blip == 0 then
        return
    end

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

    routeBlips[routeKey] = blip
end

local function CreateAllVehicleRouteBlips()
    if not IsSpawnBlipsEnabled() then
        return
    end
    local routes = (MultitrackingModeVehicleRoutes and MultitrackingModeVehicleRoutes.routes) or {}
    if type(routes) ~= "table" then
        return
    end
    for routeKey, route in pairs(routes) do
        createRouteBlip(routeKey, route)
    end
end

_G.CreateAllVehicleRouteBlips = CreateAllVehicleRouteBlips

local function removeAllRouteBlips()
    for routeKey, blip in pairs(routeBlips) do
        if blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
        routeBlips[routeKey] = nil
    end
end

AddEventHandler("multiTracking:whenLeave", removeAllRouteBlips)

AddEventHandler("multiTracking:spawnBlips:changed", function(enabled)
    if not IsEnabledMultiTracking() then
        return
    end
    if enabled then
        CreateAllVehicleRouteBlips()
    else
        removeAllRouteBlips()
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= resourceName then
        return
    end
    removeAllRouteBlips()
end)
