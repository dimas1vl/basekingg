TeamCfg = DomCfg.team

function rank(role) return TeamCfg.roleRank[role] or 0 end

function isUserOnline(userId)
    return Core.getUserSource and Core.getUserSource(userId) ~= nil or false
end

teamActAt = {}
function teamCooldown(userId)
    local now = GetGameTimer()
    if now - (teamActAt[userId] or 0) < 600 then return true end
    teamActAt[userId] = now
    return false
end

pendingInvites = {}
INVITE_TTL = 120000

function buildTeamState(src)
    local userId = Core.getUserId(src)
    if not userId then return { hasTeam = false } end

    local mem = Sql.single('SELECT `team_id`, `role` FROM `domination_team_members` WHERE `user_id` = ?', { userId })
    if not mem then

        local inv = pendingInvites[userId]
        if inv and (GetGameTimer() - inv.at) <= INVITE_TTL then
            return { hasTeam = false, invite = { team = inv.teamName, from = inv.fromName } }
        end
        return { hasTeam = false }
    end

    local team = Sql.single('SELECT `id`, `name`, `leader_id`, `discord` FROM `domination_teams` WHERE `id` = ?', { mem.team_id })
    if not team then return { hasTeam = false } end

    local rows = Sql.query([[
        SELECT m.`user_id`, m.`role`, u.`name`, u.`last_login`
        FROM `domination_team_members` m
        JOIN `users` u ON u.`id` = m.`user_id`
        WHERE m.`team_id` = ?
    ]], { team.id }) or {}

    local members = {}
    local counts  = { lider = 0, gerente = 0, sublider = 0, recrutador = 0, membro = 0 }
    local online  = 0
    for i = 1, #rows do
        local r = rows[i]
        local on = isUserOnline(r.user_id)
        if on then online = online + 1 end
        counts[r.role] = (counts[r.role] or 0) + 1
        members[#members + 1] = {
            id        = r.user_id,
            name      = r.name or ('Player %d'):format(r.user_id),
            role      = r.role,
            online    = on,
            lastLogin = r.last_login,
        }
    end

    table.sort(members, function(a, b)
        local ra, rb = rank(a.role), rank(b.role)
        if ra ~= rb then return ra > rb end
        return (a.name or ''):lower() < (b.name or ''):lower()
    end)

    local myRank = rank(mem.role)
    return {
        hasTeam     = true,
        id          = team.id,
        name        = team.name,
        premium     = isTeamPremium(team.id),
        discord     = team.discord,
        maxMembers  = TeamCfg.maxMembers,
        memberCount = #members,
        onlineCount = online,
        counts      = counts,
        caps        = TeamCfg.roleCaps,
        roleLabels  = TeamCfg.roleLabels,
        myRole      = mem.role,
        perms = {
            invite     = myRank >= TeamCfg.roleRank.recrutador,
            kick       = myRank >= TeamCfg.roleRank.sublider,
            promote    = mem.role == 'lider',
            setDiscord = myRank >= TeamCfg.roleRank.gerente,
        },
        members = members,
    }
end

function pushTeamState(src)
    if not src or src == 0 then return end
    TriggerClientEvent('domination:team:state', src, buildTeamState(src))
end

function pushTeamToUsers(userIds)
    for i = 1, #userIds do
        local s = Core.getUserSource and Core.getUserSource(userIds[i])
        if s then pushTeamState(s) end
    end
end

function teamMemberIds(teamId)
    local ids = {}
    local rows = Sql.query('SELECT `user_id` FROM `domination_team_members` WHERE `team_id` = ?', { teamId })
    if rows then for i = 1, #rows do ids[#ids + 1] = rows[i].user_id end end
    return ids
end

function roleCount(teamId, role)
    local row = Sql.single('SELECT COUNT(*) AS n FROM `domination_team_members` WHERE `team_id` = ? AND `role` = ?', { teamId, role })
    return row and tonumber(row.n) or 0
end

function getMember(userId)
    return Sql.single('SELECT `team_id`, `role` FROM `domination_team_members` WHERE `user_id` = ?', { userId })
end

-- time premium = o lider (leader_id) tem users.premium > 0
function isTeamPremium(teamId)
    local t = Sql.single('SELECT `leader_id` FROM `domination_teams` WHERE `id` = ?', { teamId })
    if not t then return false end
    local u = Sql.single('SELECT `premium` FROM `users` WHERE `id` = ?', { t.leader_id })
    return (u ~= nil) and ((u.premium == true) or ((tonumber(u.premium) or 0) > 0))
end

local function teamSyncName(src)
    local ok, info = pcall(Core.getUserInfo, src)
    return (ok and info and info.name) or GetPlayerName(tostring(src)) or '???'
end

local teamSynced = {}

CreateThread(function()
    while true do
        Wait(5000)
        local groups = {}
        for src in pairs(sessions) do
            if DoesPlayerExist(src) then
                local userId = Core.getUserId(src)
                local mem = userId and getMember(userId) or nil
                if mem and mem.team_id then
                    local ped = GetPlayerPed(src)
                    local pos = (ped and ped ~= 0) and GetEntityCoords(ped) or vector3(0.0, 0.0, 0.0)
                    local g = groups[mem.team_id]
                    if not g then g = {}; groups[mem.team_id] = g end
                    g[#g + 1] = {
                        s = src,
                        n = teamSyncName(src),
                        x = math.floor(pos.x + 0.5),
                        y = math.floor(pos.y + 0.5),
                        z = math.floor(pos.z + 0.5),
                    }
                end
            end
        end
        local sent = {}
        for _, list in pairs(groups) do
            for i = 1, #list do
                local recipient = list[i].s
                local others = {}
                for j = 1, #list do
                    if j ~= i then others[#others + 1] = list[j] end
                end
                if #others > 0 then
                    TriggerClientEvent('domination:teamSync', recipient, others)
                    sent[recipient] = true
                    teamSynced[recipient] = true
                end
            end
        end
        for src in pairs(teamSynced) do
            if not sent[src] then
                teamSynced[src] = nil
                if sessions[src] then TriggerClientEvent('domination:teamSync', src, {}) end
            end
        end
    end
end)

RegisterNetEvent('domination:team:request', function()
    pushTeamState(source)
end)

RegisterNetEvent('domination:team:create', function(name)
    local src = source
    local userId = Core.getUserId(src)
    if not userId then return notify(src, 'error', 'Jogador não identificado.') end
    if teamCooldown(userId) then return end
    if type(name) ~= 'string' then return end
    name = name:gsub('^%s+', ''):gsub('%s+$', '')
    if #name < TeamCfg.nameMinLen or #name > TeamCfg.nameMaxLen then
        return notify(src, 'error', ('Nome inválido (%d-%d caracteres).'):format(TeamCfg.nameMinLen, TeamCfg.nameMaxLen))
    end
    if getMember(userId) then return notify(src, 'error', 'Você já está em um time.') end
    if Sql.single('SELECT 1 AS x FROM `domination_teams` WHERE `name` = ?', { name }) then
        return notify(src, 'error', 'Já existe um time com esse nome.')
    end

    local okT, teamId = pcall(Sql.insert, 'INSERT INTO `domination_teams` (`name`, `leader_id`) VALUES (?, ?)', { name, userId })
    if not okT or not teamId then
        return notify(src, 'error', 'Já existe um time com esse nome ou falha ao criar.')
    end

    local okM = pcall(Sql.execute, 'INSERT INTO `domination_team_members` (`user_id`, `team_id`, `role`) VALUES (?, ?, ?)', { userId, teamId, 'lider' })
    if not okM then
        Sql.execute('DELETE FROM `domination_teams` WHERE `id` = ?', { teamId })
        return notify(src, 'error', 'Você já está em um time.')
    end
    notify(src, 'success', 'Time criado!')
    pushTeamState(src)
end)

RegisterNetEvent('domination:team:leave', function()
    local src = source
    local userId = Core.getUserId(src)
    if not userId then return end
    local mem = getMember(userId)
    if not mem then return notify(src, 'info', 'Você não está em um time.') end

    local ids = teamMemberIds(mem.team_id)
    if mem.role == 'lider' then

        Sql.execute('DELETE FROM `domination_teams` WHERE `id` = ?', { mem.team_id })
        notify(src, 'info', 'Time desfeito.')
    else
        Sql.execute('DELETE FROM `domination_team_members` WHERE `user_id` = ?', { userId })
        notify(src, 'info', 'Você saiu do time.')
    end
    pushTeamToUsers(ids)
end)

RegisterNetEvent('domination:team:invite', function(target)
    local src = source
    local userId = Core.getUserId(src)
    if not userId then return end
    if teamCooldown(userId) then return end
    local mem = getMember(userId)
    if not mem then return notify(src, 'error', 'Você não está em um time.') end
    if rank(mem.role) < TeamCfg.roleRank.recrutador then
        return notify(src, 'error', 'Sem permissão para convidar.')
    end
    if type(target) ~= 'string' then return end
    target = target:gsub('^%s+', ''):gsub('%s+$', '')
    if target == '' then return notify(src, 'error', 'Informe o ID ou nome do jogador.') end

    local targetRow
    if target:match('^%d+$') then
        targetRow = Sql.single('SELECT `id`, `name` FROM `users` WHERE `id` = ?', { tonumber(target) })
    else
        targetRow = Sql.single('SELECT `id`, `name` FROM `users` WHERE `name` = ?', { target })
    end
    if not targetRow then return notify(src, 'error', 'Jogador não encontrado.') end
    local targetId = tonumber(targetRow.id)
    if targetId == userId then return notify(src, 'error', 'Você não pode se convidar.') end

    local targetSrc = Core.getUserSource and Core.getUserSource(targetId)
    if not targetSrc or not sessions[targetSrc] then
        return notify(src, 'error', 'O jogador não está na Dominação.')
    end

    if getMember(targetId) then return notify(src, 'error', 'Esse jogador já está em um time.') end

    local total = Sql.single('SELECT COUNT(*) AS n FROM `domination_team_members` WHERE `team_id` = ?', { mem.team_id })
    if (total and tonumber(total.n) or 0) >= TeamCfg.maxMembers then
        return notify(src, 'error', 'Time cheio.')
    end

    local team = Sql.single('SELECT `name` FROM `domination_teams` WHERE `id` = ?', { mem.team_id })
    local inviterInfo = Core.getUserInfo(src)
    pendingInvites[targetId] = {
        teamId   = mem.team_id,
        teamName = team and team.name or 'Time',
        fromName = (inviterInfo and inviterInfo.name) or 'Alguém',
        at       = GetGameTimer(),
    }
    notify(src, 'success', ('Convite enviado para %s.'):format(targetRow.name or targetId))
    notify(targetSrc, 'info', ('%s te convidou pro time %s. Abra o F1 > MEU TIME.'):format(pendingInvites[targetId].fromName, pendingInvites[targetId].teamName))
    pushTeamState(targetSrc)
end)

RegisterNetEvent('domination:team:invite:accept', function()
    local src = source
    local userId = Core.getUserId(src)
    if not userId then return end
    if teamCooldown(userId) then return end
    local inv = pendingInvites[userId]
    pendingInvites[userId] = nil
    if not inv then return notify(src, 'error', 'Nenhum convite pendente.') end
    if (GetGameTimer() - inv.at) > INVITE_TTL then return notify(src, 'error', 'Convite expirado.') end
    if getMember(userId) then return notify(src, 'error', 'Você já está em um time.') end
    if not Sql.single('SELECT 1 AS x FROM `domination_teams` WHERE `id` = ?', { inv.teamId }) then
        return notify(src, 'error', 'O time não existe mais.')
    end

    local okIns = pcall(Sql.execute, [[
        INSERT INTO `domination_team_members` (`user_id`, `team_id`, `role`)
        SELECT ?, ?, 'membro' FROM DUAL
        WHERE (SELECT c FROM (SELECT COUNT(*) AS c FROM `domination_team_members` WHERE `team_id` = ?) AS t) < ?
    ]], { userId, inv.teamId, inv.teamId, TeamCfg.maxMembers })
    if not okIns then return notify(src, 'error', 'Falha ao entrar no time.') end
    local nowMem = getMember(userId)
    if not nowMem or nowMem.team_id ~= inv.teamId then
        return notify(src, 'error', 'O time está cheio.')
    end
    notify(src, 'success', ('Você entrou no time %s!'):format(inv.teamName))
    pushTeamToUsers(teamMemberIds(inv.teamId))
end)

RegisterNetEvent('domination:team:invite:decline', function()
    local src = source
    local userId = Core.getUserId(src)
    if not userId then return end
    pendingInvites[userId] = nil
    notify(src, 'info', 'Convite recusado.')
    pushTeamState(src)
end)

RegisterNetEvent('domination:team:kick', function(targetUserId)
    local src = source
    local userId = Core.getUserId(src)
    if not userId then return end
    if teamCooldown(userId) then return end
    targetUserId = tonumber(targetUserId)
    if not targetUserId or targetUserId == userId then return end

    local mem = getMember(userId)
    local tgt = getMember(targetUserId)
    if not mem or not tgt then return end
    if mem.team_id ~= tgt.team_id then return end
    if rank(mem.role) < TeamCfg.roleRank.sublider then
        return notify(src, 'error', 'Sem permissão para expulsar.')
    end
    if rank(mem.role) <= rank(tgt.role) then
        return notify(src, 'error', 'Você não pode expulsar esse cargo.')
    end

    local ids = teamMemberIds(mem.team_id)
    Sql.execute('DELETE FROM `domination_team_members` WHERE `user_id` = ?', { targetUserId })
    notify(src, 'success', 'Membro expulso.')
    pushTeamToUsers(ids)
end)

RegisterNetEvent('domination:team:setRole', function(targetUserId, role)
    local src = source
    local userId = Core.getUserId(src)
    if not userId then return end
    if teamCooldown(userId) then return end
    targetUserId = tonumber(targetUserId)
    if not targetUserId or targetUserId == userId then return end
    if type(role) ~= 'string' or not TeamCfg.roleRank[role] or role == 'lider' then
        return notify(src, 'error', 'Cargo inválido.')
    end

    local mem = getMember(userId)
    local tgt = getMember(targetUserId)
    if not mem or not tgt or mem.team_id ~= tgt.team_id then return end
    if mem.role ~= 'lider' then
        return notify(src, 'error', 'Apenas o líder pode promover/rebaixar.')
    end
    if tgt.role == role then return end

    local cap = TeamCfg.roleCaps[role]
    if cap and roleCount(mem.team_id, role) >= cap then
        return notify(src, 'error', ('Limite de %s atingido.'):format(TeamCfg.roleLabels[role] or role))
    end

    Sql.execute('UPDATE `domination_team_members` SET `role` = ? WHERE `user_id` = ?', { role, targetUserId })
    notify(src, 'success', 'Cargo atualizado.')
    pushTeamToUsers(teamMemberIds(mem.team_id))
end)

RegisterNetEvent('domination:team:setDiscord', function(url)
    local src = source
    local userId = Core.getUserId(src)
    if not userId then return end
    local mem = getMember(userId)
    if not mem then return end
    if rank(mem.role) < TeamCfg.roleRank.gerente then
        return notify(src, 'error', 'Sem permissão.')
    end
    if type(url) ~= 'string' then return end
    url = url:gsub('^%s+', ''):gsub('%s+$', '')
    if #url > 255 then url = url:sub(1, 255) end
    if url ~= '' and not (
        url:match('^https://discord%.gg/') or
        url:match('^https://discord%.com/') or
        url:match('^https://discordapp%.com/') or
        url:match('^https://[%w%-]+%.discord%.com/')
    ) then
        return notify(src, 'error', 'Use um link discord.gg ou discord.com.')
    end

    Sql.execute('UPDATE `domination_teams` SET `discord` = ? WHERE `id` = ?', { url ~= '' and url or nil, mem.team_id })
    notify(src, 'success', 'Discord atualizado.')
    pushTeamToUsers(teamMemberIds(mem.team_id))
end)
