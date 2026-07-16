function loadSession(src, zoneId)
    local userId = Core.getUserId(src)
    local session = {
        zoneId        = zoneId,
        userId        = userId,
        kills         = 0,
        deaths        = 0,
        lastDeath     = 0,
        lastVehSpawn  = 0,
        owned         = {},
        ownedVehicles = {},
        favorites     = {},
        equipped      = {},
    }
    if userId then
        session.xp, session.money = loadProgress(userId)
        session.owned  = loadOwned(userId)
        session.ownedVehicles = loadOwnedVehicles(userId)
        session.favorites = loadVehicleFavorites(userId)
        session.equipped = resolveEquipped(session, loadLoadout(userId))
        Sql.execute('UPDATE `users` SET `last_login` = current_timestamp() WHERE `id` = ?', { userId })
    else
        session.xp = 0
        session.money = 0
        session.equipped = resolveEquipped(session, {})
    end
    session.level = DomCfg.levelFromXp(session.xp)
    sessions[src] = session
    return session
end

function findZone(zoneId)
    local list = DomCfg.safeZones
    for i = 1, #list do
        if list[i].id == zoneId then return list[i] end
    end
    return nil
end

function findDominationZone(zoneId)
    local list = DomCfg.dominationZones
    for i = 1, #list do
        if list[i].id == zoneId then return list[i] end
    end
    return nil
end

function releaseLobbyMinigames(src)
    local ok, isIn = pcall(function() return exports['lobby_minigames']:isInArea(src) end)
    print(('^5[dom-sv] releaseLobbyMinigames: isInArea ok=%s isIn=%s^7'):format(tostring(ok), tostring(isIn)))
    if ok and isIn then
        pcall(function() exports['lobby_minigames']:releaseSession(src) end)
        TriggerClientEvent('lobby_minigames:handover', src)
    end
end

function notify(src, kind, msg)
    if not src or src == 0 then return end
    TriggerClientEvent('Notify', src, kind or 'info', msg, 5)
end

function enterZone(src, zoneId)
    print(('^5[dom-sv] enterZone src=%d zoneId=%s^7'):format(src, tostring(zoneId)))
    local zone = findZone(zoneId)
    if not zone then
        print('^1[dom-sv] zona nao encontrada na config^7')
        return notify(src, 'error', 'Zona invalida.')
    end

    if Core.getPlayerMatch and Core.getPlayerMatch(src) then
        print('^1[dom-sv] rejeitado: player ja em match^7')
        return notify(src, 'error', 'Voce ja esta em uma partida.')
    end

    local userId = Core.getUserId(src)
    if not userId then
        return notify(src, 'error', 'Erro ao carregar seu perfil, tente novamente.')
    end

    releaseLobbyMinigames(src)

    local session = loadSession(src, zoneId)
    SetPlayerRoutingBucket(tostring(src), SHARED_BUCKET)
    zoneBucketAt[src] = SHARED_BUCKET
    print(('^5[dom-sv] bucket=%d setado, disparando domination:enter pro src=%d (lvl=%d)^7'):format(SHARED_BUCKET, src, session.level))

    TriggerClientEvent('domination:enter', src, {
        id     = zone.id,
        label  = zone.label,
        center = { x = zone.center.x, y = zone.center.y, z = zone.center.z, w = zone.center.w },
        radius = zone.radius,
        layout = domLayout,
        state  = buildState(src, session),
        zones  = buildZoneSnapshot(),
        flags  = buildFlagSnapshot(),
    })

    print(('^2[dom-sv] player %d entered zone "%s" (concluido)^7'):format(src, zoneId))
end

function leaveZone(src)
    if not sessions[src] then return end
    flushProgress(sessions[src])
    flagOnPlayerGone(src)
    sessions[src] = nil
    if domSpectating then domSpectating[src] = nil end
    if notifyKillcamWatchers then notifyKillcamWatchers(src) end
    if domDownedSet and domDownedSet[src] then
        domDownedSet[src] = nil
        for s in pairs(sessions) do TriggerClientEvent('domination:downed', s, src, false) end
    end
    lastKiller[src] = nil
    reportAt[src]   = nil
    zonePresence[src] = nil
    zoneBucketAt[src] = nil
    lastHereZone[src] = nil
    if DoesPlayerExist(tostring(src)) then
        SetPlayerRoutingBucket(tostring(src), src)
    end
    TriggerClientEvent('domination:leave', src)
    pcall(function() exports['lobby_minigames']:enterArea(src) end)
    print(('[dom-sv] player %d left zone, retornando pra minigames area'):format(src))
end

RegisterNetEvent('domination:enter', function(zoneId)
    local src = source
    print(('^5[dom-sv] NET domination:enter src=%d zoneId=%s^7'):format(src, tostring(zoneId)))
    if type(zoneId) ~= 'string' or zoneId == '' then
        print('^1[dom-sv] zoneId invalido, abortando^7')
        return
    end
    enterZone(src, zoneId)
end)

RegisterNetEvent('domination:leave', function()
    leaveZone(source)
end)

RegisterNetEvent('domination:state:request', function()
    local src = source
    if not sessions[src] then return end
    pushState(src)
end)

RegisterNetEvent('domination:relocate', function(zoneId)
    local src = source
    local session = sessions[src]
    if not session then return end
    if type(zoneId) ~= 'string' or not findZone(zoneId) then return end
    session.zoneId = zoneId
end)

zonePresence = {}
zoneRuntime  = {}
zoneBucketAt = {}
lastHereZone = {}

HIDDEN_TYPES = { oculta = true, oculta_xp2 = true }

function zoneBucketFor(zone)
    if zone and HIDDEN_TYPES[zone.type] and LOCATION_BUCKETS and LOCATION_BUCKETS[zone.id] then
        return LOCATION_BUCKETS[zone.id]
    end
    return SHARED_BUCKET
end

function applyZoneBucket(src, zone)
    local want = zoneBucketFor(zone)
    if zoneBucketAt[src] == want then return end
    zoneBucketAt[src] = want
    if DoesPlayerExist(tostring(src)) then
        local ped = GetPlayerPed(src)
        local veh = (ped and ped ~= 0) and GetVehiclePedIsIn(ped, false) or 0
        if veh and veh ~= 0 then
            SetEntityRoutingBucket(veh, want)
        end
        SetPlayerRoutingBucket(tostring(src), want)
    end
    TriggerClientEvent('domination:veh:dropOrphan', src)
end

flagState = {}
FLAG_RETURN_MS = (DomCfg.flag and tonumber(DomCfg.flag.returnMs)) or 30000

function flagEnsure(z)
    local fs = flagState[z.id]
    if not fs then
        fs = { holderSrc = nil, holderTeam = nil, holderName = nil,
               x = z.center.x, y = z.center.y, z = z.center.z, dropped = false, droppedAt = nil }
        flagState[z.id] = fs
    end
    return fs
end

function flagBroadcast(zoneId)
    local fs = flagState[zoneId]
    if not fs then return end
    TriggerClientEvent('domination:flag', -1, zoneId, {
        holder  = fs.holderSrc,
        x = fs.x, y = fs.y, z = fs.z,
        dropped = fs.dropped and true or false,
    })
end

function flagReturnToCenter(z)
    local fs = flagEnsure(z)
    fs.holderSrc, fs.holderTeam, fs.holderName = nil, nil, nil
    fs.x, fs.y, fs.z = z.center.x, z.center.y, z.center.z
    fs.dropped, fs.droppedAt = false, nil
    flagBroadcast(z.id)
end

function flagDropAt(z, px, py, pz)
    local fs = flagEnsure(z)
    fs.holderSrc, fs.holderTeam, fs.holderName = nil, nil, nil
    fs.x, fs.y, fs.z = px, py, pz
    fs.dropped, fs.droppedAt = true, GetGameTimer()
    flagBroadcast(z.id)
end

function buildFlagSnapshot()
    local out = {}
    for zoneId, fs in pairs(flagState) do
        out[#out + 1] = { id = zoneId, holder = fs.holderSrc, x = fs.x, y = fs.y, z = fs.z, dropped = fs.dropped and true or false }
    end
    return out
end

function flagDropOnDeath(src, dx, dy, dz)
    for zoneId, fs in pairs(flagState) do
        if fs.holderSrc == src then
            local z = findDominationZone(zoneId)
            if z then
                dx, dy, dz = tonumber(dx), tonumber(dy), tonumber(dz)
                if dx and dy and dz then flagDropAt(z, dx, dy, dz) else flagReturnToCenter(z) end
            end
            return
        end
    end
end

function flagOnPlayerGone(src)
    for zoneId, fs in pairs(flagState) do
        if fs.holderSrc == src then
            local z = findDominationZone(zoneId)
            if z then flagReturnToCenter(z) else fs.holderSrc = nil; flagBroadcast(zoneId) end
        end
    end
end

function initFlags()
    flagState = {}
    local zones = DomCfg.dominationZones or {}
    for i = 1, #zones do
        if zones[i].type == 'bandeira' then flagEnsure(zones[i]) end
    end
end

function flagBroadcastAll()
    for zoneId in pairs(flagState) do flagBroadcast(zoneId) end
end

RegisterNetEvent('domination:flag:grab', function(zoneId)
    local src = source
    if not sessions[src] then return end
    if type(zoneId) ~= 'string' then return end
    local z = findDominationZone(zoneId)
    if not z or z.type ~= 'bandeira' then return end
    local rt = zoneRuntime[zoneId]
    if rt and rt.cooldownUntil and rt.cooldownUntil > GetGameTimer() then
        return notify(src, 'info', 'Zona em COOLDOWN, espere liberar.')
    end
    local fs = flagEnsure(z)
    if fs.holderSrc then return end
    if lastHereZone[src] ~= zoneId then return end
    local teamId, teamName = teamOf(src)
    if not teamId then return notify(src, 'error', 'Você precisa de um TIME pra pegar a bandeira.') end
    fs.holderSrc, fs.holderTeam, fs.holderName = src, teamId, teamName
    fs.dropped, fs.droppedAt = false, nil
    flagBroadcast(zoneId)
    notify(src, 'success', 'Você pegou a BANDEIRA! Segure dentro da zona pra dominar.')
end)

function updateFlagZone(z, rt, now)
    local fs = flagEnsure(z)

    if rt.cooldownUntil and rt.cooldownUntil <= now then
        rt.cooldownUntil = nil; rt.ownerName = nil; rt.progress = 0; rt.holdTeam = nil; rt.capturingName = nil
        broadcastZoneState(z.id, {})
    end
    if rt.cooldownUntil then
        if fs.holderSrc then flagReturnToCenter(z) end
        return
    end

    if fs.holderSrc and (not sessions[fs.holderSrc] or lastHereZone[fs.holderSrc] ~= z.id) then
        flagReturnToCenter(z)
    end
    if not fs.holderSrc and fs.dropped and fs.droppedAt and (now - fs.droppedAt) >= FLAG_RETURN_MS then
        flagReturnToCenter(z)
    end

    if fs.holderSrc and sessions[fs.holderSrc] then
        if rt.holdTeam ~= fs.holderTeam then rt.holdTeam = fs.holderTeam; rt.progress = 0 end
        rt.progress = (rt.progress or 0) + 1
        local cap = tonumber(z.captureSeconds) or 120
        local pct = math.min(100, math.floor((rt.progress / cap) * 100))
        if rt.capturingName ~= fs.holderName then
            rt.capturingName = fs.holderName
            broadcastZoneState(z.id, { cap = fs.holderName })
            broadcastZoneFeed('start', fs.holderName, z.label)
        end
        for src, p in pairs(zonePresence) do
            if p.zoneId == z.id and sessions[src] then
                if p.teamId == fs.holderTeam then
                    TriggerClientEvent('domination:progress', src, { zone = z.label, team = fs.holderName, members = 1, pct = pct, color = z.marker })
                else
                    TriggerClientEvent('domination:progress', src, false)
                end
            end
        end
        local interval = tonumber(z.rewardInterval) or 5
        if interval > 0 and (rt.progress % interval) == 0 then
            awardDomination(z, fs.holderTeam)
        end
        if rt.progress >= cap then
            rt.ownerName     = fs.holderName
            rt.cooldownUntil = now + (tonumber(z.cooldown) or 0) * 1000
            rt.progress      = 0
            rt.holdTeam      = nil
            rt.capturingName = nil
            broadcastZoneState(z.id, { cd = true, ms = (tonumber(z.cooldown) or 0) * 1000 })
            broadcastZoneFeed('captured', fs.holderName, z.label)
            for src, p in pairs(zonePresence) do
                if p.zoneId == z.id and sessions[src] then TriggerClientEvent('domination:progress', src, false) end
            end
            flagReturnToCenter(z)
        end
    else
        rt.progress = 0; rt.holdTeam = nil
        if rt.capturingName then
            rt.capturingName = nil
            broadcastZoneState(z.id, {})
        end
    end
end

domLayout = {}

local function shuffleInPlace(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

function rollDominationLayout()
    local locs  = DomCfg.locations or {}
    local types = DomCfg.zoneTypes or {}
    local nLoc, nType = #locs, #types
    domLayout = {}
    if nLoc == 0 or nType == 0 then
        DomCfg.dominationZones = {}
        return domLayout
    end

    local limits = DomCfg.zoneLimits or {}
    local capped, free = {}, {}
    for i = 1, nType do
        local key = types[i].key
        if limits[key] ~= nil then capped[#capped + 1] = key else free[#free + 1] = key end
    end
    if #free == 0 then
        for i = 1, nType do free[#free + 1] = types[i].key end
    end

    local bag = {}
    for i = 1, #capped do
        local cap = math.max(0, math.floor(tonumber(limits[capped[i]]) or 0))
        for _ = 1, cap do
            if #bag >= nLoc then break end
            bag[#bag + 1] = capped[i]
        end
    end
    shuffleInPlace(free)
    local fi = 0
    while #bag < nLoc do
        bag[#bag + 1] = free[(fi % #free) + 1]
        fi = fi + 1
    end
    shuffleInPlace(bag)

    for k = 1, nLoc do
        domLayout[locs[k].id] = bag[k]
    end

    DomCfg.dominationZones = DomCfg.buildDominationZones(domLayout)
    return domLayout
end

function applyDominationLayout(reroll)
    if reroll or not next(domLayout) then
        rollDominationLayout()
        zoneRuntime  = {}
        zonePresence = {}
        initFlags()
        for src in pairs(sessions) do
            local hz = lastHereZone[src]
            applyZoneBucket(src, hz and findDominationZone(hz) or nil)
        end
    end
    TriggerClientEvent('domination:layout', -1, domLayout)
    flagBroadcastAll()
    print(('^2[dom-sv] layout sorteado (%d zonas): %s^7'):format(#DomCfg.dominationZones, json.encode(domLayout)))
    return domLayout
end

math.randomseed(os.time())
rollDominationLayout()
initFlags()

CreateThread(function()
    Wait(500)
    TriggerClientEvent('domination:layout', -1, domLayout)
    flagBroadcastAll()
end)

RegisterNetEvent('domination:layout:request', function()
    TriggerClientEvent('domination:layout', source, domLayout)
end)

function teamOf(src)
    local userId = Core.getUserId(src)
    if not userId then return nil end
    local mem = getMember(userId)
    if not mem then return nil end
    local row = Sql.single('SELECT `name` FROM `domination_teams` WHERE `id` = ?', { mem.team_id })
    return mem.team_id, (row and row.name) or ('Time ' .. tostring(mem.team_id)), isTeamPremium(mem.team_id)
end

function buildZoneSnapshot()
    local snap, now = {}, GetGameTimer()
    for zoneId, rt in pairs(zoneRuntime) do
        if rt.cooldownUntil and rt.cooldownUntil > now then
            snap[#snap + 1] = { id = zoneId, cd = true, ms = rt.cooldownUntil - now }
        elseif rt.contestedShown then
            snap[#snap + 1] = { id = zoneId, contested = true }
        elseif rt.capturingName then
            snap[#snap + 1] = { id = zoneId, cap = rt.capturingName }
        end
    end
    return snap
end

function awardDomination(z, teamId)
    local xp    = math.max(0, math.floor(tonumber(z.rewardXp) or 0))
    local money = math.max(0, math.floor(tonumber(z.rewardMoney) or 0))
    for src, p in pairs(zonePresence) do
        local s = sessions[src]
        if s and p.zoneId == z.id and p.teamId == teamId then
            if xp > 0 then
                s.xp = (s.xp or 0) + xp
                s.level = DomCfg.levelFromXp(s.xp)
            end
            if money > 0 then
                s.money = (s.money or 0) + money
            end
            if xp > 0 or money > 0 then markDirty(s) end
            TriggerClientEvent('domination:reward', src, { xp = xp, money = money })
        end
    end
end

function broadcastZoneState(zoneId, st)
    for s in pairs(sessions) do
        TriggerClientEvent('domination:zone:state', s, zoneId, st)
    end
end

function broadcastZoneFeed(kind, team, zone)
    if not team or not zone then return end
    for s in pairs(sessions) do
        TriggerClientEvent('domination:zonefeed', s, { kind = kind, team = team, zone = zone })
    end
end

RegisterNetEvent('domination:zone:here', function(zoneId)
    local src = source
    if not sessions[src] then return end

    local zone = (type(zoneId) == 'string' and zoneId ~= '') and findDominationZone(zoneId) or nil
    applyZoneBucket(src, zone)
    lastHereZone[src] = zone and zone.id or nil

    if not zone then zonePresence[src] = nil; return end

    local teamId, teamName, premium = teamOf(src)
    if not teamId then
        zonePresence[src] = nil
        return
    end
    if zone.type == 'times' and not premium then
        zonePresence[src] = nil
        return notify(src, 'error', 'Essa dominação é só para times PREMIUM (líder premium).')
    end

    zonePresence[src] = { zoneId = zoneId, teamId = teamId, teamName = teamName, premium = premium }

    local rt = zoneRuntime[zoneId]
    if rt and rt.cooldownUntil and rt.cooldownUntil > GetGameTimer() then
        notify(src, 'info', 'Essa zona está em COOLDOWN, espere liberar pra dominar.')
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        local now   = GetGameTimer()
        local zones = DomCfg and DomCfg.dominationZones
        if zones then
            local present = {}
            for src, p in pairs(zonePresence) do
                if sessions[src] then
                    local zt = present[p.zoneId]; if not zt then zt = {}; present[p.zoneId] = zt end
                    local ti = zt[p.teamId]; if not ti then ti = { count = 0, name = p.teamName, premium = p.premium }; zt[p.teamId] = ti end
                    ti.count = ti.count + 1
                else
                    zonePresence[src] = nil
                end
            end
            for i = 1, #zones do
                local z  = zones[i]
                local rt = zoneRuntime[z.id]; if not rt then rt = { progress = 0 }; zoneRuntime[z.id] = rt end

                if z.type == 'bandeira' then
                    updateFlagZone(z, rt, now)
                    goto continueZone
                end

                if rt.cooldownUntil and rt.cooldownUntil <= now then
                    rt.cooldownUntil = nil; rt.ownerName = nil; rt.progress = 0; rt.holdTeam = nil; rt.capturingName = nil; rt.contestedShown = nil
                    broadcastZoneState(z.id, {})
                end

                if not rt.cooldownUntil then
                    local teams = present[z.id]
                    local leaderTeam, leaderCount, leaderName = nil, 0, nil
                    local contested = false
                    if teams then
                        for tid, info in pairs(teams) do
                            if z.type ~= 'times' or info.premium then
                                if info.count > leaderCount then
                                    leaderTeam, leaderCount, leaderName = tid, info.count, info.name
                                    contested = false
                                elseif info.count == leaderCount then
                                    contested = true
                                end
                            end
                        end
                    end

                    local capturing = (leaderTeam ~= nil and not contested)

                    if capturing then
                        local perMember = tonumber(DomCfg.captureSpeedPerMember) or 0.05
                        local speedMult = 1.0 + perMember * math.max(0, leaderCount - 1)
                        if rt.holdTeam ~= leaderTeam then rt.holdTeam = leaderTeam; rt.progress = 0; rt.ticks = 0 end
                        rt.progress = (rt.progress or 0) + speedMult
                        rt.ticks = (rt.ticks or 0) + 1
                        if rt.capturingName ~= leaderName then
                            rt.capturingName = leaderName; rt.contestedShown = nil
                            broadcastZoneState(z.id, { cap = leaderName })
                            broadcastZoneFeed('start', leaderName, z.label)
                        end
                        local cap = tonumber(z.captureSeconds) or 30
                        local pct = math.min(100, math.floor((rt.progress / cap) * 100))
                        for src, p in pairs(zonePresence) do
                            if p.zoneId == z.id and sessions[src] then
                                if p.teamId == leaderTeam then
                                    TriggerClientEvent('domination:progress', src, { zone = z.label, team = leaderName, members = leaderCount, pct = pct, color = z.marker })
                                else
                                    TriggerClientEvent('domination:progress', src, false)
                                end
                            end
                        end
                        local interval = tonumber(z.rewardInterval) or 5
                        if interval > 0 and (rt.ticks % interval) == 0 then
                            awardDomination(z, leaderTeam)
                        end
                        if rt.progress >= cap then
                            rt.ownerName      = leaderName
                            rt.cooldownUntil  = now + (tonumber(z.cooldown) or 0) * 1000
                            rt.progress       = 0
                            rt.ticks          = 0
                            rt.holdTeam       = nil
                            rt.capturingName  = nil
                            rt.contestedShown = nil
                            broadcastZoneState(z.id, { cd = true, ms = (tonumber(z.cooldown) or 0) * 1000 })
                            broadcastZoneFeed('captured', leaderName, z.label)
                            for src, p in pairs(zonePresence) do
                                if p.zoneId == z.id and sessions[src] then TriggerClientEvent('domination:progress', src, false) end
                            end
                        end
                    elseif contested then
                        rt.progress = 0; rt.holdTeam = nil
                        if not rt.contestedShown then
                            rt.contestedShown = true; rt.capturingName = nil
                            broadcastZoneState(z.id, { contested = true })
                        end
                        for src, p in pairs(zonePresence) do
                            if p.zoneId == z.id and sessions[src] then
                                TriggerClientEvent('domination:progress', src, { zone = z.label, contested = true })
                            end
                        end
                    else
                        rt.progress = 0; rt.holdTeam = nil
                        if rt.capturingName or rt.contestedShown then
                            rt.capturingName = nil; rt.contestedShown = nil
                            broadcastZoneState(z.id, {})
                        end
                        for src, p in pairs(zonePresence) do
                            if p.zoneId == z.id and sessions[src] then
                                TriggerClientEvent('domination:progress', src, false)
                            end
                        end
                    end
                end

                ::continueZone::
            end
        end
    end
end)
