--[[ Modo "roll": utilitarios de animacao roll - checagem e thread de inicio assincrono. ]]

local function isPlayingRollAnimation(ped, zoneConfig)
    if not (ped and DoesEntityExist(ped)) then
        return false
    end

    local animations = (zoneConfig and zoneConfig.animations) or {}

    for animDict, animNames in pairs(animations) do
        if type(animDict) == "string" and type(animNames) == "table" then
            for i = 1, #animNames do
                if IsEntityPlayingAnim(ped, animDict, animNames[i], 3) then
                    return true
                end
            end
        end
    end

    return false
end
IsPlayingRollAnimation = isPlayingRollAnimation

local function startRollAnimationThread(ped, zoneKey, pedsRegistry, zonesConfig)
    Citizen.CreateThread(function()
        if not (ped and DoesEntityExist(ped)) then return end

        local info = pedsRegistry[ped]
        if not info then return end

        local zoneConfig
        if zonesConfig.zones then
            zoneConfig = zonesConfig.zones[zoneKey]
        end

        if not zoneConfig then
            info.rollFinishedAtMs = GetGameTimer()
            return
        end

        info.rollStartedAtMs = GetGameTimer()

        local played = PlayRollAnimation(ped, zoneConfig)
        info.didPlayRoll = (played == true)

        if not played then
            info.rollStartedAtMs = nil
            info.rollFinishedAtMs = GetGameTimer()
        end
    end)
end
StartRollAnimationThread = startRollAnimationThread
