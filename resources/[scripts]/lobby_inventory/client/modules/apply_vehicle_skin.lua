-- apply_vehicle_skin.lua
-- Vehicle skin propagated to all clients via stateBag ('inventario_skin').
-- Slot key for equipped is the vehicle model hash as STRING (e.g. "kuruma" or numeric hash string).

---@param vehicle number
---@param payload table   -- { livery, primary_color, secondary_color, mod_kit, wheel_type }
local function applyVehicleSkinPayload(vehicle, payload)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) or not payload then return end

    if payload.mod_kit ~= nil then
        SetVehicleModKit(vehicle, tonumber(payload.mod_kit) or 0)
    end

    if payload.primary_color ~= nil or payload.secondary_color ~= nil then
        local cur1, cur2 = GetVehicleColours(vehicle)
        SetVehicleColours(vehicle,
            tonumber(payload.primary_color)   or cur1 or 0,
            tonumber(payload.secondary_color) or cur2 or 0)
    end

    if payload.livery ~= nil then
        local liv = tonumber(payload.livery) or 0
        SetVehicleLivery(vehicle, liv)
        -- Some vehicles use modLivery (mod slot 48) instead of native livery.
        if GetVehicleLivery(vehicle) == -1 then
            SetVehicleMod(vehicle, 48, liv, false)
        end
    end

    if payload.wheel_type ~= nil then
        SetVehicleWheelType(vehicle, tonumber(payload.wheel_type) or 0)
    end
end

---@param vehicle number
---@return table | nil
local function getEquippedSkinForVehicle(vehicle)
    if not vehicle or vehicle == 0 then return nil end
    local model = GetEntityModel(vehicle)
    local equipped = Inventario.equipped.vehicle_skin
    if not equipped then return nil end

    for slotKey, item in pairs(equipped) do
        if item and item.metadata then
            local vm = item.metadata.vehicle_model
            local slotHash
            if type(slotKey) == 'number' then
                slotHash = slotKey
            else
                slotHash = tonumber(slotKey) or GetHashKey(slotKey)
            end
            local metaHash = vm and (type(vm) == 'number' and vm or GetHashKey(vm)) or nil
            if slotHash == model or metaHash == model then
                return item
            end
        end
    end
    return nil
end

---@param item table
---@return table
local function metadataToPayload(item)
    local m = item.metadata or {}
    return {
        livery          = m.livery,
        primary_color   = m.primary_color,
        secondary_color = m.secondary_color,
        mod_kit         = m.mod_kit,
        wheel_type      = m.wheel_type,
    }
end

-- Driver-side: when the local player enters a vehicle as driver, publish the
-- skin payload to the entity stateBag (replicated → other clients pick it up).
RegisterNetEvent('kingg:player:vehicleEntered', function(vehEntity)
    if not vehEntity or vehEntity == 0 or not DoesEntityExist(vehEntity) then return end

    local ped = PlayerPedId()
    if GetPedInVehicleSeat(vehEntity, -1) ~= ped then return end

    local item = getEquippedSkinForVehicle(vehEntity)
    if not item then return end

    -- Try to take network control (retry briefly).
    if NetworkGetEntityIsNetworked(vehEntity) then
        local netId = NetworkGetNetworkIdFromEntity(vehEntity)
        if netId and netId ~= 0 then
            local deadline = GetGameTimer() + 1500
            while not NetworkHasControlOfEntity(vehEntity) and GetGameTimer() < deadline do
                NetworkRequestControlOfEntity(vehEntity)
                Wait(50)
            end
        end
    end

    local payload = metadataToPayload(item)

    -- Local apply (immediate feedback even if stateBag latency).
    applyVehicleSkinPayload(vehEntity, payload)

    -- Replicate via stateBag for everyone else.
    local ok, err = pcall(function()
        Entity(vehEntity).state:set('inventario_skin', payload, true)
    end)
    if not ok then
        print(('[inventario] failed to set vehicle stateBag: %s'):format(tostring(err)))
    end
end)

-- Receiver side: apply skin whenever a vehicle's stateBag changes.
AddStateBagChangeHandler('inventario_skin', nil, function(bagName, _, value)
    if not value then return end
    local netIdStr = bagName:match('entity:(%d+)')
    if not netIdStr then return end
    local netId = tonumber(netIdStr)
    if not netId then return end

    CreateThread(function()
        local deadline = GetGameTimer() + 5000
        while GetGameTimer() < deadline do
            if NetworkDoesEntityExistWithNetworkId(netId) then
                local veh = NetworkGetEntityFromNetworkId(netId)
                if veh and veh ~= 0 and DoesEntityExist(veh) then
                    applyVehicleSkinPayload(veh, value)
                    return
                end
            end
            Wait(150)
        end
    end)
end)
