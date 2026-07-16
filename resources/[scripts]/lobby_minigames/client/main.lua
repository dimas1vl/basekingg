---@class LobbyMinigames
---@field active boolean
---@field npcs table<integer, { ped: number, data: table }>
---@field nearest { ped: number, data: table } | nil
---@field waitingRoom { roomId: string, mode: string, map: string, variant: string|nil, current: number, max: number, owner: string } | nil
LobbyMinigames = LobbyMinigames or {}
LobbyMinigames.active      = false
LobbyMinigames.npcs        = {}
LobbyMinigames.nearest     = nil
LobbyMinigames.waitingRoom = nil

local function waitForScreenFadedOut(ms)
    local deadline = GetGameTimer() + (ms or 1500)
    while not IsScreenFadedOut() and GetGameTimer() < deadline do
        Wait(0)
    end
end

local function loadModel(model)
    local hash = type(model) == 'string' and GetHashKey(model) or model
    if HasModelLoaded(hash) then return hash end
    RequestModel(hash)
    local attempts = 0
    while not HasModelLoaded(hash) and attempts < 100 do
        attempts = attempts + 1
        Wait(50)
    end
    return HasModelLoaded(hash) and hash or nil
end

local function teleportToSpawn(spawn)
    if not spawn or not spawn.coords then return end
    local ped = PlayerPedId()
    local c   = spawn.coords

    if IsEntityDead(ped) then
        NetworkResurrectLocalPlayer(c.x, c.y, c.z, spawn.heading or 0.0, true, false)
        ped = PlayerPedId()
    end

    RequestCollisionAtCoord(c.x, c.y, c.z)
    SetEntityCoordsNoOffset(ped, c.x, c.y, c.z, false, false, false)
    SetEntityHeading(ped, spawn.heading or 0.0)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100)
    RemoveAllPedWeapons(ped, true)

    local waited = 0
    while not HasCollisionLoadedAroundEntity(ped) and waited < 100 do
        Wait(50)
        waited = waited + 1
    end

    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
end

local function spawnNpc(npcData)
    local hash = loadModel(npcData.model)
    if not hash then
        print(('^3[lobby_minigames] failed to load model %s^7'):format(tostring(npcData.model)))
        return nil
    end

    local c   = npcData.coords
    local ped = CreatePed(4, hash, c.x, c.y, c.z - 1.0, c.w or 0.0, false, false)

    local attempts = 0
    while not DoesEntityExist(ped) and attempts < 30 do
        attempts = attempts + 1
        Wait(50)
    end
    if not DoesEntityExist(ped) then return nil end

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 17, true)
    SetPedDiesWhenInjured(ped, false)
    SetEntityAsMissionEntity(ped, true, false)
    SetModelAsNoLongerNeeded(hash)

    return ped
end

local function despawnNpcs()
    for i = 1, #LobbyMinigames.npcs do
        local e = LobbyMinigames.npcs[i]
        if e.ped and DoesEntityExist(e.ped) then
            DeleteEntity(e.ped)
        end
    end
    LobbyMinigames.npcs    = {}
    LobbyMinigames.nearest = nil
end

local NPC_BLIP_RANGE = 40.0

local hudThreadId = 0

local MODE_ID_TO_UI = {
    clutch    = 'clutch',
    gang      = 'gang',
    predio    = 'predios',
    dominacao = 'dominacao',
}
local currentUIMode = nil

local LEAVE_HOLD_MS    = 2000
local leaveHoldActive  = false
local leaveHoldThread  = 0

local function sendHudUpdate()
    local ped   = PlayerPedId()
    local hp    = math.max(0, GetEntityHealth(ped) - 100)
    local hpMax = GetEntityMaxHealth(ped) - 100
    if hpMax <= 0 then hpMax = 100 end
    local armor = GetPedArmour(ped)

    SendNUIMessage({
        action = 'lobby_minigames:hud:update',
        data = {
            hp       = hp,
            hpMax    = hpMax,
            armor    = armor,
            armorMax = 100,
        },
    })
end

local function startHudThread()
    hudThreadId = hudThreadId + 1
    local myId = hudThreadId
    CreateThread(function()
        while LobbyMinigames.active and myId == hudThreadId do
            sendHudUpdate()
            Wait(250)
        end
    end)
end

---@param data { spawn: { coords: vector3, heading: number }, npcs: table[] }
RegisterNetEvent('lobby_minigames:enter', function(data)
    if LobbyMinigames.active then return end

    pcall(function() exports.lobby:closeLobby() end)

    DoScreenFadeOut(400)
    waitForScreenFadedOut(600)

    teleportToSpawn(data and data.spawn)

    LobbyMinigames.active = true

    despawnNpcs()
    local list = (data and data.npcs) or {}
    for i = 1, #list do
        local ped = spawnNpc(list[i])
        if ped then
            LobbyMinigames.npcs[#LobbyMinigames.npcs + 1] = { ped = ped, data = list[i] }
        end
    end

    SendNUIMessage({ action = 'lobby_minigames:hud:visible', data = { visible = true } })
    startHudThread()

    Wait(500)
    DoScreenFadeIn(800)
end)

RegisterNetEvent('lobby_minigames:handover', function()
    LobbyMinigames.active      = false
    LobbyMinigames.nearest     = nil
    LobbyMinigames.waitingRoom = nil
    despawnNpcs()

    if leaveHoldActive then
        leaveHoldActive = false
        SendNUIMessage({ action = 'lobby_minigames:leaveHold', data = { visible = false, percent = 0 } })
    end

    SendNUIMessage({ action = 'lobby_minigames:hud:visible', data = { visible = false } })
    SendNUIMessage({ action = 'lobby_minigames:room:closed', data = { reason = 'handover' } })
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    currentUIMode = nil
end)

RegisterNetEvent('lobby_minigames:leave', function()
    LobbyMinigames.active      = false
    LobbyMinigames.nearest     = nil
    LobbyMinigames.waitingRoom = nil
    despawnNpcs()

    SendNUIMessage({ action = 'lobby_minigames:hud:visible', data = { visible = false } })

    local ped = PlayerPedId()
    RemoveAllPedWeapons(ped, true)
    SetEntityInvincible(ped, false)

    DoScreenFadeOut(300)
    waitForScreenFadedOut(500)

    local ok = pcall(function() exports.lobby:displayLobby() end)
    if not ok then
        DoScreenFadeIn(600)
    end
end)

CreateThread(function()
    local lastEmpty = false
    while true do
        if LobbyMinigames.active and #LobbyMinigames.npcs > 0 then
            local pcoords = GetEntityCoords(PlayerPedId())
            local nearest, nearestDist = nil, math.huge
            local blips = {}

            for i = 1, #LobbyMinigames.npcs do
                local entry = LobbyMinigames.npcs[i]
                if entry.ped and DoesEntityExist(entry.ped) then
                    local nc = GetEntityCoords(entry.ped)
                    local d  = #(pcoords - nc)
                    local interactDist = entry.data.interactDist or 3.0

                    if d <= interactDist and d < nearestDist then
                        nearest, nearestDist = entry, d
                    end

                    if d <= NPC_BLIP_RANGE then
                        local onScreen, sx, sy = World3dToScreen2d(nc.x, nc.y, nc.z + 1.15)
                        if onScreen then
                            blips[#blips + 1] = {
                                id           = i,
                                modeId       = entry.data.modeId,
                                label        = entry.data.label or entry.data.modeId,
                                promptKey    = entry.data.promptKey or 'E',
                                sx           = sx,
                                sy           = sy,
                                distance     = d,
                                interactable = d <= interactDist,
                            }
                        end
                    end
                end
            end

            LobbyMinigames.nearest = nearest
            SendNUIMessage({ action = 'lobby_minigames:npcs:update', data = blips })
            lastEmpty = false
            Wait(0)
        else
            LobbyMinigames.nearest = nil
            if not lastEmpty then
                SendNUIMessage({ action = 'lobby_minigames:npcs:update', data = {} })
                lastEmpty = true
            end
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        if LobbyMinigames.active then
            local ped = PlayerPedId()
            SetEntityInvincible(ped, true)
            SetPlayerInvincible(PlayerId(), true)
            SetPlayerCanDoDriveBy(PlayerId(), false)
            NetworkSetFriendlyFireOption(false)
            SetCanAttackFriendly(ped, false, false)
            if IsEntityDead(ped) then
                local s = Config.LobbyMinigames and Config.LobbyMinigames.spawn
                if s then
                    NetworkResurrectLocalPlayer(s.coords.x, s.coords.y, s.coords.z, s.heading or 0.0, true, false)
                end
            end
            SetEntityHealth(ped, GetEntityMaxHealth(ped))
            if GetPedArmour(ped) < 100 then SetPedArmour(ped, 100) end
            if GetSelectedPedWeapon(ped) ~= GetHashKey('WEAPON_UNARMED') then
                RemoveAllPedWeapons(ped, true)
            end
            Wait(500)
        else
            Wait(1500)
        end
    end
end)

CreateThread(function()
    while true do
        if LobbyMinigames.active then
            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 24,  true)
            DisableControlAction(0, 25,  true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 263, true)
            DisableControlAction(0, 264, true)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

local function openMinigamesUI(modeId)
    local uiMode = MODE_ID_TO_UI[modeId] or modeId
    currentUIMode = uiMode
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'show-mode', data = { mode = uiMode } })
end

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    currentUIMode = nil
    cb({ ok = true })
end)

RegisterNUICallback('minigames:getRooms', function(data, cb)
    local mode = (data and data.gameMode) or currentUIMode or 'gang'
    currentUIMode = mode
    TriggerServerEvent('lobby_minigames:rooms:list', mode)
    cb({})
end)

RegisterNetEvent('lobby_minigames:rooms:list', function(mode, rooms)
    SendNUIMessage({ action = 'minigames:setRooms', data = rooms or {} })
end)

RegisterNUICallback('minigames:joinRoom', function(data, cb)
    local roomId = data and data.roomId
    local password = data and data.password
    if not roomId then
        cb({ ok = false })
        return
    end
    TriggerServerEvent('lobby_minigames:rooms:join', roomId, password)
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    currentUIMode = nil
    cb({ ok = true })
end)

RegisterNetEvent('lobby_minigames:players:total', function(total)
    SendNUIMessage({ action = 'minigames:setTotalPlayers', data = tonumber(total) or 0 })
end)

RegisterNUICallback('minigames:createRoom', function(data, cb)
    local payload = type(data) == 'table' and data or {}
    if not payload.gameMode and currentUIMode then
        payload.gameMode = currentUIMode
    end
    TriggerServerEvent('lobby_minigames:rooms:create', payload)
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    currentUIMode = nil
    cb({ ok = true })
end)

RegisterNetEvent('lobby_minigames:rooms:waiting', function(payload)
    if type(payload) == 'table' and payload.roomId then
        LobbyMinigames.waitingRoom = payload
    end
    SendNUIMessage({ action = 'lobby_minigames:room:waiting', data = payload or {} })
end)

RegisterNetEvent('lobby_minigames:rooms:closed', function(payload)
    LobbyMinigames.waitingRoom = nil
    SendNUIMessage({ action = 'lobby_minigames:room:closed', data = payload or {} })
end)

local function openSafeZoneSelector()
    local zones
    local ok, result = pcall(function() return exports.domination:getSafeZones() end)
    if ok and type(result) == 'table' then zones = result else zones = {} end
    local list = {}
    for i = 1, #zones do
        list[#list + 1] = { id = zones[i].id, label = zones[i].label }
    end
    currentUIMode = 'safezone'
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'show-mode', data = { mode = 'safezone', zones = list } })
end

RegisterCommand('lobby_minigames:interact', function()
    if not LobbyMinigames.active then return end
    if LobbyMinigames.waitingRoom then
        TriggerEvent('Notify', 'error', 'Voce esta aguardando uma partida. Cancele com [F6].', 4)
        return
    end
    local entry = LobbyMinigames.nearest
    if not entry then return end
    if entry.data.modeId == 'dominacao' then
        openSafeZoneSelector()
        return
    end
    openMinigamesUI(entry.data.modeId)
end, false)

RegisterKeyMapping('lobby_minigames:interact', '[MINIGAMES] Interagir com NPC', 'keyboard', 'E')

RegisterNUICallback('safezone:select', function(data, cb)
    print(('^5[lbm] safezone:select NUI cb data=%s^7'):format(json.encode(data or {})))
    local zoneId = data and data.zoneId
    if type(zoneId) ~= 'string' or zoneId == '' then
        print('^1[lbm] safezone:select: zoneId invalido^7')
        cb({ ok = false })
        return
    end
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    currentUIMode = nil
    print(('^5[lbm] triggering domination:enter zoneId=%s^7'):format(zoneId))
    TriggerServerEvent('domination:enter', zoneId)
    cb({ ok = true })
end)

RegisterCommand('lobby_minigames:cancelRoom', function()
    if not LobbyMinigames.active then return end
    if not LobbyMinigames.waitingRoom then return end
    TriggerServerEvent('lobby_minigames:rooms:leaveRoom')
end, false)

RegisterKeyMapping('lobby_minigames:cancelRoom', '[MINIGAMES] Cancelar sala', 'keyboard', 'F6')

local function startLeaveHold()
    if not LobbyMinigames.active then return end
    if leaveHoldActive then return end
    if LobbyMinigames.waitingRoom then
        TriggerEvent('Notify', 'error', 'Voce esta aguardando uma partida. Cancele com [F6] antes de sair.', 4)
        return
    end

    leaveHoldActive = true
    leaveHoldThread = leaveHoldThread + 1
    local myId      = leaveHoldThread
    local startedAt = GetGameTimer()

    SendNUIMessage({ action = 'lobby_minigames:leaveHold', data = { visible = true, percent = 0 } })

    CreateThread(function()
        while leaveHoldActive and myId == leaveHoldThread and LobbyMinigames.active do
            local elapsed = GetGameTimer() - startedAt
            local pct     = math.min(100, math.floor((elapsed / LEAVE_HOLD_MS) * 100))
            SendNUIMessage({ action = 'lobby_minigames:leaveHold', data = { visible = true, percent = pct } })
            if elapsed >= LEAVE_HOLD_MS then
                leaveHoldActive = false
                SendNUIMessage({ action = 'lobby_minigames:leaveHold', data = { visible = false, percent = 0 } })
                TriggerServerEvent('lobby_minigames:leave')
                return
            end
            Wait(50)
        end
        SendNUIMessage({ action = 'lobby_minigames:leaveHold', data = { visible = false, percent = 0 } })
    end)
end

local function cancelLeaveHold()
    if not leaveHoldActive then return end
    leaveHoldActive = false
    SendNUIMessage({ action = 'lobby_minigames:leaveHold', data = { visible = false, percent = 0 } })
end

RegisterCommand('+sairminigames', startLeaveHold,  false)
RegisterCommand('-sairminigames', cancelLeaveHold, false)
RegisterKeyMapping('+sairminigames', '[MINIGAMES] Segurar pra sair', 'keyboard', 'F')

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    despawnNpcs()
    LobbyMinigames.active = false
end)
