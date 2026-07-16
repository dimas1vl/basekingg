RegisterNetEvent('domination:shop:buy', function(category, weaponId)
    local src = source
    local session = sessions[src]
    if not session then return end
    if type(category) ~= 'string' or type(weaponId) ~= 'string' then return end

    local userId = session.userId
    if not userId then return notify(src, 'error', 'Jogador não identificado.') end

    local weaponCfg, catKey = DomCfg.findWeapon(weaponId, category)
    if not weaponCfg or catKey ~= category then
        return notify(src, 'error', 'Arma inválida.')
    end

    if weaponCfg.default or (tonumber(weaponCfg.price) or 0) <= 0 or session.owned[weaponId] then
        return notify(src, 'info', 'Você já possui essa arma.')
    end

    session.level = DomCfg.levelFromXp(session.xp)
    if session.level < weaponCfg.level then
        notify(src, 'error', ('Requer nível %d.'):format(weaponCfg.level))
        return pushState(src)
    end

    local price = math.floor(tonumber(weaponCfg.price) or 0)

    if (session.money or 0) < price then
        notify(src, 'error', 'Dinheiro insuficiente.')
        return pushState(src)
    end

    session.owned[weaponId] = true
    session.money = (session.money or 0) - price
    markDirty(session)

    local ok, err = pcall(function()
        Sql.execute('INSERT IGNORE INTO `domination_weapons` (`user_id`, `weapon_id`) VALUES (?, ?)', { userId, weaponId })
    end)
    if not ok then
        session.owned[weaponId] = nil
        session.money = (session.money or 0) + price
        markDirty(session)
        print(('^1[dom-sv] buy falhou: %s^7'):format(tostring(err)))
        return notify(src, 'error', 'Falha na compra.')
    end

    flushProgress(session)

    notify(src, 'success', ('Comprou %s por %d de dinheiro.'):format(weaponCfg.label, price))
    pushState(src)
end)

RegisterNetEvent('domination:shop:equip', function(category, weaponId)
    local src = source
    local session = sessions[src]
    if not session then return end
    if type(category) ~= 'string' or type(weaponId) ~= 'string' then return end

    local weaponCfg, catKey = DomCfg.findWeapon(weaponId, category)
    if not weaponCfg or catKey ~= category then
        return notify(src, 'error', 'Arma inválida.')
    end
    if not sessionOwns(session, weaponCfg) then
        return notify(src, 'error', 'Você não possui essa arma.')
    end

    session.equipped[category] = weaponId

    if session.userId then
        Sql.execute(
            'REPLACE INTO `domination_loadout` (`user_id`, `category`, `weapon_id`) VALUES (?, ?, ?)',
            { session.userId, category, weaponId }
        )
    end

    local cat = DomCfg.getCategory(category)
    TriggerClientEvent('domination:equip', src, {
        category = category,
        id       = weaponId,
        slot     = cat and cat.slot or nil,
        weapon   = weaponCfg.weapon,
    })

    pushState(src)
end)
