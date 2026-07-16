local Hud = Game.module('hud')

local compassRunning = false
local bigmapExpanded = false

function Hud:setup(ctx)
    ctx.tracker = Game.Tracker.new()
    compassRunning = false
    bigmapExpanded = false
end

function Hud:activate(ctx)
    compassRunning = true
    ctx:tick(function()
        if not compassRunning then return end
        if Game.deploy and Game.deploy.isParachuting and Game.deploy.isParachuting() then return end
        local rot = GetGameplayCamRot(2)
        local deg = math.floor(((360.0 - ((rot.z + 360.0) % 360.0)) + 360.0) % 360.0)
        Game.ui.send('hud:meters', { heading = deg })
    end)
end

function Hud:teardown(ctx)
    compassRunning = false
    bigmapExpanded = false
    SetBigmapActive(false, false)
    ctx.tracker:flush()
    Game.ui.send('hud:safezone', { visible = false, title = '', message = '' })
end

local function resolvePlayerName(src)

    if Game.session.names and Game.session.names[src] then
        return Game.session.names[src]
    end

    local pid = GetPlayerFromServerId(src)

    if pid ~= -1 then return GetPlayerName(pid) end

    return ('Player %d'):format(src)
end

Game.session:onNet('matchAlive.update', function(players, squads)
    Game.ui.send('hud:matchAlive', { players = players, squads = squads })
end)

Game.session:onNet('playerDeath', function(victimSrc, killerSrc, weaponHash)
    local victimName = resolvePlayerName(victimSrc)
    local killerName = ''
    local localSrc = GetPlayerServerId(PlayerId())
    local killerTeam, victimTeam = false, false

    if killerSrc and killerSrc > 0 then
        killerName = resolvePlayerName(killerSrc)
        for _, src in ipairs(Game.session.squad) do
            if src == killerSrc then killerTeam = true end
            if src == victimSrc then victimTeam = true end
        end
        if killerSrc == localSrc then killerTeam = true end
        if victimSrc == localSrc then victimTeam = true end
    end

    Game.ui.send('hud:killfeed', {
        killer = killerName,
        victim = victimName,
        killerIsTeam = killerTeam,
        victimIsTeam = victimTeam,
    })
end)

Game.session:onNet('completion.show', function(data)
    local placement = data and data.placement or 0
    local kills = data and data.kills or 0
    local winner = placement == 1

    if winner then
        local ped = PlayerPedId()
        ClearPedTasks(ped)
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CHEERING', 0, true)
    end

    Game.ui.send('hud:safezone', {
        visible = true,
        title = winner and 'VITORIA!' or 'DERROTA',
        message = ('Posicao: #%d  |  Kills: %d'):format(placement, kills),
    })
end)


RegisterCommand('+br:bigmap', function()
    if not Game.session:active() then return end
    bigmapExpanded = not bigmapExpanded
    SetBigmapActive(bigmapExpanded, false)
end, false)
RegisterKeyMapping('+br:bigmap', 'Minimapa Grande', 'keyboard', 'M')

CreateThread(function()

    Wait(1500)

    while true do

        if Game.session:active() and GetResourceState('minimap-racco') == 'started' then

            local ok, rect = pcall(exports['minimap-racco'].GetMinimapScreenRect, exports['minimap-racco'])

            if ok and rect then
                local sw, sh = GetActiveScreenResolution()
                local scaleX = 1920 / sw
                local scaleY = 1080 / sh

                Game.ui.send('hud:minimapFrame', {
                    x = rect.x * scaleX,
                    y = rect.y * scaleY,
                    w = rect.w * scaleX,
                    h = rect.h * scaleY,
                })
            end
        end

        Wait(2000)
    end
end)
