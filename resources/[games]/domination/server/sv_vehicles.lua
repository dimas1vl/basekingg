---@param userId number
---@return table<string, boolean>
function loadOwnedVehicles(userId)
    local owned = {}
    local rows = Sql.query('SELECT `vehicle_id` FROM `domination_vehicles` WHERE `user_id` = ?', { userId })
    if rows then
        for i = 1, #rows do owned[rows[i].vehicle_id] = true end
    end
    return owned
end

---@param userId number
---@return table<string, boolean>
function loadVehicleFavorites(userId)
    local favs = {}
    local rows = Sql.query('SELECT `vehicle_id` FROM `domination_vehicle_favorites` WHERE `user_id` = ?', { userId })
    if rows then
        for i = 1, #rows do favs[rows[i].vehicle_id] = true end
    end
    return favs
end

function meetsRequirement(info, req)
    if not req then return true end
    if not info then return false end
    if req == 'vip' then
        return tonumber(info.premium) == 1
    elseif req == 'streamer' then
        return info.role == 'streamer' or info.role == 'admin'
    elseif req == 'exclusive' then
        return info.role == 'admin'
    end
    return false
end

function buildVehicleState(src, session)
    local info  = Core.getUserInfo(src)
    local level = DomCfg.levelFromXp(session.xp or 0)
    local owned = session.ownedVehicles or {}
    local favs  = session.favorites or {}

    local categories = {}
    for i = 1, #DomCfg.vehicleCategories do
        local cat  = DomCfg.vehicleCategories[i]
        local list = DomCfg.vehicles[cat.key] or {}
        local vehicles = {}
        for j = 1, #list do
            local v       = list[j]
            local price   = tonumber(v.price) or 0
            local reqLvl  = tonumber(v.level) or 0
            local isOwned = price > 0 and owned[v.id] == true
            local reqOk   = meetsRequirement(info, v.requires)
            local levelOk = level >= reqLvl

            local action
            if not reqOk then
                action = 'req'
            elseif not levelOk and not isOwned then
                action = 'locked'
            elseif price > 0 and not isOwned then
                action = 'buy'
            else
                action = 'spawn'
            end

            vehicles[#vehicles + 1] = {
                id       = v.id,
                label    = v.label,
                image    = v.image,
                level    = reqLvl,
                price    = price,
                requires = v.requires,
                action   = action,
                favorite = favs[v.id] == true,
            }
        end
        categories[#categories + 1] = { key = cat.key, label = cat.label, vehicles = vehicles }
    end

    return {
        level     = level,
        gems      = getGems(src),
        imageBase = DomCfg.vehicleImageBase,
        categories = categories,
    }
end

function pushVehicleState(src)
    local session = sessions[src]
    if not session then return end
    TriggerClientEvent('domination:veh:state', src, buildVehicleState(src, session))
end

RegisterNetEvent('domination:veh:state:request', function()
    local src = source
    if not sessions[src] then return end
    pushVehicleState(src)
end)

RegisterNetEvent('domination:veh:buy', function(category, vehId)
    local src = source
    local session = sessions[src]
    if not session then return end
    if type(category) ~= 'string' or type(vehId) ~= 'string' then return end

    local userId = session.userId
    if not userId then return notify(src, 'error', 'Jogador não identificado.') end

    local v, catKey = DomCfg.findVehicle(vehId, category)
    if not v or catKey ~= category then return notify(src, 'error', 'Veículo inválido.') end

    local price = math.floor(tonumber(v.price) or 0)
    if price <= 0 or session.ownedVehicles[vehId] then
        return notify(src, 'info', 'Você já possui esse veículo.')
    end

    if not meetsRequirement(Core.getUserInfo(src), v.requires) then
        notify(src, 'error', 'Você não tem acesso a esse veículo.')
        return pushVehicleState(src)
    end

    local level = DomCfg.levelFromXp(session.xp or 0)
    if level < (tonumber(v.level) or 0) then
        notify(src, 'error', ('Requer nível %d.'):format(v.level))
        return pushVehicleState(src)
    end

    if (session.money or 0) < price then
        notify(src, 'error', 'Dinheiro insuficiente.')
        return pushVehicleState(src)
    end

    session.ownedVehicles[vehId] = true
    session.money = (session.money or 0) - price
    markDirty(session)

    local ok = pcall(function()
        Sql.execute('INSERT IGNORE INTO `domination_vehicles` (`user_id`, `vehicle_id`) VALUES (?, ?)', { userId, vehId })
    end)
    if not ok then
        session.ownedVehicles[vehId] = nil
        session.money = (session.money or 0) + price
        markDirty(session)
        return notify(src, 'error', 'Falha na compra.')
    end

    flushProgress(session)
    notify(src, 'success', ('Comprou %s por %d de dinheiro.'):format(v.label, price))
    pushVehicleState(src)
    pushState(src)
end)

RegisterNetEvent('domination:veh:spawn', function(category, vehId)
    local src = source
    local session = sessions[src]
    if not session then return end
    if type(category) ~= 'string' or type(vehId) ~= 'string' then return end

    local now = GetGameTimer()
    if now - (session.lastVehSpawn or 0) < 2000 then return end

    local v, catKey = DomCfg.findVehicle(vehId, category)
    if not v or catKey ~= category then return end

    local isOwned = (tonumber(v.price) or 0) > 0 and session.ownedVehicles[vehId] == true

    if not meetsRequirement(Core.getUserInfo(src), v.requires) then
        return notify(src, 'error', 'Você não tem acesso a esse veículo.')
    end

    local level = DomCfg.levelFromXp(session.xp or 0)
    if level < (tonumber(v.level) or 0) and not isOwned then
        return notify(src, 'error', ('Requer nível %d.'):format(v.level))
    end
    if (tonumber(v.price) or 0) > 0 and not isOwned then
        return notify(src, 'error', 'Compre o veículo primeiro.')
    end

    session.lastVehSpawn = now
    TriggerClientEvent('domination:veh:do_spawn', src, { model = v.model, label = v.label })
end)

RegisterNetEvent('domination:veh:favorite', function(category, vehId, fav)
    local src = source
    local session = sessions[src]
    if not session or not session.userId then return end
    if type(category) ~= 'string' or type(vehId) ~= 'string' then return end

    local v, catKey = DomCfg.findVehicle(vehId, category)
    if not v or catKey ~= category then return end

    if fav then
        session.favorites[vehId] = true
        Sql.execute('INSERT IGNORE INTO `domination_vehicle_favorites` (`user_id`, `vehicle_id`) VALUES (?, ?)', { session.userId, vehId })
    else
        session.favorites[vehId] = nil
        Sql.execute('DELETE FROM `domination_vehicle_favorites` WHERE `user_id` = ? AND `vehicle_id` = ?', { session.userId, vehId })
    end
    pushVehicleState(src)
end)
