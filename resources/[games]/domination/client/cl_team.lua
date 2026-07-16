RegisterNetEvent('domination:team:state', function(state)
    SendNUIMessage({ action = 'team', data = state })
    -- mudou de time/cargo: força re-reportar presença pra reavaliar se pode dominar
    -- (cobre entrar num time enquanto parado dentro da zona)
    domReportedZone = ''
end)

RegisterNUICallback('team:request', function(_, cb)
    TriggerServerEvent('domination:team:request')
    cb({})
end)

RegisterNUICallback('team:create', function(data, cb)
    if type(data) == 'table' and data.name then
        TriggerServerEvent('domination:team:create', tostring(data.name))
    end
    cb({ ok = true })
end)

RegisterNUICallback('team:leave', function(_, cb)
    TriggerServerEvent('domination:team:leave')
    cb({ ok = true })
end)

RegisterNUICallback('team:accept', function(_, cb)
    TriggerServerEvent('domination:team:invite:accept')
    cb({ ok = true })
end)

RegisterNUICallback('team:decline', function(_, cb)
    TriggerServerEvent('domination:team:invite:decline')
    cb({ ok = true })
end)

RegisterNUICallback('team:invite', function(data, cb)
    if type(data) == 'table' and data.target then
        TriggerServerEvent('domination:team:invite', tostring(data.target))
    end
    cb({ ok = true })
end)

RegisterNUICallback('team:kick', function(data, cb)
    if type(data) == 'table' and data.id then
        TriggerServerEvent('domination:team:kick', data.id)
    end
    cb({ ok = true })
end)

RegisterNUICallback('team:setrole', function(data, cb)
    if type(data) == 'table' and data.id and data.role then
        TriggerServerEvent('domination:team:setRole', data.id, tostring(data.role))
    end
    cb({ ok = true })
end)

RegisterNUICallback('team:setdiscord', function(data, cb)
    if type(data) == 'table' then
        TriggerServerEvent('domination:team:setDiscord', tostring(data.url or ''))
    end
    cb({ ok = true })
end)

local relReady = false
local teamSet = {}
local teammates = {}
local DOM_ALLY = 'DOM_ALLY'
local DOM_ENEMY = 'DOM_ENEMY'
local ALLY_HASH = GetHashKey(DOM_ALLY)
local ENEMY_HASH = GetHashKey(DOM_ENEMY)

local function setupRelationships()
    if relReady then return end
    AddRelationshipGroup(DOM_ALLY)
    AddRelationshipGroup(DOM_ENEMY)
    SetRelationshipBetweenGroups(1, ALLY_HASH, ALLY_HASH)
    SetRelationshipBetweenGroups(5, ALLY_HASH, ENEMY_HASH)
    SetRelationshipBetweenGroups(5, ENEMY_HASH, ALLY_HASH)
    SetRelationshipBetweenGroups(5, ENEMY_HASH, ENEMY_HASH)
    relReady = true
end

local function styleTeamBlip(blip, name)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 2)
    SetBlipScale(blip, 0.85)
    SetBlipAsShortRange(blip, false)
    SetBlipCategory(blip, 7)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(name or 'Aliado')
    EndTextCommandSetBlipName(blip)
end

local function clearTeamBlips()
    for _, t in pairs(teammates) do
        if t.blip and DoesBlipExist(t.blip) then RemoveBlip(t.blip) end
    end
    teammates = {}
    teamSet = {}
end

---@param src number
---@return boolean
function domIsTeammate(src)
    return teamSet[src] == true
end

RegisterNetEvent('domination:teamSync', function(members)
    if type(members) ~= 'table' then return end
    local present = {}
    teamSet = {}
    for i = 1, #members do
        local m = members[i]
        if m and m.s then
            teamSet[m.s] = true
            present[m.s] = true
            local t = teammates[m.s]
            if not t then t = {}; teammates[m.s] = t end
            t.name = m.n
            t.x, t.y, t.z = m.x, m.y, m.z
        end
    end
    for src, t in pairs(teammates) do
        if not present[src] then
            if t.blip and DoesBlipExist(t.blip) then RemoveBlip(t.blip) end
            teammates[src] = nil
        end
    end
end)

local function applyTeamGroups()
    local mySrc = GetPlayerServerId(PlayerId())
    local selfPed = PlayerPedId()
    if selfPed ~= 0 then SetPedRelationshipGroupHash(selfPed, ALLY_HASH) end
    for _, cid in ipairs(GetActivePlayers()) do
        local ssrc = GetPlayerServerId(cid)
        if ssrc ~= -1 and ssrc ~= mySrc then
            local ped = GetPlayerPed(cid)
            if ped ~= 0 and DoesEntityExist(ped) then
                SetPedRelationshipGroupHash(ped, teamSet[ssrc] and ALLY_HASH or ENEMY_HASH)
            end
        end
    end
end

CreateThread(function()
    while true do
        local wait = 1000
        if Zone.active then
            wait = 300
            setupRelationships()
            NetworkSetFriendlyFireOption(true)
            local selfPed = PlayerPedId()
            if selfPed ~= 0 then SetCanAttackFriendly(selfPed, false, false) end
            applyTeamGroups()

            for src, t in pairs(teammates) do
                local idx = GetPlayerFromServerId(src)
                local ped = (idx ~= -1) and GetPlayerPed(idx) or 0
                local inRange = ped ~= 0 and DoesEntityExist(ped)
                if inRange then
                    if not (t.blip and DoesBlipExist(t.blip) and t.isEntity) then
                        if t.blip and DoesBlipExist(t.blip) then RemoveBlip(t.blip) end
                        t.blip = AddBlipForEntity(ped)
                        t.isEntity = true
                        styleTeamBlip(t.blip, t.name)
                    end
                else
                    if t.blip and DoesBlipExist(t.blip) and not t.isEntity then
                        SetBlipCoords(t.blip, t.x or 0.0, t.y or 0.0, t.z or 0.0)
                    else
                        if t.blip and DoesBlipExist(t.blip) then RemoveBlip(t.blip) end
                        t.blip = AddBlipForCoord(t.x or 0.0, t.y or 0.0, t.z or 0.0)
                        t.isEntity = false
                        styleTeamBlip(t.blip, t.name)
                    end
                end
            end
        else
            if next(teammates) ~= nil then clearTeamBlips() end
        end
        Wait(wait)
    end
end)

RegisterNetEvent('domination:leave', function()
    clearTeamBlips()
    local ped = PlayerPedId()
    if ped ~= 0 then SetPedRelationshipGroupHash(ped, GetHashKey('PLAYER')) end
end)

CreateThread(function()
    while true do
        if Zone.active and not respawning then
            local pid = PlayerId()
            local found, ent = GetEntityPlayerIsFreeAimingAt(pid)
            if found and ent and ent ~= 0 and IsEntityAPed(ent) and IsPedAPlayer(ent) then
                local pidx = NetworkGetPlayerIndexFromPed(ent)
                if pidx ~= -1 and teamSet[GetPlayerServerId(pidx)] then
                    DisablePlayerFiring(pid, true)
                    DisableControlAction(0, 24, true)
                    DisableControlAction(0, 257, true)
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

local downedSet = {}
local REVIVE_MS = (tonumber(Config.Domination.reviveTime) or 10) * 1000
local REVIVE_DIST = tonumber(Config.Domination.reviveDistance) or 2.0

RegisterNetEvent('domination:downed', function(src, isDowned)
    if not src then return end
    if isDowned then downedSet[src] = true else downedSet[src] = nil end
end)

local reviveUi = false

local function doRevive(targetSrc, targetPed)
    local ped = PlayerPedId()
    TaskTurnPedToFaceEntity(ped, targetPed, REVIVE_MS)
    RequestAnimDict('mini@cpr@char_a@cpr_str')
    local adl = GetGameTimer() + 600
    while not HasAnimDictLoaded('mini@cpr@char_a@cpr_str') and GetGameTimer() < adl do Wait(0) end
    TaskPlayAnim(ped, 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest', 8.0, -8.0, -1, 1, 0, false, false, false)

    local start = GetGameTimer()
    local lastSend = 0
    local ok = true
    while Zone.active do
        local elapsed = GetGameTimer() - start
        if elapsed >= REVIVE_MS then break end
        if not IsControlPressed(0, 38) then ok = false; break end
        if not downedSet[targetSrc] then ok = false; break end
        local idx = GetPlayerFromServerId(targetSrc)
        local tped = (idx ~= -1) and GetPlayerPed(idx) or 0
        if tped == 0 or #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(tped)) > REVIVE_DIST then ok = false; break end
        local now = GetGameTimer()
        if now - lastSend > 60 then
            SendNUIMessage({ action = 'revive', visible = true, holding = true, pct = elapsed / REVIVE_MS })
            lastSend = now
        end
        Wait(0)
    end

    ClearPedTasks(PlayerPedId())
    SendNUIMessage({ action = 'revive', visible = false })
    reviveUi = false
    if ok and downedSet[targetSrc] then
        TriggerServerEvent('domination:revive', targetSrc)
        downedSet[targetSrc] = nil
    end
end

CreateThread(function()
    while true do
        local wait = 400
        local nearSrc, nearPed = nil, nil
        if Zone.active and not respawning then
            local ped = PlayerPedId()
            if ped ~= 0 and not IsEntityDead(ped) and not IsPedInAnyVehicle(ped, false) then
                local mySrc = GetPlayerServerId(PlayerId())
                local mypos = GetEntityCoords(ped)
                local bestDist = REVIVE_DIST
                for src in pairs(downedSet) do
                    if src ~= mySrc then
                        local idx = GetPlayerFromServerId(src)
                        local tped = (idx ~= -1) and GetPlayerPed(idx) or 0
                        if tped ~= 0 and DoesEntityExist(tped) then
                            local tpos = GetEntityCoords(tped)
                            local d = #(mypos - tpos)
                            if d <= 75.0 then
                                wait = 0
                                DrawMarker(2, tpos.x, tpos.y, tpos.z + 1.0, 0, 0, 0, 180.0, 0, 0, 0.3, 0.3, 0.3, 124, 252, 106, 200, false, true, 2, false, nil, nil, false)
                            end
                            if d <= bestDist then nearSrc, nearPed, bestDist = src, tped, d end
                        else
                            downedSet[src] = nil
                        end
                    end
                end
            end
        end

        if nearSrc then
            wait = 0
            if not reviveUi then
                reviveUi = true
                SendNUIMessage({ action = 'revive', visible = true, holding = false, pct = 0 })
            end
            if IsControlPressed(0, 38) then
                doRevive(nearSrc, nearPed)
            end
        elseif reviveUi then
            reviveUi = false
            SendNUIMessage({ action = 'revive', visible = false })
        end

        Wait(wait)
    end
end)
