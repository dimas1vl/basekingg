while not Core do
    Wait(100)
end

---@class LobbyMinigames
---@field sessions table<number, { src: number }>
LobbyMinigames = LobbyMinigames or {}
LobbyMinigames.sessions = LobbyMinigames.sessions or {}

local SHARED_BUCKET = Core.allocateBucket()
local lastEnter = {}
local ENTER_COOLDOWN_MS = 1500

local function log(level, msg)
    if Core and Core.log then
        return Core.log(level, ('[lobby_minigames] %s'):format(msg))
    end
    print(('[lobby_minigames] [%s] %s'):format(level, msg))
end

log('info', ('shared bucket allocated: %d'):format(SHARED_BUCKET))

local function notify(src, kind, msg)
    if not src or src == 0 then return end
    TriggerClientEvent('Notify', src, kind or 'info', msg, 5)
end

---@param modeId string
---@return table | nil
local function findNpcByMode(modeId)
    local npcs = Config.LobbyMinigames and Config.LobbyMinigames.npcs or {}
    for i = 1, #npcs do
        if npcs[i].modeId == modeId then return npcs[i] end
    end
    return nil
end

---@param src number
---@return boolean
local function isInOtherActivity(src)
    if Core.isInQueue and Core.isInQueue(src) then return true end
    if Core.getPlayerMatch and Core.getPlayerMatch(src) then return true end
    return false
end

---@param src number
function LobbyMinigames:releaseSession(src)
    if not self.sessions[src] then return end
    self.sessions[src] = nil
end

---@param src number
function LobbyMinigames:enter(src)
    if self.sessions[src] then return end

    local now = GetGameTimer()
    if lastEnter[src] and (now - lastEnter[src]) < ENTER_COOLDOWN_MS then
        return
    end
    lastEnter[src] = now

    if isInOtherActivity(src) then
        return notify(src, 'error', 'Voce ja esta em outra atividade.')
    end

    if Core.removePlayerFromQueue then
        pcall(Core.removePlayerFromQueue, src)
    end

    SetPlayerRoutingBucket(tostring(src), SHARED_BUCKET)
    self.sessions[src] = { src = src }

    TriggerClientEvent('lobby_minigames:enter', src, {
        spawn = Config.LobbyMinigames.spawn,
        npcs  = Config.LobbyMinigames.npcs,
    })

    log('info', ('player %d entered (shared bucket %d, %d total)'):format(
        src, SHARED_BUCKET, self:countSessions()
    ))
end

---@param src number
function LobbyMinigames:leave(src)
    if not self.sessions[src] then return end

    if LobbyMinigames.rooms then
        for _, room in pairs(LobbyMinigames.rooms) do
            for i = 1, #room.players do
                if room.players[i] == src then
                    if room.ownerSrc == src then
                        local roomId = room.id
                        local affected = {}
                        for j = 1, #room.players do affected[j] = room.players[j] end
                        LobbyMinigames.rooms[roomId] = nil
                        for j = 1, #affected do
                            if affected[j] ~= src then
                                TriggerClientEvent('lobby_minigames:rooms:closed', affected[j], { reason = 'owner-left' })
                            end
                        end
                    else
                        local roomId = room.id
                        local newPlayers = {}
                        for j = 1, #room.players do
                            if room.players[j] ~= src then newPlayers[#newPlayers + 1] = room.players[j] end
                        end
                        room.players = newPlayers
                        for j = 1, #newPlayers do
                            TriggerClientEvent('lobby_minigames:rooms:waiting', newPlayers[j], {
                                roomId  = roomId,
                                mode    = room.gameMode,
                                map     = room.map,
                                variant = room.variant,
                                current = #newPlayers,
                                max     = room.maxPlayers,
                                owner   = room.ownerName,
                            })
                        end
                    end
                    break
                end
            end
        end
    end

    TriggerClientEvent('lobby_minigames:leave', src)

    if DoesPlayerExist(tostring(src)) then
        SetPlayerRoutingBucket(tostring(src), src)
    end

    self.sessions[src] = nil

    log('info', ('player %d left (%d remaining)'):format(src, self:countSessions()))
end

---@return integer
function LobbyMinigames:countSessions()
    local n = 0
    for _ in pairs(self.sessions) do n = n + 1 end
    return n
end

---@param src number
---@return boolean
local function isPlayerInRoom(src)
    if not LobbyMinigames.rooms then return false end
    for _, room in pairs(LobbyMinigames.rooms) do
        for i = 1, #room.players do
            if room.players[i] == src then return true end
        end
    end
    return false
end

---@param src number
---@param modeId string
function LobbyMinigames:requestMode(src, modeId)
    if not self.sessions[src] then
        return notify(src, 'error', 'Voce nao esta na area dos minigames.')
    end

    local npc = findNpcByMode(modeId)
    if not npc then
        return notify(src, 'error', 'Modo invalido.')
    end

    notify(src, 'success', ('[MOCK] Entrando em: %s'):format(npc.label))
    log('info', ('[MOCK] player %d would queue for mode=%s'):format(src, modeId))
end

RegisterNetEvent('lobby_minigames:enter', function()
    LobbyMinigames:enter(source)
end)

RegisterNetEvent('lobby_minigames:leave', function()
    local src = source
    if isPlayerInRoom(src) then
        return notify(src, 'error', 'Voce esta aguardando uma partida. Cancele com [F6] antes de sair.')
    end
    LobbyMinigames:leave(src)
end)

RegisterNetEvent('lobby_minigames:requestMode', function(modeId)
    if type(modeId) ~= 'string' or modeId == '' then return end
    LobbyMinigames:requestMode(source, modeId)
end)


---@class MGRoom
---@field id string
---@field gameMode string
---@field ownerSrc number
---@field ownerName string
---@field map string
---@field maxPlayers number
---@field variant string | nil
---@field isPrivate boolean
---@field password string | nil
---@field players number[]
---@field createdAt number

---@type table<string, MGRoom>
LobbyMinigames.rooms = LobbyMinigames.rooms or {}

local roomCounter = 0

local function nextRoomId(prefix)
    roomCounter = roomCounter + 1
    return ('%s_%d'):format(prefix or 'r', roomCounter)
end

---@param src number
local function getPlayerName(src)
    if Core.getUserInfo then
        local info = Core.getUserInfo(src)
        if info and info.name then return info.name end
    end
    return GetPlayerName(src) or ('Player#' .. src)
end

---@param mode string
---@return MGRoom[]
local function listRoomsByMode(mode)
    local out = {}
    for _, room in pairs(LobbyMinigames.rooms) do
        if room.gameMode == mode then
            out[#out + 1] = {
                id         = room.id,
                owner      = room.ownerName,
                map        = room.map,
                players    = #room.players,
                maxPlayers = room.maxPlayers,
                isPrivate  = room.isPrivate,
                variant    = room.variant,
            }
        end
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

---@param mode string
---@param ownerSrc number
---@param payload table
---@return MGRoom
local function createRoom(mode, ownerSrc, payload)
    local id = nextRoomId(string.sub(mode, 1, 1))
    local room = {
        id         = id,
        gameMode   = mode,
        ownerSrc   = ownerSrc,
        ownerName  = getPlayerName(ownerSrc),
        map        = tostring(payload.map or 'MAPA PADRAO'):upper(),
        maxPlayers = tonumber(payload.maxPlayers) or 2,
        variant    = type(payload.variant) == 'string' and payload.variant:lower() or payload.variant,
        isPrivate  = payload.isPrivate == true,
        password   = payload.password,
        players    = { ownerSrc },
        createdAt  = os.time(),
    }
    LobbyMinigames.rooms[id] = room
    log('info', ('room created id=%s mode=%s owner=%d map=%s slots=%d variant=%s'):format(
        id, mode, ownerSrc, room.map, room.maxPlayers, tostring(room.variant or '-')
    ))
    return room
end

---@param src number
---@return MGRoom | nil
local function getRoomByPlayer(src)
    for _, room in pairs(LobbyMinigames.rooms) do
        for i = 1, #room.players do
            if room.players[i] == src then return room end
        end
    end
    return nil
end

---@param roomId string
local function broadcastRoomWaiting(roomId)
    local room = LobbyMinigames.rooms[roomId]
    if not room then return end
    local payload = {
        roomId  = room.id,
        mode    = room.gameMode,
        map     = room.map,
        variant = room.variant,
        current = #room.players,
        max     = room.maxPlayers,
        owner   = room.ownerName,
    }
    for i = 1, #room.players do
        TriggerClientEvent('lobby_minigames:rooms:waiting', room.players[i], payload)
    end
end

---@param roomId string
---@param reason string | nil
local function destroyRoom(roomId, reason)
    local room = LobbyMinigames.rooms[roomId]
    if not room then return end
    local affected = {}
    for i = 1, #room.players do affected[i] = room.players[i] end
    LobbyMinigames.rooms[roomId] = nil
    log('info', ('room destroyed id=%s reason=%s'):format(roomId, tostring(reason or '-')))
    for i = 1, #affected do
        TriggerClientEvent('lobby_minigames:rooms:closed', affected[i], { reason = reason or 'destroyed' })
    end
end

---@param src number
---@return string | nil roomId
local function removePlayerFromRoom(src)
    local room = getRoomByPlayer(src)
    if not room then return nil end
    local roomId = room.id

    if room.ownerSrc == src then
        destroyRoom(roomId, 'owner-left')
        return roomId
    end

    local newPlayers = {}
    for i = 1, #room.players do
        if room.players[i] ~= src then newPlayers[#newPlayers + 1] = room.players[i] end
    end
    room.players = newPlayers

    TriggerClientEvent('lobby_minigames:rooms:closed', src, { reason = 'left' })
    broadcastRoomWaiting(roomId)
    return roomId
end

---@param roomId string
---@param src number
---@param password string | nil
---@return boolean ok, string | nil err
local function joinRoom(roomId, src, password)
    local room = LobbyMinigames.rooms[roomId]
    if not room then return false, 'Sala nao existe.' end
    if #room.players >= room.maxPlayers then return false, 'Sala cheia.' end
    if room.isPrivate and room.password ~= password then
        return false, 'Senha incorreta.'
    end
    for i = 1, #room.players do
        if room.players[i] == src then return true end
    end
    room.players[#room.players + 1] = src
    return true
end

---@return integer
local function getOnlineCount()
    return GetNumPlayerIndices()
end

RegisterNetEvent('lobby_minigames:rooms:list', function(mode)
    local src = source
    TriggerClientEvent('lobby_minigames:rooms:list', src, mode, listRoomsByMode(mode))
    TriggerClientEvent('lobby_minigames:players:total', src, getOnlineCount())
end)

RegisterNetEvent('lobby_minigames:rooms:create', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end
    local mode = payload.gameMode
    if type(mode) ~= 'string' or mode == '' then
        return notify(src, 'error', 'Modo invalido pra criar sala.')
    end

    if getRoomByPlayer(src) then
        return notify(src, 'error', 'Voce ja esta aguardando uma partida. Cancele a sala com [F6] antes de criar outra.')
    end

    local room = createRoom(mode, src, payload)
    TriggerClientEvent('lobby_minigames:rooms:list', src, mode, listRoomsByMode(mode))
    TriggerClientEvent('lobby_minigames:players:total', src, getOnlineCount())
    broadcastRoomWaiting(room.id)
    notify(src, 'success', ('Sala "%s" criada (%s).'):format(room.map, room.variant or (room.maxPlayers .. ' slots')))
end)

RegisterNetEvent('lobby_minigames:rooms:join', function(roomId, password)
    local src = source
    if type(roomId) ~= 'string' or roomId == '' then return end

    local current = getRoomByPlayer(src)
    if current then
        if current.id == roomId then
            broadcastRoomWaiting(roomId)
            return
        end
        return notify(src, 'error', 'Voce ja esta aguardando uma partida. Cancele a sala com [F6] antes de entrar em outra.')
    end

    local ok, err = joinRoom(roomId, src, password)
    if not ok then
        return notify(src, 'error', err or 'Falha ao entrar na sala.')
    end
    local room = LobbyMinigames.rooms[roomId]
    broadcastRoomWaiting(roomId)
    notify(src, 'success', ('Entrou na sala %s (%d/%d).'):format(room.map, #room.players, room.maxPlayers))

    if #room.players >= room.maxPlayers then
        local batch = {}
        for i = 1, #room.players do batch[i] = room.players[i] end

        local mode    = room.gameMode
        local subMode = room.variant
        local options = { map = room.map }

        log('info', ('room %s lotou (%d/%d) — disparando matchmaking:start mode=%s sub=%s'):format(
            room.id, #batch, room.maxPlayers, tostring(mode), tostring(subMode)
        ))

        LobbyMinigames.rooms[room.id] = nil

        TriggerEvent('kingg:matchmaking:start', batch, mode, subMode, 'squad', options)
    end
end)

RegisterNetEvent('lobby_minigames:rooms:leaveRoom', function()
    local src = source
    if removePlayerFromRoom(src) then
        notify(src, 'info', 'Voce saiu da sala.')
    end
end)

exports('listRoomsByMode',   function(mode) return listRoomsByMode(mode) end)
exports('getRoom',           function(id)   return LobbyMinigames.rooms[id] end)
exports('getRoomByPlayer',   function(src)  return getRoomByPlayer(tonumber(src)) end)
exports('removePlayerFromRoom', function(src) return removePlayerFromRoom(tonumber(src)) end)

AddEventHandler('playerDropped', function()
    local src = source
    LobbyMinigames:leave(src)
    lastEnter[src] = nil
end)

AddEventHandler('kingg:player:leave', function(src)
    LobbyMinigames:leave(src)
    lastEnter[src] = nil
end)

AddEventHandler('kingg:matchmaking:start', function(batch)
    for i = 1, #batch do
        local src = batch[i]
        if LobbyMinigames.sessions[src] then
            removePlayerFromRoom(src)
            TriggerClientEvent('lobby_minigames:handover', src)
            LobbyMinigames:releaseSession(src)
            lastEnter[src] = nil
        end
    end
end)

AddEventHandler('kingg:matchmaking:rejected', function(batch, mode, subMode, reason)
    if type(batch) ~= 'table' then return end
    log('warn', ('rollback: gamemode %s/%s rejeitou batch (%s) — re-entrando %d players na area'):format(
        tostring(mode), tostring(subMode), tostring(reason), #batch
    ))
    for i = 1, #batch do
        local src = tonumber(batch[i])
        if src and DoesPlayerExist(tostring(src)) then
            LobbyMinigames:enter(src)
            notify(src, 'error', ('Falha ao iniciar partida: %s'):format(tostring(reason or 'sala fechada')))
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for src in pairs(LobbyMinigames.sessions) do
        LobbyMinigames:leave(src)
    end
    if SHARED_BUCKET then
        Core.releaseBucket(SHARED_BUCKET)
        SHARED_BUCKET = nil
    end
end)

exports('enterArea', function(src) LobbyMinigames:enter(tonumber(src)) end)
exports('leaveArea', function(src) LobbyMinigames:leave(tonumber(src)) end)
exports('isInArea',  function(src) return LobbyMinigames.sessions[tonumber(src)] ~= nil end)
exports('getSharedBucket', function() return SHARED_BUCKET end)
exports('releaseSession', function(src) LobbyMinigames:releaseSession(tonumber(src)) end)

RegisterCommand('minigames', function(src)
    src = tonumber(src) or 0
    if src == 0 then
        return log('info', '/minigames so funciona no jogo, nao no console.')
    end
    LobbyMinigames:enter(src)
end, false)

RegisterCommand('sairmg', function(src)
    src = tonumber(src) or 0
    if src == 0 then return end
    if isPlayerInRoom(src) then
        return notify(src, 'error', 'Voce esta aguardando uma partida. Cancele com [F6] antes de sair.')
    end
    LobbyMinigames:leave(src)
end, false)

log('info', 'server module loaded — use /minigames pra entrar, /sairmg pra sair instantaneo')
