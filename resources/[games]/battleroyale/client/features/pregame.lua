local Pregame = Game.module('pregame')

local running = false
local passiveMode = false
local leaveHoldActive = false
local leaveHoldThread = 0
local nameCache = {}
local playerCount = { current = 0, max = 0 }

local LEAVE_HOLD_MS = 2000

local ARSENAL = {
    'WEAPON_SPECIALCARBINE',
    'WEAPON_ASSAULTRIFLE',
    'WEAPON_CARBINERIFLE',
    'WEAPON_PISTOL_MK2',
    'WEAPON_ASSAULTSMG',
    'WEAPON_MACHINEPISTOL',
    'WEAPON_APPISTOL',
    'WEAPON_MICROSMG',
}

local function drawName(coords, text)

    local onScreen, sx, sy = World3dToScreen2d(coords.x, coords.y, coords.z)

    if not onScreen then return end

    SetTextScale(0.26, 0.26)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 220)
    SetTextDropshadow(1, 0, 0, 0, 180)
    SetTextOutline()
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(sx, sy)
end

function Pregame:setup(ctx)

    running = false
    passiveMode = false
    leaveHoldActive = false
    nameCache = {}
end

function Pregame:teardown(ctx)

    running = false
    leaveHoldActive = false

    if passiveMode then
        passiveMode = false
        local ped = PlayerPedId()
        self:removePassive(ped)
    end

    self:hideShortcuts()
    nameCache = {}
end

function Pregame:hideShortcuts()

    Game.ui.send('hud:shortcuts', { visible = false, passive = false })
    Game.ui.send('hud:leaveHold', { visible = false, percent = 0 })
end

function Pregame:sendShortcuts()

    Game.ui.send('hud:shortcuts', {
        visible = true,
        passive = passiveMode,
        current = playerCount.current,
        max = playerCount.max,
    })
end

---@param ped number
function Pregame:applyPassive(ped)

    SetEntityInvincible(ped, true)
    SetPlayerInvincible(PlayerId(), true)
    SetEntityAlpha(ped, 80, false)
    SetCanAttackFriendly(ped, false, false)
    NetworkSetFriendlyFireOption(false)
end

---@param ped number
function Pregame:removePassive(ped)

    SetEntityInvincible(ped, false)
    SetPlayerInvincible(PlayerId(), false)
    ResetEntityAlpha(ped)
    SetCanAttackFriendly(ped, true, false)
    NetworkSetFriendlyFireOption(true)
end

function Pregame:togglePassive()

    passiveMode = not passiveMode

    local ped = PlayerPedId()

    if passiveMode then
        self:sendShortcuts()

        CreateThread(function()
            local spawns = Config.BR.warmup.lobbySpawns
            local spawn = spawns[math.random(#spawns)]

            DoScreenFadeOut(200)
            Wait(250)

            local p = PlayerPedId()
            SetEntityCoordsNoOffset(p, spawn.x, spawn.y, spawn.z, false, false, false)
            SetEntityHeading(p, spawn.w)
            self:applyPassive(p)
            RemoveAllPedWeapons(p, true)

            Wait(200)
            DoScreenFadeIn(300)
        end)
    else
        self:sendShortcuts()

        CreateThread(function()
            local spawns = Config.BR.warmup.warmupSpawns
            local spawn = spawns[math.random(#spawns)]

            DoScreenFadeOut(200)
            Wait(250)

            local p = PlayerPedId()
            SetEntityCoordsNoOffset(p, spawn.x, spawn.y, spawn.z, false, false, false)
            SetEntityHeading(p, spawn.w)
            self:removePassive(p)

            GiveWeaponToPed(p, GetHashKey('WEAPON_KNIFE'), 1, false, true)

            for _, w in ipairs(ARSENAL) do
                GiveWeaponToPed(p, GetHashKey(w), 500, false, true)
            end

            Wait(200)
            DoScreenFadeIn(300)
        end)
    end
end

---@param pos vector3
function Pregame:spawn(pos)

    local ped = PlayerPedId()

    DoScreenFadeOut(0)
    NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, GetEntityHeading(ped), true, false)

    ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    ClearPedTasks(ped)
    SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)

    Wait(500)
    DoScreenFadeIn(500)

    ped = PlayerPedId()

    if passiveMode then
        self:applyPassive(ped)
    else
        NetworkSetFriendlyFireOption(true)
        GiveWeaponToPed(ped, GetHashKey('WEAPON_KNIFE'), 1, false, true)

        for _, w in ipairs(ARSENAL) do
            GiveWeaponToPed(ped, GetHashKey(w), 500, false, true)
        end
    end
end

function Pregame:renderNametags()

    local ped = PlayerPedId()
    local origin = GetEntityCoords(ped)
    local me = GetPlayerServerId(PlayerId())

    for _, pid in ipairs(GetActivePlayers()) do

        local src = GetPlayerServerId(pid)

        if src == me then goto skip end

        local pPed = GetPlayerPed(pid)

        if not DoesEntityExist(pPed) then goto skip end

        local pedCoords = GetEntityCoords(pPed)
        local d = #(origin - pedCoords)

        if d <= 40.0 then
            local name = nameCache[src] or GetPlayerName(pid) or ('Player %d'):format(src)
            drawName(pedCoords + vec3(0.0, 0.0, 0.5), name)
        end

        ::skip::
    end
end

-- Hold-to-leave

local function startLeaveHold()

    if not running then return end
    if leaveHoldActive then return end

    leaveHoldActive = true
    leaveHoldThread = leaveHoldThread + 1

    local myId = leaveHoldThread
    local startedAt = GetGameTimer()

    Game.ui.send('hud:leaveHold', { visible = true, percent = 0 })

    CreateThread(function()

        while leaveHoldActive and myId == leaveHoldThread and running do

            local elapsed = GetGameTimer() - startedAt
            local pct = math.min(100, math.floor((elapsed / LEAVE_HOLD_MS) * 100))

            Game.ui.send('hud:leaveHold', { visible = true, percent = pct })

            if elapsed >= LEAVE_HOLD_MS then
                leaveHoldActive = false
                Game.ui.send('hud:leaveHold', { visible = false, percent = 0 })
                Game.session:send('warmup.leave')
                return
            end

            Wait(50)
        end

        Game.ui.send('hud:leaveHold', { visible = false, percent = 0 })
    end)
end

local function cancelLeaveHold()

    if not leaveHoldActive then return end

    leaveHoldActive = false
    Game.ui.send('hud:leaveHold', { visible = false, percent = 0 })
end

-- Net events

Game.session:onNet('warmup.start', function(coords, countData, names)

    running = true
    passiveMode = true
    leaveHoldActive = false
    nameCache = {}

    if countData then
        playerCount.current = countData.current or 0
        playerCount.max = countData.max or 0
    end

    if names then
        for src, name in pairs(names) do nameCache[src] = name end
    end

    CreateThread(function()
        Pregame:spawn(coords)
        Pregame:sendShortcuts()
        Game.ui.send('show', true)
        Game.ui.send('hud:warmup', true)
    end)

    CreateThread(function()
        for k,v in pairs(GetGamePool('CObject')) do
            DeleteObject(v)
        end
    end)

    CreateThread(function()

        while running do
            Pregame:renderNametags()
            Wait(0)
        end
    end)

    CreateThread(function()

        while running do
            Wait(500)

            if GetEntityHealth(PlayerPedId()) <= 100 then
                Game.session:send('warmup.respawn')
            end
        end
    end)

    CreateThread(function()

        while running do

            if passiveMode then
                DisablePlayerFiring(PlayerPedId(), true)
                DisableControlAction(0, 140, true)
            end

            Wait(0)
        end
    end)
end)

Game.session:onNet('warmup.names', function(names)

    if not names then return end

    for src, name in pairs(names) do nameCache[src] = name end
end)

Game.session:onNet('warmup.playerCount', function(data)

    if not data or not running then return end

    playerCount.current = data.current or 0
    playerCount.max = data.max or 0
    Pregame:sendShortcuts()
end)

Game.session:onNet('warmup.respawn', function(coords)

    if not running then return end

    CreateThread(function()
        Pregame:spawn(coords)
    end)
end)

Game.session:onNet('warmup.countdown', function(seconds)

    CreateThread(function()

        local remaining = seconds

        while remaining > 0 and running do
            Game.ui.send('hud:safezone', {
                visible = true, title = 'PARTIDA INICIANDO',
                message = ('A partida inicia em %d segundos'):format(remaining),
            })
            Wait(1000)
            remaining = remaining - 1
        end

        Game.ui.send('hud:safezone', { visible = false, title = '', message = '' })
    end)
end)

Game.session:listen('phaseChange', function(newPhase)

    if newPhase == MatchState.AIRPLANE and running then
        Game.ui.send('hud:warmup', false)
        running = false
        leaveHoldActive = false

        local ped = PlayerPedId()

        if passiveMode then
            passiveMode = false
            Pregame:removePassive(ped)
        end

        RemoveAllPedWeapons(ped, true)
        ClearPedBloodDamage(ped)
        ClearPedTasks(ped)
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
        NetworkSetFriendlyFireOption(false)
        Pregame:hideShortcuts()
        nameCache = {}
    end
end)

-- Keybindings

RegisterCommand('+br:leave', startLeaveHold, false)
RegisterCommand('-br:leave', cancelLeaveHold, false)
RegisterKeyMapping('+br:leave', 'Segurar para voltar ao lobby', 'keyboard', 'F')

RegisterCommand('br:passive', function()

    if not running then return end

    Pregame:togglePassive()
end, false)
RegisterKeyMapping('br:passive', 'Entrar/Sair PVP', 'keyboard', 'G')
