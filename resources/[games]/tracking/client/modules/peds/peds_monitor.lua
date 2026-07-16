--[[ Controlador genérico de peds com monitor de distância/morte. ]]

local controllers = {}

---@param ped number
local function DeleteTrackedPed(ped)
    if not ped then return end

    TriggerEvent("multiTracking:parachute:trail:remove", ped)

    if DoesEntityExist(ped) then
        local parachuteProp = DecorGetInt(ped, "PED_PROP_PARACHUTE")
        if parachuteProp and DoesEntityExist(parachuteProp) then
            DeleteEntity(parachuteProp)
        end
        SetEntityAsMissionEntity(ped, true, true)
        DeleteEntity(ped)
    end
end

MultiTrackingPedsController = {}
MultiTrackingPedsController.__index = MultiTrackingPedsController

---@param key string
function MultiTrackingPedsController.new(_, key)
    local instance = {
        key = key,
        createdNpcs = {},
        monitorHandler = nil,
        isActiveMonitor = false,
        maxDistance = nil,
    }
    setmetatable(instance, MultiTrackingPedsController)
    return instance
end

---@param distance number
function MultiTrackingPedsController.setMaxDistance(self, distance)
    self.maxDistance = distance
end

---@param handler fun(ped:number):boolean
function MultiTrackingPedsController.setMonitorHandler(self, handler)
    self.monitorHandler = handler
end

---@param ped number
function MultiTrackingPedsController.registerNpc(self, ped)
    if not ped then return end
    self.createdNpcs[ped] = true
end

---@param ped number
function MultiTrackingPedsController.deleteNpc(self, ped)
    if not ped then return end
    self.createdNpcs[ped] = nil
    DeleteTrackedPed(ped)
end

function MultiTrackingPedsController.deleteAll(self)
    for ped, _ in pairs(self.createdNpcs) do
        self:deleteNpc(ped)
    end
end

---@return number
function MultiTrackingPedsController.getTrackedCount(self)
    local count = 0
    for ped, _ in pairs(self.createdNpcs) do
        if ped and DoesEntityExist(ped) then
            count = count + 1
        end
    end
    return count
end

function MultiTrackingPedsController.startMonitor(self)
    if self.isActiveMonitor then return end
    self.isActiveMonitor = true

    CreateThread(function()
        while self.isActiveMonitor do
            if type(IsEnabledMultiTracking) == 'function' and not IsEnabledMultiTracking() then
                self.isActiveMonitor = false
                break
            end

            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local pedsToDelete = {}

            for ped, _ in pairs(self.createdNpcs) do
                local shouldDelete = false

                if not (ped and DoesEntityExist(ped)) then
                    shouldDelete = true
                elseif IsEntityDead(ped) or IsPedDeadOrDying(ped, true) then
                    shouldDelete = true
                elseif type(self.monitorHandler) == "function" then
                    if self.monitorHandler(ped) then
                        shouldDelete = true
                    end
                else
                    local pedCoords = GetEntityCoords(ped)
                    local distance = #(playerCoords.xy - pedCoords.xy)
                    local maxDistance = self.maxDistance or 800.0
                    if distance > maxDistance then
                        shouldDelete = true
                    end
                end

                if shouldDelete then
                    pedsToDelete[#pedsToDelete + 1] = ped
                end
            end

            for i = 1, #pedsToDelete, 1 do
                self:deleteNpc(pedsToDelete[i])
            end

            Wait(50)
        end
    end)
end

function MultiTrackingPedsController.stopMonitor(self)
    self.isActiveMonitor = false
end

---@param key string
---@return table
local function MultiTrackingGetPedsController(key)
    if type(key) ~= "string" or not key then
        key = "default"
    end
    if not controllers[key] then
        controllers[key] = MultiTrackingPedsController.new(MultiTrackingPedsController, key)
    end
    return controllers[key]
end
_G.MultiTrackingGetPedsController = MultiTrackingGetPedsController

---@param ped number
local function MultiTrackingDeleteTrackedPed(ped)
    if not ped then return end
    for _, controller in pairs(controllers) do
        controller.createdNpcs[ped] = nil
    end
    DeleteTrackedPed(ped)
end
_G.MultiTrackingDeleteTrackedPed = MultiTrackingDeleteTrackedPed
