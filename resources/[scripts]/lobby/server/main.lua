while not Core do
    Wait(100)
end

local API = {}
---@class Lobby
Lobby = {}

---@param src number
function Lobby.pushUserInfo(src)
    local info = Core.getUserInfo(src)
    if not info then
        local userId = Core.getUserId(src)
        print(('^1[lobby] pushUserInfo src=%d userId=%s — NO userInfo (cannot send)^7'):format(
            src, tostring(userId)
        ))
        return
    end

    local ok, navbar = pcall(function()
        local Inventario = exports['lobby_inventory']:GetInventario()
        return Inventario and Inventario:getNavbarEntry() or nil
    end)
    if not ok then
        print(('^3[lobby] pushUserInfo: lobby_inventory:GetInventario errored: %s^7'):format(tostring(navbar)))
    end
    info.navbar = ok and navbar or nil

    print(('[lobby] pushUserInfo src=%d name=%s hasAppearance=%s hasGender=%s'):format(
        src, tostring(info.name), tostring(info.appearance ~= nil), tostring(info.gender)
    ))
    RPC._receiveUserInfo(src, info)
    Lobby.pushFriends(src)
end

function API.requestUserInfo()
    Lobby.pushUserInfo(source)
end

function API.requestFriends()
    Lobby.pushFriends(source)
end

---@type table<number, table<number, boolean>>
local gSquadInvites = {}

---@type table<number, SquadMember[]>
local gSquads = {}

---@param friendId number
---@return table | nil
local function getFriendInfo(friendId)
    local friendSrc = Core.getUserSource(friendId)
    if friendSrc then
        return Core.getUserInfo(friendSrc)
    end
    return nil
end

---@param src number
---@return Friend[]
function Lobby.buildFriendList(src)
    local userId = Core.getUserId(src)
    if not userId then return {} end

    local rows = Core.getUserFriends(userId)
    local friends = {}

    for i = 1, #rows do
        local friendId = rows[i].friend_id
        local info = getFriendInfo(friendId)
        local friendSrc = Core.getUserSource(friendId)

        friends[#friends + 1] = {
            id = tostring(friendId),
            name = info and info.name or tostring(friendId),
            team = info and info.role or '',
            avatar = '',
            banner = '',
            online = friendSrc ~= nil,
        }
    end

    return friends
end

---@param src number
---@return table
function Lobby.buildPendingRequests(src)
    local userId = Core.getUserId(src)
    if not userId then return { incoming = {}, outgoing = {} } end
    return Core.getPendingFriendRequests(userId)
end

---@param src number
function Lobby.pushFriends(src)
    local friends = Lobby.buildFriendList(src)
    local pending = Lobby.buildPendingRequests(src)
    RPC._receiveFriendsUpdate(src, friends)
    RPC._receivePendingRequests(src, pending)
end

---@param src number
function Lobby.pushSquad(src)
    local userId = Core.getUserId(src)
    if not userId then return end
    local squad = gSquads[userId] or {}
    RPC._receiveSquadUpdate(src, squad)
end

---@return Friend[], table
function API.getFriends()
    local src = source
    return Lobby.buildFriendList(src), Lobby.buildPendingRequests(src)
end

---@param nickname string
---@return boolean, string | nil
function API.sendFriendRequest(nickname)
    local src = source
    local userId = Core.getUserId(src)
    if not userId then return false, 'Usuário não encontrado' end

    local target = Core.getUserByName(nickname)
    if not target then return false, 'Jogador não encontrado' end

    local ok, err = Core.sendFriendRequest(userId, target.id)
    if not ok then return false, err end

    local targetSrc = Core.getUserSource(target.id)
    if targetSrc then
        local senderInfo = Core.getUserInfo(src)
        RPC._receiveFriendNotification(targetSrc, {
            type = 'request_received',
            fromName = senderInfo and senderInfo.name or tostring(userId),
            fromUserId = userId,
        })
        Lobby.pushFriends(targetSrc)
    end

    Lobby.pushFriends(src)
    return true
end

---@param fromUserId number
---@return boolean, string | nil
function API.acceptFriendRequest(fromUserId)
    local src = source
    local userId = Core.getUserId(src)
    if not userId then return false, 'Usuário não encontrado' end

    local ok, err = Core.acceptFriendRequest(userId, fromUserId)
    if not ok then return false, err end

    Lobby.pushFriends(src)

    local requesterSrc = Core.getUserSource(fromUserId)
    if requesterSrc then
        local acceptorInfo = Core.getUserInfo(src)
        RPC._receiveFriendNotification(requesterSrc, {
            type = 'request_accepted',
            fromName = acceptorInfo and acceptorInfo.name or tostring(userId),
            fromUserId = userId,
        })
        Lobby.pushFriends(requesterSrc)
    end

    return true
end

---@param fromUserId number
---@return boolean, string | nil
function API.declineFriendRequest(fromUserId)
    local src = source
    local userId = Core.getUserId(src)
    if not userId then return false, 'Usuário não encontrado' end

    local ok, err = Core.declineFriendRequest(userId, fromUserId)
    if not ok then return false, err end

    Lobby.pushFriends(src)

    local requesterSrc = Core.getUserSource(fromUserId)
    if requesterSrc then
        RPC._receiveFriendNotification(requesterSrc, {
            type = 'request_declined',
            fromName = '',
            fromUserId = userId,
        })
        Lobby.pushFriends(requesterSrc)
    end

    return true
end

---@param friendId number
---@return boolean, string | nil
function API.removeFriend(friendId)
    local src = source
    local userId = Core.getUserId(src)
    if not userId then return false, 'Usuário não encontrado' end

    local ok, err = Core.removeFriend(userId, friendId)
    if not ok then return false, err end

    Lobby.pushFriends(src)

    local friendSrc = Core.getUserSource(friendId)
    if friendSrc then
        Lobby.pushFriends(friendSrc)
    end

    return true
end

---@param friendId number
---@return boolean, string | nil
function API.inviteToSquad(friendId)
    local src = source
    local userId = Core.getUserId(src)
    if not userId then return false, 'Usuário não encontrado' end

    local fid = tonumber(friendId)
    if not fid then return false, 'ID inválido' end

    local friendSrc = Core.getUserSource(fid)
    if not friendSrc then return false, 'Amigo está offline' end

    if not gSquadInvites[userId] then
        gSquadInvites[userId] = {}
    end
    gSquadInvites[userId][fid] = true

    local senderInfo = Core.getUserInfo(src)
    RPC._receiveSquadInvite(friendSrc, {
        fromUserId = userId,
        fromName = senderInfo and senderInfo.name or tostring(userId),
        fromAvatar = '',
    })

    return true
end

---@param fromUserId number
---@return boolean, string | nil
function API.acceptSquadInvite(fromUserId)
    local src = source
    local userId = Core.getUserId(src)
    if not userId then return false, 'Usuário não encontrado' end

    local fid = tonumber(fromUserId)
    if not fid then return false, 'ID inválido' end

    if not gSquadInvites[fid] or not gSquadInvites[fid][userId] then
        return false, 'Convite não encontrado'
    end

    gSquadInvites[fid][userId] = nil

    if not gSquads[fid] then
        local leaderSrc = Core.getUserSource(fid)
        local leaderInfo = leaderSrc and Core.getUserInfo(leaderSrc) or nil
        gSquads[fid] = {
            { id = tostring(fid), name = leaderInfo and leaderInfo.name or tostring(fid), avatar = '', isLeader = true },
        }
    end

    local squad = gSquads[fid]

    if #squad >= 4 then
        return false, 'Squad está cheio'
    end

    for i = 1, #squad do
        if squad[i].id == tostring(userId) then
            return false, 'Jogador já está no squad'
        end
    end

    local memberInfo = Core.getUserInfo(src)
    squad[#squad + 1] = {
        id = tostring(userId),
        name = memberInfo and memberInfo.name or tostring(userId),
        avatar = '',
        isLeader = false,
    }

    gSquads[userId] = squad

    for i = 1, #squad do
        local memberId = tonumber(squad[i].id)
        if memberId then
            local memberSrc = Core.getUserSource(memberId)
            if memberSrc then
                RPC._receiveSquadUpdate(memberSrc, squad)
            end
        end
    end

    return true
end

---@param fromUserId number
---@return boolean, string | nil
function API.declineSquadInvite(fromUserId)
    local src = source
    local userId = Core.getUserId(src)
    if not userId then return false, 'Usuário não encontrado' end

    local fid = tonumber(fromUserId)
    if not fid then return false, 'ID inválido' end

    if gSquadInvites[fid] then
        gSquadInvites[fid][userId] = nil
    end

    local inviterSrc = Core.getUserSource(fid)
    if inviterSrc then
        local declinedInfo = Core.getUserInfo(src)
        RPC._receiveFriendNotification(inviterSrc, {
            type = 'invite_declined',
            fromName = declinedInfo and declinedInfo.name or tostring(userId),
            fromUserId = userId,
        })
    end

    return true
end

---@return boolean
function API.leaveSquad()

    local src = source
    local userId = Core.getUserId(src)

    if not userId then return false end

    local squad = gSquads[userId]

    if not squad then return false end

    for i = #squad, 1, -1 do
        if tonumber(squad[i].id) == userId then
            table.remove(squad, i)
            break
        end
    end

    gSquads[userId] = nil

    if #squad <= 1 then

        for i = 1, #squad do

            local memberId = tonumber(squad[i].id)

            if memberId then
                gSquads[memberId] = nil

                local memberSrc = Core.getUserSource(memberId)

                if memberSrc then
                    RPC._receiveSquadUpdate(memberSrc, {})
                end
            end
        end
    else

        local hasLeader = false

        for i = 1, #squad do
            if squad[i].isLeader then
                hasLeader = true
                break
            end
        end

        if not hasLeader and #squad > 0 then
            squad[1].isLeader = true
        end

        for i = 1, #squad do

            local memberId = tonumber(squad[i].id)

            if memberId then

                local memberSrc = Core.getUserSource(memberId)

                if memberSrc then
                    RPC._receiveSquadUpdate(memberSrc, squad)
                end
            end
        end
    end

    RPC._receiveSquadUpdate(src, {})

    return true
end

RPC:bind(API)


---@param userId number
local function pushFriendsOnlineStatus(userId)

    local rows = Core.getUserFriends(userId)

    for i = 1, #rows do

        local friendSrc = Core.getUserSource(rows[i].friend_id)

        if friendSrc then
            Lobby.pushFriends(friendSrc)
        end
    end
end

---@param userId number
local function cleanupSquadOnDrop(userId)

    local squad = gSquads[userId]

    if not squad then return end

    for i = #squad, 1, -1 do
        if tonumber(squad[i].id) == userId then
            table.remove(squad, i)
            break
        end
    end

    gSquads[userId] = nil

    if #squad <= 1 then

        for i = 1, #squad do

            local memberId = tonumber(squad[i].id)

            if memberId then
                gSquads[memberId] = nil

                local memberSrc = Core.getUserSource(memberId)

                if memberSrc then
                    RPC._receiveSquadUpdate(memberSrc, {})
                end
            end
        end
    else

        local hasLeader = false

        for i = 1, #squad do
            if squad[i].isLeader then
                hasLeader = true
                break
            end
        end

        if not hasLeader and #squad > 0 then
            squad[1].isLeader = true
        end

        for i = 1, #squad do

            local memberId = tonumber(squad[i].id)

            if memberId then

                local memberSrc = Core.getUserSource(memberId)

                if memberSrc then
                    RPC._receiveSquadUpdate(memberSrc, squad)
                end
            end
        end
    end
end

RegisterNetEvent('lobby:enteringLobby', function()

    local src = source

    if not src or src == 0 then return end
    if not DoesPlayerExist(tostring(src)) then return end

    SetPlayerRoutingBucket(tostring(src), src)

    local userId = Core.getUserId(src)

    if userId then
        pushFriendsOnlineStatus(userId)
    end
end)

AddEventHandler('playerDropped', function()

    local src = source
    local userId = Core.getUserId(src)

    if not userId then return end

    cleanupSquadOnDrop(userId)
    pushFriendsOnlineStatus(userId)
end)

RegisterNetEvent('net.lobby:joinQueue', function(payload)

    local src = source

    if not payload or type(payload) ~= 'table' then return end

    local userId = Core.getUserId(src)

    if not userId then return end

    local squad = gSquads[userId]
    local sources = { src }

    if squad and #squad > 1 then

        local isLeader = false

        for i = 1, #squad do

            if tonumber(squad[i].id) == userId and squad[i].isLeader then
                isLeader = true
                break
            end
        end

        if not isLeader then
            Core.log('warn', ('joinQueue: src=%d is not the squad leader, ignoring'):format(src))
            return
        end

        sources = {}

        local seen = {}

        for i = 1, #squad do

            local memberId = tonumber(squad[i].id)

            if memberId then

                local memberSrc = Core.getUserSource(memberId)

                if memberSrc and not seen[memberSrc] then
                    seen[memberSrc] = true
                    sources[#sources + 1] = memberSrc
                end
            end
        end
    end

    local modeKey, subModeKey, squadKey = Core.resolveMatchKeys(
        payload.category, payload.submode, 'squad'
    )

    if not modeKey or not subModeKey or not squadKey then
        Core.log('warn', ('joinQueue: could not resolve mode="%s" sub="%s" squad="squad" (src=%d)'):format(
            tostring(payload.category), tostring(payload.submode), src
        ))
        return
    end

    local ok, err = Core.addPlayerToQueue(sources, modeKey, subModeKey, squadKey, payload.fillSlot == true)

    if not ok then
        Core.log('warn', ('joinQueue failed for src=%d: %s'):format(src, tostring(err)))
    end
end)

RegisterNetEvent('net.lobby:leaveQueue', function()
    local src = source
    Core.removePlayerFromQueue(src)
end)

AddEventHandler('kingg:matchmaking:start', function(batch)
    for i = 1, #batch do
        TriggerClientEvent('lobby:closeLobby', batch[i])
    end
end)
