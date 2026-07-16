while not Core do
    Wait(100)
end

local Friends = {
    requests = {},
}

function Friends:_areFriends(userId, otherId)
    local a, b = tonumber(userId), tonumber(otherId)
    if not a or not b or a == b then
        return false
    end
    local row = Core.single(
        [[SELECT 1 AS ok FROM `friends`
          WHERE (`user_id` = ? AND `friend_id` = ?)
             OR (`user_id` = ? AND `friend_id` = ?)
          LIMIT 1]],
        { a, b, b, a }
    )
    return row ~= nil
end

function Friends:_clearPendingRequest(fromUserId, toUserId)
    local pending = self.requests[fromUserId]
    if not pending then
        return
    end
    pending[toUserId] = nil
    if not next(pending) then
        self.requests[fromUserId] = nil
    end
end

function Friends:sendRequest(userId, targetUserId)
    local uid, tid = tonumber(userId), tonumber(targetUserId)
    if not uid or not tid then
        return false, 'IDs inválidos'
    end
    if uid == tid then
        return false, 'Você não pode enviar pedido para si mesmo'
    end
    if self:_areFriends(uid, tid) then
        return false, 'O usuário já é seu amigo'
    end
    if self.requests[uid] and self.requests[uid][tid] then
        return false, 'O pedido de amizade já foi enviado'
    end
    if self.requests[tid] and self.requests[tid][uid] then
        return false, 'Este usuário já te enviou um pedido de amizade'
    end
    if not self.requests[uid] then
        self.requests[uid] = {}
    end
    self.requests[uid][tid] = true
    return true
end

function Friends:acceptRequest(acceptorUserId, requesterUserId)
    local accept, requester = tonumber(acceptorUserId), tonumber(requesterUserId)
    if not accept or not requester then
        return false, 'IDs inválidos'
    end
    if not self.requests[requester] or not self.requests[requester][accept] then
        return false, 'O pedido de amizade não foi encontrado'
    end
    if self:_areFriends(accept, requester) then
        self:_clearPendingRequest(requester, accept)
        return false, 'O usuário já é seu amigo'
    end
    self:_clearPendingRequest(requester, accept)
    Core.Query(
        [[INSERT IGNORE INTO `friends` (`user_id`, `friend_id`) VALUES (?, ?), (?, ?)]],
        { accept, requester, requester, accept }
    )
    return true
end

function Friends:removeFriend(userId, friendId)
    local uid, fid = tonumber(userId), tonumber(friendId)
    if not uid or not fid then
        return false, 'IDs inválidos'
    end
    if uid == fid then
        return false, 'Você não pode remover si mesmo'
    end
    if not self:_areFriends(uid, fid) then
        return false, 'Não é seu amigo'
    end
    Core._Execute(
        [[DELETE FROM `friends`
          WHERE (`user_id` = ? AND `friend_id` = ?)
             OR (`user_id` = ? AND `friend_id` = ?)]],
        { uid, fid, fid, uid }
    )
    self:_clearPendingRequest(uid, fid)
    self:_clearPendingRequest(fid, uid)
    return true
end


function Core.getUserFriends(userId)
    local uid = tonumber(userId)
    if not uid then
        return false, 'IDs inválidos (userId)'
    end
    local friends = Core.Query('SELECT friend_id, user_id FROM `friends` WHERE `user_id` = ?', { uid })
    return friends or {}
end

function Core.acceptFriendRequest(userId, friendId)
    local uid = tonumber(userId)
    if not uid then
        return false, 'IDs inválidos (userId)'
    end
    local fid = tonumber(friendId)
    if not fid then
        return false, 'IDs inválidos (friendId)'
    end
    return Friends:acceptRequest(uid, fid)
end

function Core.removeFriend(userId, friendId)
    local uid = tonumber(userId)
    if not uid then
        return false, 'IDs inválidos (userId)'
    end
    local fid = tonumber(friendId)
    if not fid then
        return false, 'IDs inválidos (friendId)'
    end
    return Friends:removeFriend(uid, fid)
end

function Core.sendFriendRequest(userId, friendId)
    local uid = tonumber(userId)
    if not uid then
        return false, 'IDs inválidos (userId)'
    end
    local fid = tonumber(friendId)
    if not fid then
        return false, 'IDs inválidos (friendId)'
    end
    return Friends:sendRequest(uid, fid)
end

---@param userId number
---@return table
function Core.getPendingFriendRequests(userId)
    local uid = tonumber(userId)
    if not uid then
        return { incoming = {}, outgoing = {} }
    end

    local incoming = {}
    local outgoing = {}

    for fromId, targets in pairs(Friends.requests) do
        if targets[uid] then
            local info = Core.users_info[fromId]
            local name = info and info.name
            if not name then
                local row = Core.single('SELECT name FROM `users` WHERE `id` = ? LIMIT 1', { fromId })
                name = row and row.name or tostring(fromId)
            end
            incoming[#incoming + 1] = { userId = fromId, name = name }
        end
    end

    if Friends.requests[uid] then
        for toId in pairs(Friends.requests[uid]) do
            local info = Core.users_info[toId]
            local name = info and info.name
            if not name then
                local row = Core.single('SELECT name FROM `users` WHERE `id` = ? LIMIT 1', { toId })
                name = row and row.name or tostring(toId)
            end
            outgoing[#outgoing + 1] = { userId = toId, name = name }
        end
    end

    return { incoming = incoming, outgoing = outgoing }
end

---@param name string
---@return table | nil
function Core.getUserByName(name)
    if type(name) ~= 'string' or name == '' then
        return nil
    end
    return Core.single('SELECT id, name FROM `users` WHERE `name` = ? LIMIT 1', { name })
end

---@param userId number
---@param fromUserId number
---@return boolean ok
---@return string | nil err
function Core.declineFriendRequest(userId, fromUserId)
    local uid = tonumber(userId)
    local fid = tonumber(fromUserId)
    if not uid or not fid then
        return false, 'IDs inválidos'
    end
    if not Friends.requests[fid] or not Friends.requests[fid][uid] then
        return false, 'O pedido de amizade não foi encontrado'
    end
    Friends:_clearPendingRequest(fid, uid)
    return true
end