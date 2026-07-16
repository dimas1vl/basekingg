RegisterCommand('dom_addxp', function(src, args)
    if src == 0 then
        print('^3[dom-sv] dom_addxp só funciona em jogo (precisa estar numa zona).^7')
        return
    end
    local session = sessions[src]
    if not session or not session.userId then
        return notify(src, 'error', 'Entre numa zona de Dominação primeiro.')
    end

    if not (Core.hasRole and Core.hasRole(session.userId, 'admin')) then
        return notify(src, 'error', 'Sem permissão.')
    end
    local amount = math.floor(tonumber(args[1]) or 0)
    if amount == 0 then return notify(src, 'error', 'Uso: /dom_addxp <quantidade>') end

    session.xp = math.max(0, (session.xp or 0) + amount)
    session.level = DomCfg.levelFromXp(session.xp)
    markDirty(session)
    notify(src, 'success', ('XP de Dominação: %d (nível %d)'):format(session.xp, session.level))
    pushState(src)
end, false)

RegisterCommand('dom_addgems', function(src, args)
    if src == 0 then
        print('^3[dom-sv] dom_addgems só funciona em jogo (precisa estar numa zona).^7')
        return
    end
    local session = sessions[src]
    if not session or not session.userId then
        return notify(src, 'error', 'Entre numa zona de Dominação primeiro.')
    end
    if not (Core.hasRole and Core.hasRole(session.userId, 'admin')) then
        return notify(src, 'error', 'Sem permissão.')
    end
    local amount = math.floor(tonumber(args[1]) or 0)
    if amount == 0 then return notify(src, 'error', 'Uso: /dom_addgems <quantidade>') end

    session.money = math.max(0, (session.money or 0) + amount)
    markDirty(session)

    notify(src, 'success', ('Dinheiro: %d'):format(session.money))
    pushState(src)
end, false)

-- forca um novo sorteio de layout (mesmo efeito do RR, sem precisar reiniciar)
RegisterCommand('dom_reroll', function(src)
    if src == 0 then
        applyDominationLayout(true)
        print('^2[dom-sv] layout de dominacao re-sorteado (console).^7')
        return
    end
    local session = sessions[src]
    if not session or not session.userId then
        return notify(src, 'error', 'Entre numa zona de Dominação primeiro.')
    end
    if not (Core.hasRole and Core.hasRole(session.userId, 'admin')) then
        return notify(src, 'error', 'Sem permissão.')
    end
    applyDominationLayout(true)
    notify(src, 'success', 'Zonas de dominação re-sorteadas.')
end, false)

AddEventHandler('playerDropped', function()
    leaveZone(source)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    flushAllProgress()
    if SHARED_BUCKET then
        Core.releaseBucket(SHARED_BUCKET)
        SHARED_BUCKET = nil
    end
    if LOCATION_BUCKETS then
        for _, b in pairs(LOCATION_BUCKETS) do Core.releaseBucket(b) end
        LOCATION_BUCKETS = nil
    end
end)

exports('getSafeZones', function()
    local list = {}
    if DomCfg and DomCfg.safeZones then
        for i = 1, #DomCfg.safeZones do
            local z = DomCfg.safeZones[i]
            list[#list + 1] = { id = z.id, label = z.label }
        end
    end
    return list
end)

exports('isInZone', function(src)
    return sessions[tonumber(src)] ~= nil
end)
