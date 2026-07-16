---@class Lobby
---@field userInfo UserRow | nil
---@field cam number | nil
---@field active boolean
Lobby = {
    userInfo = nil,
    cam = nil,
    active = false
}

---@param info UserRow
function Lobby:setUserInfo(info)
    self.userInfo = info
    print(json.encode(info, {
        indent = true
    }))
    SendNUIMessage({
        action = 'setUserInfo',
        data = info
    })
end

function Lobby:awaitUserInfo(timeoutMs)
    if self.userInfo then
        return self.userInfo
    end
    self:requestUserInfo()
    local startedAt = GetGameTimer()
    local deadline  = startedAt + (timeoutMs or 4000)
    local retryAt   = startedAt + 1000
    local retries   = 0
    while not self.userInfo and GetGameTimer() < deadline do
        if GetGameTimer() >= retryAt and retries < 2 then
            retries = retries + 1
            print(('^3[lobby] userInfo RPC slow, retry %d/2^7'):format(retries))
            self:requestUserInfo()
            retryAt = GetGameTimer() + 1500
        end
        Wait(50)
    end
    return self.userInfo
end

---@return number
function Lobby:resolveModelHash()

    local info = self.userInfo
    local clothes = info and info.appearance and info.appearance.clothes or {}
    local modelhash = clothes.modelhash

    if type(modelhash) == 'number' and IsModelInCdimage(modelhash) and IsModelValid(modelhash) then
        return modelhash
    end

    local fallbackName = (info and info.gender == 'female') and 'mp_f_freemode_01' or 'mp_m_freemode_01'

    return GetHashKey(fallbackName)
end

---@param hash number
---@return boolean
function Lobby:swapPedModel(hash)

    RequestModel(hash)

    local loadDeadline = GetGameTimer() + 8000

    while not HasModelLoaded(hash) and GetGameTimer() < loadDeadline do
        Wait(0)
    end

    if not HasModelLoaded(hash) then return false end

    SetPlayerModel(PlayerId(), hash)
    SetModelAsNoLongerNeeded(hash)

    local swapDeadline = GetGameTimer() + 3000

    while GetEntityModel(PlayerPedId()) ~= hash and GetGameTimer() < swapDeadline do
        Wait(0)
    end

    Wait(150)

    return GetEntityModel(PlayerPedId()) == hash
end

---@param ped number
---@param clothes table
---@param COMPONENT_MAP table<string, number>
---@param PROP_MAP table<string, number>
function Lobby:applyClothes(ped, clothes, COMPONENT_MAP, PROP_MAP)

    for slot = 0, 11 do
        SetPedComponentVariation(ped, slot, 0, 0, 0)
    end

    for k, v in pairs(clothes) do

        local cId = COMPONENT_MAP[k]
        local pId = PROP_MAP[k]

        if cId then
            SetPedComponentVariation(ped, cId, v[1] or 0, v[2] or 0, v[3] or 0)
        elseif pId then
            if (v[1] or -1) == -1 then
                ClearPedProp(ped, pId)
            else
                SetPedPropIndex(ped, pId, v[1], v[2] or 0, true)
            end
        end
    end
end

---@param timeoutMs? number
function Lobby:waitForInventarioApply(timeoutMs)

    TriggerServerEvent('inventario:ready', { phase = 'spawn' })

    local deadline = GetGameTimer() + (timeoutMs or 2000)

    while not (Inventario and Inventario.ready) and GetGameTimer() < deadline do
        Wait(50)
    end

    Wait(100)
end

function Lobby:applyAppearance()

    local info = self.userInfo

    local PLAYER_ZERO_HASH = GetHashKey('player_zero')
    local FREEMODE_MALE    = GetHashKey('mp_m_freemode_01')

    local modelhash
    if info then
        modelhash = self:resolveModelHash()
    else
        print('^1[lobby] userInfo unavailable — forcing freemode fallback^7')
        modelhash = FREEMODE_MALE
    end

    if GetEntityModel(PlayerPedId()) ~= modelhash then
        self:swapPedModel(modelhash)
    end

    if GetEntityModel(PlayerPedId()) == PLAYER_ZERO_HASH then
        print('^1[lobby] ped still player_zero after swap — emergency freemode swap^7')
        self:swapPedModel(FREEMODE_MALE)
    end

    if info then
        local ok, maps = pcall(function() return exports['lobby_inventory']:GetClothesMaps() end)
        if ok and maps then
            local COMPONENT_MAP = maps.component or {}
            local PROP_MAP      = maps.prop      or {}
            local clothes       = (info.appearance and info.appearance.clothes) or {}
            self:applyClothes(PlayerPedId(), clothes, COMPONENT_MAP, PROP_MAP)
        end
    end

    Wait(150)

    self:waitForInventarioApply(2000)
end

function Lobby:requestUserInfo()
    RPC._requestUserInfo()
end

function Lobby:init()
    DoScreenFadeOut(0)
    Wait(500)
    DoScreenFadeOut(1000)
    Wait(1000)
    self:requestUserInfo()
end

function Lobby:teleportPed()
    local ped = PlayerPedId()
    local c   = Config.ped.coords

    if IsEntityDead(ped) then
        NetworkResurrectLocalPlayer(c.x, c.y, c.z, Config.ped.heading or 0.0, true, false)
        ped = PlayerPedId()
    end

    RequestCollisionAtCoord(c.x, c.y, c.z)
    SetEntityCoordsNoOffset(ped, c.x, c.y, c.z, true, true, true)
    SetEntityHeading(ped, Config.ped.heading)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100)
end

CreateThread(function()
    while true do
        if Lobby and Lobby.active then
            local ped = PlayerPedId()
            SetEntityInvincible(ped, true)
            SetPlayerInvincible(PlayerId(), true)
            if IsEntityDead(ped) then
                local c = Config.ped and Config.ped.coords
                if c then
                    NetworkResurrectLocalPlayer(c.x, c.y, c.z, Config.ped.heading or 0.0, true, false)
                end
            end
            SetEntityHealth(ped, GetEntityMaxHealth(ped))
            local armor = GetPedArmour(ped)
            if armor < 100 then SetPedArmour(ped, 100) end
            Wait(500)
        else
            Wait(1500)
        end
    end
end)

function Lobby:applyView(view)
    if not self.cam or not DoesCamExist(self.cam) then
        return
    end
    local preset = (Config.views and Config.views[view]) or Config.views.home
    local x, y, z = table.unpack(GetEntityCoords(PlayerPedId()))
    SetCamCoord(self.cam, vector3(x + preset.offset.x, y + preset.offset.y, z + preset.offset.z))
    PointCamAtCoord(self.cam, x + preset.lookAtOffset.x, y + preset.lookAtOffset.y, z + preset.lookAtOffset.z)
end

function Lobby:createCam()
    self:destroyCam()

    local x, y, z = table.unpack(GetEntityCoords(PlayerPedId()))
    local off = Config.cam.offset
    local look = Config.cam.lookAtOffset
    self.cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', false)
    SetCamCoord(self.cam, vector3(x + off.x, y + off.y, z + off.z))
    PointCamAtCoord(self.cam, x + look.x, y + look.y, z + look.z)
    SetCamActive(self.cam, true)
    RenderScriptCams(true, true, Config.cam.fadeMs, 0, 0, 0)
end

function Lobby:destroyCam()
    if self.cam and DoesCamExist(self.cam) then
        SetCamActive(self.cam, false)
        RenderScriptCams(false, true, Config.cam.fadeMs, true, true)
        DestroyCam(self.cam, false)
        self.cam = nil
    end
end

function Lobby:display()

    print('[Lobby] display: started')

    if not IsScreenFadedOut() then
        print('[Lobby] display: fading out screen')
        DoScreenFadeOut(400)
        while not IsScreenFadedOut() do Wait(0) end
    end

    print('[Lobby] display: clearing cams and ped state')

    RenderScriptCams(false, false, 0, true, true)
    self:destroyCam()

    local ped = PlayerPedId()
    local isDead = IsEntityDead(ped)

    print(('[Lobby] display: ped=%d isDead=%s'):format(ped, tostring(isDead)))

    if isDead then

        local c = Config.ped.coords

        NetworkResurrectLocalPlayer(c.x, c.y, c.z, Config.ped.heading or 0.0, true, false)
        ped = PlayerPedId()

        print(('[Lobby] display: resurrected, new ped=%d'):format(ped))
    end

    ClearPedTasks(ped)
    RemoveAllPedWeapons(ped, true)
    ClearPedBloodDamage(ped)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, false)
    NetworkSetInSpectatorMode(false, ped)

    print('[Lobby] display: awaiting user info')
    TriggerServerEvent('lobby:enteringLobby')

    self:awaitUserInfo()

    print(('[Lobby] display: userInfo=%s'):format(self.userInfo and 'ok' or 'nil'))

    print('[Lobby] display: applying appearance')

    self:applyAppearance()

    print('[Lobby] display: teleporting ped')

    self:teleportPed()

    Wait(150)

    print('[Lobby] display: creating cam')

    self:createCam()

    Wait(300)

    self.active = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'show', data = true })

    print('[Lobby] display: showing NUI, fading in')

    DoScreenFadeIn(800)

    CreateThread(function()

        while self.active do

            if Config.hideRadar then
                DisplayRadar(false)
            end

            Wait(0)
        end
    end)
end

function Lobby:close()
    if not self.active then return end
    self.active = false

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })

    if self.cam and DoesCamExist(self.cam) then
        SetCamActive(self.cam, false)
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(self.cam, false)
        self.cam = nil
    end

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
end

RPC:bind({
    receiveUserInfo = function(info)
        Lobby:setUserInfo(info)
    end,
    receiveFriendNotification = function(notification)
        SendNUIMessage({ action = 'friendNotification', data = notification })
    end,
    receiveSquadInvite = function(invite)
        SendNUIMessage({ action = 'squadInvite', data = invite })
    end,
    receiveFriendsUpdate = function(friends)
        SendNUIMessage({ action = 'updateFriends', data = friends })
    end,
    receivePendingRequests = function(pending)
        SendNUIMessage({ action = 'updatePendingRequests', data = pending })
    end,
    receiveSquadUpdate = function(squad)
        SendNUIMessage({ action = 'updateSquad', data = squad })
    end,
})

RegisterNUICallback('setLobbyView', function(data, cb)
    Lobby:applyView(data and data.view or 'home')
    cb({
        ok = true
    })
end)

RegisterNUICallback('joinQueue', function(data, cb)
    TriggerServerEvent('net.lobby:joinQueue', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('leaveQueue', function(_, cb)
    TriggerServerEvent('net.lobby:leaveQueue')
    cb({ ok = true })
end)

RegisterNUICallback('selectMode', function(_, cb)
    cb({ ok = true })
end)

RegisterNUICallback('lobby_minigames:enter', function(_, cb)
    TriggerServerEvent('lobby_minigames:enter')
    cb({ ok = true })
end)

local function ackStub(_, cb)
    cb({ ok = true })
end

RegisterNUICallback('fetchFriends', function(_, cb)
    RPC._requestFriends()
    cb({ ok = true })
end)

RegisterNUICallback('sendFriendRequest', function(data, cb)
    local ok, err = RPC.sendFriendRequest(data.nickname)
    cb({ ok = ok, error = err })
end)

RegisterNUICallback('acceptFriendRequest', function(data, cb)
    local ok, err = RPC.acceptFriendRequest(data.userId)
    cb({ ok = ok, error = err })
end)

RegisterNUICallback('declineFriendRequest', function(data, cb)
    local ok, err = RPC.declineFriendRequest(data.userId)
    cb({ ok = ok, error = err })
end)

RegisterNUICallback('removeFriend', function(data, cb)
    local ok, err = RPC.removeFriend(data.friendId)
    cb({ ok = ok, error = err })
end)

RegisterNUICallback('inviteToSquad', function(data, cb)
    local ok, err = RPC.inviteToSquad(data.friendId)
    cb({ ok = ok, error = err })
end)

RegisterNUICallback('acceptSquadInvite', function(data, cb)
    local ok, err = RPC.acceptSquadInvite(data.fromUserId)
    cb({ ok = ok, error = err })
end)

RegisterNUICallback('declineSquadInvite', function(data, cb)
    local ok, err = RPC.declineSquadInvite(data.fromUserId)
    cb({ ok = ok, error = err })
end)

RegisterNUICallback('leaveSquad', function(_, cb)
    local ok = RPC.leaveSquad()
    cb({ ok = ok })
end)

RegisterNUICallback('openActivity',  ackStub)
RegisterNUICallback('openSettings',  ackStub)
RegisterNUICallback('equipItem',     ackStub)
RegisterNUICallback('close',         ackStub)

RegisterNetEvent('lobby:displayLobby', function()
    print('[Lobby] lobby:displayLobby event received')
    Lobby:display()
end)

RegisterNetEvent('lobby:closeLobby', function()
    Lobby:close()
end)

exports('closeLobby', function()
    Lobby:close()
end)

exports('displayLobby', function()
    Lobby:display()
end)

RegisterCommand('loadlobby', function()
    print("opa")
    Lobby:display()
end)