local active = false
local killerSrc = nil
local watchSeq = 0
local pinnedInterior = nil

local function grayscale(on)
    if not (Config.Domination.killcam and Config.Domination.killcam.grayscale) then return end
    if on then
        SetTimecycleModifier('NG_deathfail_BW_base')
        SetTimecycleModifierStrength(1.0)
    else
        ClearTimecycleModifier()
    end
end

---@param ped number
local function specOff(ped)
    NetworkSetInSpectatorMode(false, ped)
    SetMinimapInSpectatorMode(false, ped)
end

function stopKillcam()
    if not active then return end
    active = false
    watchSeq = watchSeq + 1
    killerSrc = nil
    grayscale(false)
    specOff(PlayerPedId())
    if pinnedInterior then
        UnpinInterior(pinnedInterior)
        pinnedInterior = nil
    end
    TriggerServerEvent('domination:spectate', false)
end

---@param killerPed number
local function killerGone(killerPed)
    return killerPed == 0
        or not DoesEntityExist(killerPed)
        or IsEntityDead(killerPed)
        or IsPedDeadOrDying(killerPed, true)
end

---@param srcId number|string|nil
function startKillcam(srcId)
    srcId = tonumber(srcId)
    if not srcId then return end
    if not (Config.Domination.killcam and Config.Domination.killcam.enabled) then return end

    if active then stopKillcam() end
    active = true
    killerSrc = srcId
    watchSeq = watchSeq + 1
    local mySeq = watchSeq

    TriggerServerEvent('domination:spectate', killerSrc)

    CreateThread(function()
        local pid = -1
        local deadline = GetGameTimer() + 1500
        repeat
            pid = GetPlayerFromServerId(killerSrc)
            if pid ~= -1 and DoesEntityExist(GetPlayerPed(pid)) then break end
            Wait(50)
        until GetGameTimer() > deadline or mySeq ~= watchSeq or not active

        if mySeq ~= watchSeq or not active then return end

        local killerPed = (pid ~= -1) and GetPlayerPed(pid) or 0
        if killerGone(killerPed) then
            stopKillcam()
            return
        end

        local kpos = GetEntityCoords(killerPed)
        local interior = GetInteriorAtCoords(kpos.x, kpos.y, kpos.z)
        if interior ~= 0 then
            pinnedInterior = interior
            PinInteriorInMemory(interior)
        end

        SetMinimapInSpectatorMode(true, killerPed)
        NetworkSetInSpectatorMode(true, killerPed)
        grayscale(true)

        while active and mySeq == watchSeq and domDowned and Zone.active do
            local p = GetPlayerFromServerId(killerSrc)
            local kp = (p ~= -1) and GetPlayerPed(p) or 0
            if killerGone(kp) then
                stopKillcam()
                return
            end
            NetworkSetInSpectatorMode(true, kp)
            Wait(200)
        end

        stopKillcam()
    end)
end

RegisterNetEvent('domination:killcam:stop', function()
    stopKillcam()
end)
