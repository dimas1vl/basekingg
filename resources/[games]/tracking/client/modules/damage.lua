--[[ Damage handler do tracking via thread polling de HP. ]]

local HEAD_BONES = {
    [31086] = true,
    [12844] = true,
}

local KILL_WINDOW_MS = 250

---@class VictimState
---@field hp          number
---@field bone        number
---@field coords      vector3
---@field damagedAtMs number
local victimState = {}

---@return boolean
local function hitmarkerEnabled()
    local cfg = GetGlobalConfigBuilder and GetGlobalConfigBuilder('general')
    if not (cfg and cfg.get) then return true end
    local v = cfg.get('hitmarkerEnabled')
    if v == nil then return true end
    return v == true
end

---@param ped number
local function HandleTrackedNpcKill(ped)
    TriggerServerEvent("multiTracking:server:whenKillNpc")
    TriggerEvent("multiTracking:client:npcKilled", ped)
    MultiTrackingDeleteTrackedPed(ped)
end

local function playKillSoundSafe()
    if GetResourceState('sounds') == 'started' then
        local ok = pcall(function() exports.sounds:playKillSound(true) end)
        if ok then return end
    end
    PlaySoundFrontend(-1, 'Hit_Marker', 'PLAYER_SWITCH_CUSTOM_SOUNDSET', true)
end

---@param coords   vector3
---@param damage   number
---@param lethal   boolean
---@param headshot boolean
local function pushHitmarkerAtCoords(coords, damage, lethal, headshot)
    if damage <= 0 then return end
    if not hitmarkerEnabled() then return end
    if not coords then return end

    local onScreen, sx, sy = World3dToScreen2d(coords.x, coords.y, coords.z + 1.2)
    if not onScreen then return end

    if math.abs(sx - 0.5) < 0.08 and math.abs(sy - 0.5) < 0.10 then
        sy = sy - 0.12
    end

    SendNUIMessage({
        action = 'thitmarker',
        data = {
            x        = sx + (math.random() - 0.5) * 0.03,
            y        = sy,
            damage   = math.floor(damage + 0.5),
            lethal   = lethal,
            headshot = headshot,
        },
    })
end

---@return table<number, boolean>
local function collectTrackedPeds()
    local out = {}

    if type(GetAllTrackingVehiclesInstances) == 'function' then
        local instances = GetAllTrackingVehiclesInstances()
        for _, routeInstances in pairs(instances) do
            for _, inst in pairs(routeInstances) do
                if not inst.destroyed and inst.ped and DoesEntityExist(inst.ped) then
                    out[inst.ped] = true
                end
            end
        end
    end

    if type(MultiTrackingGetPedsController) == 'function' then
        for _, key in ipairs({ 'parachute', 'runner', 'roll', 'area' }) do
            local ctrl = MultiTrackingGetPedsController(key)
            if ctrl and ctrl.createdNpcs then
                for ped in pairs(ctrl.createdNpcs) do
                    if ped and DoesEntityExist(ped) then
                        out[ped] = true
                    end
                end
            end
        end
    end

    return out
end

CreateThread(function()
    while true do
        if IsEnabledMultiTracking and IsEnabledMultiTracking() then
            local tracked = collectTrackedPeds()
            local now = GetGameTimer()

            for ped in pairs(tracked) do
                local curHp = GetEntityHealth(ped)
                local coords = GetEntityCoords(ped)
                local _, bone = GetPedLastDamageBone(ped)
                local prev = victimState[ped]

                if prev == nil then
                    victimState[ped] = { hp = curHp, bone = bone, coords = coords, damagedAtMs = 0 }
                elseif curHp < prev.hp then
                    local damage = prev.hp - curHp
                    local isHeadshot = HEAD_BONES[bone] or false
                    local isDead = IsEntityDead(ped) or curHp <= 0

                    pushHitmarkerAtCoords(coords, damage, isDead, isHeadshot)

                    if isHeadshot then
                        playKillSoundSafe()
                    else
                        TriggerEvent("hitDamage:extra:whenDamage", ped)
                    end

                    if isDead then
                        TriggerEvent("kill:client:confirmKillEvent")
                        victimState[ped] = nil
                        HandleTrackedNpcKill(ped)
                    else
                        victimState[ped] = {
                            hp = curHp, bone = bone, coords = coords, damagedAtMs = now,
                        }
                    end
                else
                    prev.coords = coords
                    prev.bone = bone
                end
            end

            for ped, state in pairs(victimState) do
                if not tracked[ped] then
                    if state.damagedAtMs > 0 and (now - state.damagedAtMs) <= KILL_WINDOW_MS then
                        local isHeadshot = HEAD_BONES[state.bone] or false
                        pushHitmarkerAtCoords(state.coords, state.hp, true, isHeadshot)
                    end
                    victimState[ped] = nil
                end
            end
        end
        Wait(0)
    end
end)

AddEventHandler('multiTracking:whenLeave', function()
    victimState = {}
end)
