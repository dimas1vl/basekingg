local VALID_ROLES = { user = true, admin = true, spec = true }
local VALID_STATS = { xp = true, gems = true }

---@param adminSrc number
---@param targetSrc number
function Admin.act.tpto(adminSrc, targetSrc)
    if targetSrc == adminSrc then
        return Admin.notify(adminSrc, 'warning', 'Voce nao pode se teleportar para si mesmo.')
    end

    local bucket = GetPlayerRoutingBucket(tostring(targetSrc))
    SetPlayerRoutingBucket(tostring(adminSrc), bucket)

    local coords = GetEntityCoords(GetPlayerPed(targetSrc))
    TriggerClientEvent('admin:teleport', adminSrc, { x = coords.x, y = coords.y, z = coords.z })

    Admin.notify(adminSrc, 'success', ('Voce foi teleportado ate %s.'):format(Admin.playerName(targetSrc)))
end

---@param adminSrc number
---@param targetSrc number
function Admin.act.tptome(adminSrc, targetSrc)
    if targetSrc == adminSrc then
        return Admin.notify(adminSrc, 'warning', 'Voce nao pode puxar a si mesmo.')
    end

    TriggerEvent('kingg:player:leave', targetSrc)
    Admin.frozen[targetSrc] = nil
    Admin.god[targetSrc] = nil

    local adminBucket = GetPlayerRoutingBucket(tostring(adminSrc))
    local coords = GetEntityCoords(GetPlayerPed(adminSrc))

    CreateThread(function()
        Wait(600)
        if not DoesPlayerExist(targetSrc) then return end
        SetPlayerRoutingBucket(tostring(targetSrc), adminBucket)
        TriggerClientEvent('lobby:closeLobby', targetSrc)
        TriggerClientEvent('admin:teleport', targetSrc, { x = coords.x, y = coords.y, z = coords.z })
    end)

    Admin.notify(adminSrc, 'success', ('%s foi puxado ate voce.'):format(Admin.playerName(targetSrc)))
    Admin.notify(targetSrc, 'importante', 'Voce foi teleportado por um admin.')
end

---Toggle freeze on the target.
---@param adminSrc number
---@param targetSrc number
function Admin.act.freeze(adminSrc, targetSrc)
    local frozen = not Admin.frozen[targetSrc]
    Admin.frozen[targetSrc] = frozen or nil
    TriggerClientEvent('admin:freeze', targetSrc, frozen)

    Admin.notify(adminSrc, 'success', ('%s foi %s.'):format(Admin.playerName(targetSrc), frozen and 'congelado' or 'descongelado'))
    Admin.notify(targetSrc, 'importante', frozen and 'Voce foi congelado por um admin.' or 'Voce foi descongelado.')
end

---Toggle god mode (max health/armor + invincible) on the target.
---@param adminSrc number
---@param targetSrc number
function Admin.act.god(adminSrc, targetSrc)
    local enabled = not Admin.god[targetSrc]
    Admin.god[targetSrc] = enabled or nil
    TriggerClientEvent('admin:god', targetSrc, enabled)

    local who = targetSrc == adminSrc and 'Voce' or Admin.playerName(targetSrc)
    Admin.notify(adminSrc, 'success', ('God mode %s para %s.'):format(enabled and 'ativado' or 'desativado', who))
    if targetSrc ~= adminSrc then
        Admin.notify(targetSrc, 'importante', enabled and 'God mode ativado por um admin.' or 'God mode desativado.')
    end
end

---Send the target back to the lobby regardless of their mode.
---@param adminSrc number
---@param targetSrc number
function Admin.act.setarlobby(adminSrc, targetSrc)
    TriggerEvent('kingg:player:leave', targetSrc)
    SetPlayerRoutingBucket(tostring(targetSrc), targetSrc)
    TriggerClientEvent('lobby:displayLobby', targetSrc)

    Admin.frozen[targetSrc] = nil
    Admin.god[targetSrc] = nil

    Admin.notify(adminSrc, 'success', ('%s foi enviado para o lobby.'):format(Admin.playerName(targetSrc)))
    Admin.notify(targetSrc, 'importante', 'Voce foi enviado para o lobby por um admin.')
end

---Kick the target (no ban).
---@param adminSrc number
---@param targetSrc number
---@param reason? string
function Admin.act.kick(adminSrc, targetSrc, reason)
    reason = (reason and reason ~= '') and tostring(reason) or 'Expulso por um admin'
    Admin.notify(adminSrc, 'success', ('%s foi expulso. Motivo: %s'):format(Admin.playerName(targetSrc), reason))
    DropPlayer(tostring(targetSrc), reason)
end

---Change a user's role (works for online and offline users).
---@param adminSrc number
---@param userId number
---@param role string
function Admin.act.setRole(adminSrc, userId, role)
    if not VALID_ROLES[role] then
        return Admin.notify(adminSrc, 'error', 'Cargo invalido (user/admin/spec).')
    end
    Admin.db.execute('UPDATE `users` SET `role` = ? WHERE `id` = ?', { role, userId })
    Core.updateUserInfo(userId, { role = role })
    Admin.notify(adminSrc, 'success', ('Cargo do usuario %s alterado para %s.'):format(userId, role))
end

---Set an integer stat (xp/gems) on a user.
---@param adminSrc number
---@param userId number
---@param field string
---@param value number
function Admin.act.setStat(adminSrc, userId, field, value)
    if not VALID_STATS[field] then
        return Admin.notify(adminSrc, 'error', 'Campo invalido (xp/gems).')
    end
    value = math.max(0, math.floor(tonumber(value) or 0))
    -- field is whitelisted above, safe to interpolate.
    Admin.db.execute(('UPDATE `users` SET `%s` = ? WHERE `id` = ?'):format(field), { value, userId })
    Core.updateUserInfo(userId, { [field] = value })
    Admin.notify(adminSrc, 'success', ('%s do usuario %s definido para %d.'):format(field, userId, value))
end

---@param adminSrc number
---@param userId number
function Admin.act.unban(adminSrc, userId)
    local removed = Admin.bans:remove(userId)
    if not removed then
        return Admin.notify(adminSrc, 'warning', ('O usuario %s nao esta banido.'):format(userId))
    end
    Admin.notify(adminSrc, 'success', ('Usuario %s desbanido com sucesso.'):format(userId))
end

---@return table | nil
local function getInventarioApi()
    local ok, api = pcall(function() return exports['lobby_inventory']:GetInventario() end)
    if not ok or not api then return nil end
    return api
end

---@param adminSrc number
---@param targetUserId number
---@param itemId string
function Admin.act.grantInventario(adminSrc, targetUserId, itemId)
    targetUserId = tonumber(targetUserId)
    if not targetUserId or not itemId or itemId == '' then
        return Admin.notify(adminSrc, 'error', 'Uso: alvo + id do item.')
    end

    local exists = Admin.db.single('SELECT 1 AS ok FROM `users` WHERE `id` = ?', { targetUserId })
    if not exists then
        return Admin.notify(adminSrc, 'error', ('Usuario %s nao existe.'):format(targetUserId))
    end

    local api = getInventarioApi()
    if not api then
        return Admin.notify(adminSrc, 'error', 'Resource inventario indisponivel.')
    end

    local _, adminUserId = Admin.isAdmin(adminSrc)
    local sourceRef = tostring(adminUserId or 0)

    local ok, result = pcall(function()
        return api:grant(targetUserId, itemId, 'admin', sourceRef)
    end)
    if not ok then
        Admin.log('error', ('grantInventario failed: %s'):format(tostring(result)))
        return Admin.notify(adminSrc, 'error', 'Falha ao conceder o item.')
    end

    if not result or not result.ok then
        return Admin.notify(adminSrc, 'error', 'Nao foi possivel conceder o item (item invalido?).')
    end

    if result.alreadyOwned then
        Admin.notify(adminSrc, 'info', ('Usuario %s ja possuia %s.'):format(targetUserId, itemId))
    else
        Admin.notify(adminSrc, 'success', ('Inventarioo %s concedido a %s.'):format(itemId, targetUserId))
    end
end

---@param adminSrc number
---@param targetUserId number
---@param itemId string
function Admin.act.revokeInventario(adminSrc, targetUserId, itemId)
    targetUserId = tonumber(targetUserId)
    if not targetUserId or not itemId or itemId == '' then
        return Admin.notify(adminSrc, 'error', 'Uso: alvo + id do item.')
    end

    local api = getInventarioApi()
    if not api then
        return Admin.notify(adminSrc, 'error', 'Resource inventario indisponivel.')
    end

    local ok, result = pcall(function()
        return api:revoke(targetUserId, itemId)
    end)
    if not ok then
        Admin.log('error', ('revokeInventario failed: %s'):format(tostring(result)))
        return Admin.notify(adminSrc, 'error', 'Falha ao revogar o item.')
    end

    Admin.notify(adminSrc, 'success', ('Inventarioo %s revogado de %s.'):format(itemId, targetUserId))
end

AddEventHandler('playerDropped', function()
    local src = source
    Admin.frozen[src] = nil
    Admin.god[src] = nil
    Admin.playerMode[src] = nil
    Admin.specPrevBucket[src] = nil
end)
