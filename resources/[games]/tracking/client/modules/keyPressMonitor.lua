--[[ Monitor de inputs do modo: navegacao entre spawn zones (setas),
     toggle de aim-roll e teleporte aleatorio para spawn ponto. ]]

local isMonitorActive = false
local spawnZones = MultitrackingSpawnZones or {}
local currentZoneIndex = 0

local function GetSpawnPointForZone(zoneIndex)
    local zone = spawnZones[zoneIndex]
    if not zone then
        return nil
    end

    local spawns = zone.spawns
    if type(spawns) == "table" and #spawns > 0 then
        math.randomseed(GetGameTimer())
        return spawns[math.random(1, #spawns)]
    end

    return zone.centerZoneCds
end

local function TeleportPlayerToCoords(coords)
    if not coords then
        return
    end

    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    FreezeEntityPosition(ped, true)

    local attempts = 0
    while not HasCollisionLoadedAroundEntity(ped) and attempts < 80 do
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        Wait(100)
        attempts = attempts + 1
    end

    -- Always unfreeze after teleport — never restore prior frozen state
    -- (the lobby leaves the ped frozen, and we want the player to move here).
    FreezeEntityPosition(ped, false)
end

local function CycleSpawnZone(direction)
    if #spawnZones == 0 then
        return
    end

    currentZoneIndex = currentZoneIndex + direction
    if currentZoneIndex > #spawnZones then
        currentZoneIndex = 1
    end
    if currentZoneIndex < 1 then
        currentZoneIndex = #spawnZones
    end

    local spawnPoint = GetSpawnPointForZone(currentZoneIndex)
    if not spawnPoint then
        return
    end

    TeleportPlayerToCoords(spawnPoint)
end

local function GoToSpawnZoneByName(zoneName)
    for index, zone in ipairs(spawnZones) do
        if zone.name == zoneName then
            currentZoneIndex = index
            local spawnPoint = GetSpawnPointForZone(index)
            if spawnPoint then
                TeleportPlayerToCoords(spawnPoint)
            end
            return
        end
    end
end

AddEventHandler("multiTracking:keyPressMonitor:client:start", function()
    if isMonitorActive then
        return
    end
    isMonitorActive = true

    while isMonitorActive do
        local rightPressed = IsDisabledControlPressed(1, 175)
        local leftPressed = IsDisabledControlPressed(1, 174)
        local homePressed = IsDisabledControlPressed(1, 173)
        local toggleAimRoll = IsDisabledControlJustPressed(1, 305)

        if rightPressed then
            TriggerEvent("multiTracking:keyPressMonitor:client:right")
            Wait(400)
        elseif leftPressed then
            TriggerEvent("multiTracking:keyPressMonitor:client:left")
            Wait(400)
        elseif homePressed then
            TriggerEvent("multiTracking:keyPressMonitor:client:home")
            Wait(400)
        elseif toggleAimRoll then
            TriggerEvent("multiTracking:keyPressMonitor:client:toggleAimRoll")
            Wait(1000)
        end
        Wait(0)
    end
end)

AddEventHandler("multiTracking:keyPressMonitor:client:stop", function()
    isMonitorActive = false
end)

AddEventHandler("multiTracking:keyPressMonitor:client:home", function()
    if not IsEnabledMultiTracking() then
        return
    end
    GoToSpawnZoneByName("zancudo")
end)

AddEventHandler("multiTracking:keyPressMonitor:client:right", function()
    if not IsEnabledMultiTracking() then
        return
    end
    CycleSpawnZone(1)
end)

AddEventHandler("multiTracking:keyPressMonitor:client:left", function()
    if not IsEnabledMultiTracking() then
        return
    end
    CycleSpawnZone(-1)
end)

AddEventHandler("multiTracking:keyPressMonitor:client:toggleAimRoll", function()
    if not IsEnabledMultiTracking() then
        return
    end

    local builder = GetGlobalConfigBuilder("runner")
    if not builder then
        return
    end

    local enabled = builder.get("aimRollEnabled") or false
    local newValue = not enabled
    builder.set("aimRollEnabled", newValue)

    local statusText = newValue and "Ativado" or "Desativado"
    TriggerEvent("Notify", "info", "Rolamento ao Mirar: " .. statusText)
end)

AddEventHandler("multiTracking:randomSpawnPlayer", function()
    if not IsEnabledMultiTracking() then
        return
    end
    if #spawnZones == 0 then
        return
    end

    math.randomseed(GetGameTimer())
    local randomIndex = math.random(1, #spawnZones)
    currentZoneIndex = randomIndex

    local spawnPoint = GetSpawnPointForZone(randomIndex)
    if not spawnPoint then
        return
    end

    TeleportPlayerToCoords(spawnPoint)
end)
