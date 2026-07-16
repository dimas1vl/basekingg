h2h = {}

local function playerLabel(src)
    local ok, info = pcall(Core.getUserInfo, src)
    return (ok and info and info.name) or GetPlayerName(tostring(src)) or '???'
end

local function broadcastKillFeed(killerSrc, killerName, victimSrc, victimName)
    for s in pairs(sessions) do
        TriggerClientEvent('domination:killfeed', s, {
            killerSrc  = killerSrc,
            killerName = killerName,
            victimSrc  = victimSrc,
            victimName = victimName,
        })
    end
end

function getTeamNameOf(userId)
    if not userId then return nil end
    local row = Sql.single([[
        SELECT t.`name` AS name FROM `domination_team_members` m
        JOIN `domination_teams` t ON t.`id` = m.`team_id`
        WHERE m.`user_id` = ?
    ]], { userId })
    return row and row.name or nil
end

function buildDeathCard(targetSrc, isSelf, theyKilledMe, iKilledThem)
    local userId = Core.getUserId(targetSrc)
    local info   = Core.getUserInfo(targetSrc)
    local sess   = sessions[targetSrc]
    local xp     = (sess and sess.xp) or (userId and loadProgress(userId)) or 0
    local kills  = info and tonumber(info.kills) or 0
    local deaths = info and tonumber(info.deaths) or 0
    local wins   = info and tonumber(info.wins) or 0
    local loss   = info and tonumber(info.loss) or 0
    local ratio
    if (wins + loss) > 0 then ratio = wins / (wins + loss) * 100
    elseif (kills + deaths) > 0 then ratio = kills / (kills + deaths) * 100
    else ratio = 0 end

    return {
        self   = isSelf and true or false,
        id     = userId or 0,
        name   = (info and info.name) or GetPlayerName(tostring(targetSrc)) or '???',
        clan   = getTeamNameOf(userId),
        level  = DomCfg.levelFromXp(xp),
        gems   = (sess and tonumber(sess.money)) or 0,
        kills  = kills,
        deaths = deaths,
        ratio  = math.floor(ratio * 10 + 0.5) / 10,
        ping   = GetPlayerPing(targetSrc) or 0,
        they   = theyKilledMe or 0,
        me     = iKilledThem or 0,
    }
end

RegisterNetEvent('domination:report', function()
    local src = source
    if not sessions[src] then return end

    local now = GetGameTimer()
    if now - (reportAt[src] or 0) < 3000 then return end
    reportAt[src] = now

    local targetUserId = lastKiller[src]
    if not targetUserId then return notify(src, 'error', 'Nada para reportar.') end
    local reporterId = Core.getUserId(src)
    if Core and Core.log then
        Core.log('warn', ('[domination] report: user %s reportou user %s'):format(tostring(reporterId), tostring(targetUserId)))
    end
    notify(src, 'success', 'Jogador reportado. Obrigado!')
end)

RegisterNetEvent('domination:kill', function(killerServerId, deathX, deathY, deathZ)
    local victimSrc = source
    local victim = sessions[victimSrc]
    if not victim then return end

    zonePresence[victimSrc] = nil
    flagDropOnDeath(victimSrc, deathX, deathY, deathZ)

    local now = GetGameTimer()
    if now - (victim.lastDeath or 0) < 1500 then return end
    victim.lastDeath = now

    victim.deaths = (victim.deaths or 0) + 1
    pushState(victimSrc)

    killerServerId = tonumber(killerServerId)
    local killer = killerServerId and sessions[killerServerId] or nil

    local validKiller = killer and killer.userId and killerServerId ~= victimSrc
        and DoesPlayerExist(tostring(killerServerId))

    local victimName = playerLabel(victimSrc)
    if validKiller then
        broadcastKillFeed(killerServerId, playerLabel(killerServerId), victimSrc, victimName)
        local kId, vId = killer.userId, victim.userId
        local they, me = 0, 0
        if kId and vId then
            local kKey = kId .. ':' .. vId
            h2h[kKey] = (h2h[kKey] or 0) + 1
            they = h2h[kKey]
            me   = h2h[vId .. ':' .. kId] or 0
        end
        lastKiller[victimSrc] = killer.userId
        TriggerClientEvent('domination:deathcard', victimSrc, buildDeathCard(killerServerId, false, they, me))
    else
        broadcastKillFeed(victimSrc, victimName, victimSrc, victimName)
        lastKiller[victimSrc] = nil
        TriggerClientEvent('domination:deathcard', victimSrc, buildDeathCard(victimSrc, true, 0, 0))
        return
    end

    if killer.zoneId ~= victim.zoneId then return end

    local victimKey = victim.userId or ('src:' .. victimSrc)
    killer.lastKillFrom = killer.lastKillFrom or {}
    if now - (killer.lastKillFrom[victimKey] or 0) < (tonumber(DomCfg.level.killCooldownMs) or 15000) then
        return
    end

    killer.killWindow = killer.killWindow or { start = now, count = 0 }
    if now - killer.killWindow.start >= 60000 then
        killer.killWindow = { start = now, count = 0 }
    end
    if killer.killWindow.count >= (tonumber(DomCfg.level.maxKillsPerMin) or 20) then return end
    killer.killWindow.count = killer.killWindow.count + 1
    killer.lastKillFrom[victimKey] = now

    killer.kills = (killer.kills or 0) + 1

    local gain   = math.max(0, math.floor(tonumber(DomCfg.level.xpPerKill) or 0))
    local before = DomCfg.levelFromXp(killer.xp)
    killer.xp    = (killer.xp or 0) + gain
    markDirty(killer)
    local after = DomCfg.levelFromXp(killer.xp)
    killer.level = after

    if after > before then
        notify(killerServerId, 'success', ('Subiu para o nível %d!'):format(after))
    elseif gain > 0 then
        notify(killerServerId, 'info', ('+%d XP de Dominação'):format(gain))
    end

    pushState(killerServerId)
end)

local teamCache = {}
local function cachedTeam(src)
    local c = teamCache[src]
    local now = GetGameTimer()
    if c and (now - c.at) < 2000 then return c.teamId end
    local t = DoesPlayerExist(src) and teamOf(src) or nil
    teamCache[src] = { teamId = t, at = now }
    return t
end

domDownedSet = {}
domSpectating = {}

RegisterNetEvent('domination:spectate', function(targetSrc)
    local src = source
    if not sessions[src] then return end
    targetSrc = tonumber(targetSrc) or nil
    if targetSrc and domDownedSet[targetSrc] then
        domSpectating[src] = nil
        TriggerClientEvent('domination:killcam:stop', src)
        return
    end
    domSpectating[src] = targetSrc
end)

---@param targetSrc number
function notifyKillcamWatchers(targetSrc)
    for spec, tgt in pairs(domSpectating) do
        if tgt == targetSrc then
            domSpectating[spec] = nil
            TriggerClientEvent('domination:killcam:stop', spec)
        end
    end
end

RegisterNetEvent('domination:downed', function(isDowned)
    local src = source
    if not sessions[src] then return end
    if isDowned then domDownedSet[src] = true else domDownedSet[src] = nil end
    if isDowned then notifyKillcamWatchers(src) end
    local tA = cachedTeam(src)
    if not tA then return end
    for s in pairs(sessions) do
        if s ~= src and cachedTeam(s) == tA then
            TriggerClientEvent('domination:downed', s, src, isDowned and true or false)
        end
    end
end)

RegisterNetEvent('domination:revive', function(downedSrc)
    local src = source
    downedSrc = tonumber(downedSrc)
    if not downedSrc or not sessions[src] or not sessions[downedSrc] then return end
    if src == downedSrc or not domDownedSet[downedSrc] then return end
    if not (DoesPlayerExist(src) and DoesPlayerExist(downedSrc)) then return end

    local tA = teamOf(src)
    local tB = teamOf(downedSrc)
    if not (tA and tB and tA == tB) then return end

    local pedA, pedB = GetPlayerPed(src), GetPlayerPed(downedSrc)
    if not pedA or pedA == 0 or not pedB or pedB == 0 then return end
    local dist = #(GetEntityCoords(pedA) - GetEntityCoords(pedB))
    if dist > ((tonumber(DomCfg.reviveDistance) or 2.0) + 2.0) then return end

    domDownedSet[downedSrc] = nil
    for s in pairs(sessions) do
        TriggerClientEvent('domination:downed', s, downedSrc, false)
    end
    TriggerClientEvent('domination:revived', downedSrc)
end)
