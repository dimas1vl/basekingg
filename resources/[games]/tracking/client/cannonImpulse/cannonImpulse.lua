--[[ Gerenciamento das instancias do canhao de impulso:
     spawn nas posicoes padrao, loop de proximidade e cleanup. ]]

local cannonEnabled = GetConvarBool("multiTrackingCannonImpulseEnabled", true)
local proximityThreadRunning = false
local instances = {}
local idCounter = 0

local function nextInstanceId()
    idCounter = idCounter + 1
    if idCounter > 10000 then
        idCounter = 1
    end
    return idCounter
end

local function createInstance(cdsProp, rotationProp)
    local instance = CannonImpulse:new(cdsProp, rotationProp)
    local id = tostring(nextInstanceId())
    instances[id] = instance
    return instance, id
end

local function startProximityThread()
    proximityThreadRunning = true
    Citizen.CreateThread(function()
        while true do
            if not proximityThreadRunning then break end

            local wait = 1000
            for _, instance in pairs(instances) do
                if instance:processProximityTick() then
                    wait = 0
                end
            end
            Wait(wait)
        end
    end)
end

local function deleteAllCannonImpulseInstances()
    for id, instance in pairs(instances) do
        instance:cleanup()
        instance:stop()
        instances[id] = nil
    end
    instances = {}
    proximityThreadRunning = false
    idCounter = 0
end
DeleteAllCannonImpulseInstances = deleteAllCannonImpulseInstances

local function spawnAll()
    if not cannonEnabled then return end

    for _, entry in ipairs(CannonInpulseConfig.defaultPositions) do
        createInstance(entry.cdsProp, entry.rotationProp)
    end

    startProximityThread()
end

AddEventHandler("multiTracking:whenEnter", function()
    spawnAll()
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    DeleteAllCannonImpulseInstances()
end)

AddConvarChangeListener("multiTrackingCannonImpulseEnabled", function()
    if not IsEnabledMultiTracking() then return end

    cannonEnabled = GetConvarBool("multiTrackingCannonImpulseEnabled", true)
    if not cannonEnabled then
        DeleteAllCannonImpulseInstances()
    else
        spawnAll()
    end
end)
