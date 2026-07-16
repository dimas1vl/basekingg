local Observer = Game.module('observer')

local active = false
local targets = {}
local targetIdx = 0
local currentSrc = nil

function Observer:setup(ctx)
    active = false
    targets = {}
    targetIdx = 0
    currentSrc = nil
end

function Observer:teardown(ctx)
    self:stop()
end

function Observer:stop()
    if not active then return end
    active = false
    NetworkSetInSpectatorMode(false, PlayerPedId())
    SetMinimapInSpectatorMode(false, PlayerPedId())
    targets = {}
    targetIdx = 0
    currentSrc = nil
end

function Observer:watch(src)
    local pid = GetPlayerFromServerId(src)
    if pid == -1 then return false end
    local ped = GetPlayerPed(pid)
    if not DoesEntityExist(ped) then return false end

    local pos = GetEntityCoords(ped)
    local interior = GetInteriorAtCoords(pos.x, pos.y, pos.z)
    if interior ~= 0 then
        PinInteriorInMemory(interior)
    end

    SetMinimapInSpectatorMode(true, ped)
    NetworkSetInSpectatorMode(true, ped)

    currentSrc = src
    return true
end

function Observer:cycle(dir)
    if #targets == 0 then return end
    local tries = 0
    repeat
        targetIdx = targetIdx + dir
        if targetIdx > #targets then targetIdx = 1
        elseif targetIdx < 1 then targetIdx = #targets end
        tries = tries + 1
    until self:watch(targets[targetIdx]) or tries >= #targets
end

Game.session:onNet('spectator.init', function(alivePlayers)
    if active then return end
    active = true
    targets = alivePlayers or {}
    targetIdx = 0

    if #targets > 0 then
        Observer:cycle(1)
    end

    CreateThread(function()
        while active do
            Wait(0)

            if IsControlJustPressed(0, 174) then
                Observer:cycle(-1)
            end
            if IsControlJustPressed(0, 175) then
                Observer:cycle(1)
            end

            for key = 1, math.min(9, #Game.session.squad) do
                if IsControlJustPressed(0, 156 + key) then
                    local src = Game.session.squad[key]
                    for i, t in ipairs(targets) do
                        if t == src then
                            targetIdx = i
                            Observer:watch(src)
                            break
                        end
                    end
                end
            end

            if currentSrc then
                local pid = GetPlayerFromServerId(currentSrc)
                local name = (Game.session.names and Game.session.names[currentSrc]) or ((pid ~= -1) and GetPlayerName(pid)) or ('Player %d'):format(currentSrc)
                local hp, arm = 0, 0

                if pid ~= -1 then
                    local ped = GetPlayerPed(pid)
                    if DoesEntityExist(ped) then
                        hp = math.max(0, GetEntityHealth(ped) - 100)
                        arm = GetPedArmour(ped)
                    end
                end

                SetTextFont(4)
                SetTextScale(0.0, 0.4)
                SetTextColour(255, 255, 255, 220)
                SetTextCentre(true)
                SetTextDropshadow(1, 0, 0, 0, 255)
                SetTextEdge(1, 0, 0, 0, 255)
                SetTextOutline()
                SetTextEntry('STRING')
                AddTextComponentString(('SPECTATING: %s  HP: %d  ARM: %d'):format(name, hp, arm))
                DrawText(0.5, 0.93)

                SetTextFont(4)
                SetTextScale(0.0, 0.28)
                SetTextColour(200, 200, 200, 180)
                SetTextCentre(true)
                SetTextEntry('STRING')
                AddTextComponentString('[LEFT/RIGHT] Trocar  [1-9] Squad')
                DrawText(0.5, 0.96)
            end
        end
    end)
end)

Game.session:onNet('playerState.update', function(src, newState)
    if not active then return end
    if newState == PlayerState.DEAD or newState == PlayerState.SPECTATING then
        for i = #targets, 1, -1 do
            if targets[i] == src then
                table.remove(targets, i)
                break
            end
        end
        if currentSrc == src then
            if #targets > 0 then
                targetIdx = math.min(targetIdx, #targets)
                Observer:cycle(1)
            else
                Observer:stop()
            end
        end
    end
end)
