Admin:command('nc', function(src)
    TriggerClientEvent('admin:noclip:toggle', src)
    Admin.notify(src, 'success', 'Noclip alternado.')
end)

Admin:command('tpto', function(src, args)
    local target = Admin.resolveOnline(args[1])
    if not target then
        return Admin.notify(src, 'error', 'Uso: /tpto [id do personagem] (jogador online nao encontrado).')
    end
    Admin.act.tpto(src, target)
end)

Admin:command('tptome', function(src, args)
    local target = Admin.resolveOnline(args[1])
    if not target then
        return Admin.notify(src, 'error', 'Uso: /tptome [id do personagem] (jogador online nao encontrado).')
    end
    Admin.act.tptome(src, target)
end)

Admin:command('spec', function(src, args)
    if not args[1] then
        if Admin.specPrevBucket[src] ~= nil then
            TriggerClientEvent('admin:spec:stop', src)
            return
        end
        return Admin.notify(src, 'error', 'Uso: /spec [id do personagem]. Use /spec novamente para sair.')
    end

    local target = Admin.resolveOnline(args[1])
    if not target then
        return Admin.notify(src, 'error', 'Uso: /spec [id do personagem] (jogador online nao encontrado).')
    end
    Admin.act.spectate(src, target)
end)

Admin:command('freeze', function(src, args)
    local target = Admin.resolveOnline(args[1])
    if not target then
        return Admin.notify(src, 'error', 'Uso: /freeze [id do personagem] (jogador online nao encontrado).')
    end
    Admin.act.freeze(src, target)
end)

Admin:command('god', function(src, args)
    local target = src
    if args[1] then
        target = Admin.resolveOnline(args[1])
        if not target then
            return Admin.notify(src, 'error', 'Uso: /god [id do personagem] (jogador online nao encontrado).')
        end
    end
    Admin.act.god(src, target)
end)

Admin:command('setarlobby', function(src, args)
    local target = Admin.resolveOnline(args[1])
    if not target then
        return Admin.notify(src, 'error', 'Uso: /setarlobby [id do personagem] (jogador online nao encontrado).')
    end
    Admin.act.setarlobby(src, target)
end)

Admin:command('kick', function(src, args)
    local target = Admin.resolveOnline(args[1])
    if not target then
        return Admin.notify(src, 'error', 'Uso: /kick [id do personagem] [motivo].')
    end
    local reason = table.concat(args, ' ', 2)
    Admin.act.kick(src, target, reason)
end)

Admin:command('cds', function(src)
    TriggerClientEvent('admin:cds:open', src)
end)

Admin:command('criar_zona', function(src)
    TriggerClientEvent('admin:zonebuilder:start', src)
end)

Admin:command('tpcds', function(src)
    TriggerClientEvent('admin:tpcds:open', src)
end)

Admin:command('ban', function(src, args)
    local userId = tonumber(args[1])
    if not userId then
        return Admin.notify(src, 'error', 'Uso: /ban [id do personagem].')
    end

    local exists = Admin.db.single('SELECT `id` FROM `users` WHERE `id` = ?', { userId })
    if not exists then
        return Admin.notify(src, 'error', ('Usuario %s nao existe.'):format(userId))
    end

    local name, onlineSrc = Admin.getUserName(userId)
    TriggerClientEvent('admin:ban:open', src, {
        targetSrc = onlineSrc or 0,
        targetUserId = userId,
        targetName = name,
    })
end)

RegisterNetEvent('net.admin:submitBan', function(payload)
    local src = source
    local allowed, staffId = Admin.isAdmin(src)
    if not allowed then
        return Admin.notify(src, 'error', 'Voce nao tem permissao.')
    end
    if type(payload) ~= 'table' then return end

    local targetUserId = tonumber(payload.targetUserId)
    local days = tonumber(payload.days) or 0
    local reason = tostring(payload.reason or 'Sem motivo')
    if not targetUserId then
        return Admin.notify(src, 'error', 'Alvo invalido.')
    end

    Admin.bans:create(targetUserId, staffId, days, reason)

    local targetSrc = Core.getUserSource(targetUserId)
    if targetSrc and DoesPlayerExist(targetSrc) then
        DropPlayer(tostring(targetSrc), ('Voce foi banido do servidor por %s'):format(reason))
    end

    local durationText = days <= 0 and 'permanentemente' or ('por %d dia(s)'):format(days)
    Admin.notify(src, 'success', ('Usuario %s banido %s. Motivo: %s'):format(targetUserId, durationText, reason))
end)

Admin:command('unban', function(src, args)
    local userId = tonumber(args[1])
    if not userId then
        return Admin.notify(src, 'error', 'Uso: /unban [user_id].')
    end
    Admin.act.unban(src, userId)
end)

Admin:command('conceder', function(src, args)
    local userId = tonumber(args[1])
    local itemId = args[2]
    if not userId or not itemId or itemId == '' then
        return Admin.notify(src, 'error', 'Uso: /conceder [id do personagem] [id do item].')
    end
    Admin.act.grantInventario(src, userId, itemId)
end)

Admin:command('revogar', function(src, args)
    local userId = tonumber(args[1])
    local itemId = args[2]
    if not userId or not itemId or itemId == '' then
        return Admin.notify(src, 'error', 'Uso: /revogar [id do personagem] [id do item].')
    end
    Admin.act.revokeInventario(src, userId, itemId)
end)

Admin:command('verban', function(src, args)
    local userId = tonumber(args[1])
    if not userId then
        return Admin.notify(src, 'error', 'Uso: /verban [user_id].')
    end

    local info = Admin.bans:get(userId)
    if not info then
        return Admin.notify(src, 'info', ('O usuario %s nao possui ban registrado.'):format(userId))
    end

    local staff = info.staff_name or ('id ' .. tostring(info.staff_id))
    local message = ('Ban de %s | %s | Motivo: %s | Admin: %s'):format(
        info.target_name or ('user ' .. userId),
        Admin.formatDate(info.created_at),
        info.reason or 'Sem motivo',
        staff
    )
    Admin.notify(src, 'info', message, 10)
end)

Admin.log('info', 'Admin commands registered')
