local Totem = Game.module('totem')

local INTERACT_RANGE = 3.0
local CARD_RANGE = 2.0

local ACTIVE_HASH = `vdg_reviveativo`
local LOADING_HASH = `vdg_reviveloading`
local CHIP_HASH = `vdg_chiprevivekingg`

local cards = {}
local cardEntities = {}
local cardBlips = {}
local collectedCount = 0
local validSlots = {}
local platformPos = {}
local platformEntities = {}
local loadingEntities = {}
local channeling = false
local cycleStart = 0

function Totem:setup(ctx)
    cards = {}
    cardEntities = {}
    cardBlips = {}
    collectedCount = 0
    validSlots = {}
    platformPos = {}
    platformEntities = {}
    loadingEntities = {}
    channeling = false
    cycleStart = 0
end

function Totem:teardown(ctx)
    self:flush()
end

function Totem:flush()
    channeling = false
    cycleStart = 0
    cards = {}
    collectedCount = 0
    validSlots = {}

    for _, e in pairs(cardEntities) do
        if DoesEntityExist(e) then DeleteEntity(e) end
    end
    for _, b in pairs(cardBlips) do Game.removeBlip(b) end
    for _, e in pairs(platformEntities) do
        if DoesEntityExist(e) then DeleteEntity(e) end
    end
    for _, e in pairs(loadingEntities) do
        if DoesEntityExist(e) then DeleteEntity(e) end
    end

    cardEntities = {}
    cardBlips = {}
    platformEntities = {}
    loadingEntities = {}
end

function Totem:nearestCard()
    local origin = GetEntityCoords(PlayerPedId())
    for id, c in pairs(cards) do
        if #(origin - vec3(c.x, c.y, c.z)) <= CARD_RANGE then return id end
    end
end

function Totem:nearestPlatform()
    local origin = GetEntityCoords(PlayerPedId())
    for i = 1, #validSlots do
        local idx = validSlots[i]
        local p = platformPos[idx]
        if p and #(origin - vec3(p[1], p[2], p[3])) <= INTERACT_RANGE then return idx end
    end
end

Game.session:onNet('revive.init', function(slots)
    Totem:flush()
    validSlots = slots or {}
    collectedCount = 0

    platformPos = gPlatformCoords

    for i = 1, #validSlots do
        local idx = validSlots[i]
        local p = platformPos[idx]
        if p then
            Game.addBlip(vec3(p[1], p[2], p[3]), {
                icon = 398, color = 2, scale = 0.6,
                shortRange = true, label = 'Plataforma de Revive',
            })
        end
    end

    CreateThread(function()
        while Game.session:active() do
            Wait(1200)
            local cam = GetFinalRenderedCamCoord()
            for i = 1, #validSlots do
                local idx = validSlots[i]
                local p = platformPos[idx]
                if not p then goto skip end
                local d = #(vec2(cam.x, cam.y) - vec2(p[1], p[2]))
                if d <= 100.0 then
                    if not platformEntities[idx] then
                        local h = Game.requestAsset(ACTIVE_HASH)
                        if h then
                            platformEntities[idx] = CreateObjectNoOffset(h, p[1], p[2], p[3], false, false, false)
                            FreezeEntityPosition(platformEntities[idx], true)
                            SetModelAsNoLongerNeeded(h)
                        end
                    end
                else
                    if platformEntities[idx] and DoesEntityExist(platformEntities[idx]) then
                        DeleteEntity(platformEntities[idx])
                    end
                    platformEntities[idx] = nil
                end
                ::skip::
            end
        end
    end)

    CreateThread(function()
        while Game.session:active() do
            Wait(600)
            local cam = GetFinalRenderedCamCoord()
            for id, c in pairs(cards) do
                local d = #(vec2(cam.x, cam.y) - vec2(c.x, c.y))
                if d <= 80.0 then
                    if not cardEntities[id] then
                        local h = Game.requestAsset(CHIP_HASH)
                        if h then
                            cardEntities[id] = CreateObjectNoOffset(h, c.x, c.y, c.z, false, false, false)
                            FreezeEntityPosition(cardEntities[id], true)
                            SetModelAsNoLongerNeeded(h)
                            cardBlips[id] = Game.addBlip(vec3(c.x, c.y, c.z), {
                                icon = 306, color = 5, scale = 0.5, shortRange = true,
                            })
                        end
                    end
                else
                    if cardEntities[id] and DoesEntityExist(cardEntities[id]) then
                        DeleteEntity(cardEntities[id])
                    end
                    cardEntities[id] = nil
                    Game.removeBlip(cardBlips[id])
                    cardBlips[id] = nil
                end
            end
        end
    end)
end)

Game.session:onNet('revive.cardDropped', function(cardId, targetSrc, x, y, z)
    cards[cardId] = { src = targetSrc, x = x, y = y, z = z }
end)

local function removeCard(id)
    cards[id] = nil
    if cardEntities[id] and DoesEntityExist(cardEntities[id]) then
        DeleteEntity(cardEntities[id])
    end
    cardEntities[id] = nil
    Game.removeBlip(cardBlips[id])
    cardBlips[id] = nil
end

Game.session:onNet('revive.cardCollected', function(cardId)
    removeCard(cardId)
end)

Game.session:onNet('revive.cardPickedUp', function(cardId, totalCards)
    collectedCount = totalCards
    removeCard(cardId)
    Game.ui.send('hud:safezone', { visible = true, title = 'CARD', message = ('Card coletado! (%d)'):format(totalCards) })
    SetTimeout(2000, function()
        Game.ui.send('hud:safezone', { visible = false, title = '', message = '' })
    end)
end)

Game.session:onNet('revive.cardConsumed', function(remaining)
    collectedCount = remaining
    cycleStart = GetGameTimer()
end)

Game.session:onNet('revive.platformsUpdate', function(newSlots)
    local oldSet = {}
    for i = 1, #validSlots do oldSet[validSlots[i]] = true end
    validSlots = newSlots or {}
    local newSet = {}
    for i = 1, #validSlots do newSet[validSlots[i]] = true end
    for idx in pairs(oldSet) do
        if not newSet[idx] and platformEntities[idx] then
            if DoesEntityExist(platformEntities[idx]) then DeleteEntity(platformEntities[idx]) end
            platformEntities[idx] = nil
        end
    end
end)

Game.session:onNet('revive.totemStarted', function(totemIdx, playerSrc)
    local p = platformPos[totemIdx]
    if not p then return end
    if loadingEntities[totemIdx] and DoesEntityExist(loadingEntities[totemIdx]) then
        DeleteEntity(loadingEntities[totemIdx])
    end
    local h = Game.requestAsset(LOADING_HASH)
    if h then
        loadingEntities[totemIdx] = CreateObjectNoOffset(h, p[1], p[2], p[3], false, false, false)
        FreezeEntityPosition(loadingEntities[totemIdx], true)
        SetModelAsNoLongerNeeded(h)
    end
    if playerSrc == GetPlayerServerId(PlayerId()) then channeling = true end
end)

Game.session:onNet('revive.totemStopped', function(totemIdx, playerSrc)
    if loadingEntities[totemIdx] and DoesEntityExist(loadingEntities[totemIdx]) then
        DeleteEntity(loadingEntities[totemIdx])
    end
    loadingEntities[totemIdx] = nil
    if playerSrc == GetPlayerServerId(PlayerId()) then
        channeling = false
        Game.ui.send('hud:action', { visible = false, type = nil, text = '', cancelKey = '', progress = 0 })
    end
end)

Game.session:onNet('revive.playerRevived', function(x, y, z)
    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, x, y, z + 1.0, false, false, false)
    NetworkResurrectLocalPlayer(x, y, z + 1.0, 0.0, true, false)
    Wait(100)
    ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    ClearPedTasksImmediately(ped)
    SetEntityInvincible(ped, false)
    SetEntityVisible(ped, true)
    FreezeEntityPosition(ped, false)
    GiveWeaponToPed(ped, GetHashKey('WEAPON_PISTOL_MK2'), 50, false, true)
    Game.ui.send('hud:safezone', { visible = true, title = 'REVIVIDO', message = 'Voce foi revivido!' })
    SetTimeout(3000, function()
        Game.ui.send('hud:safezone', { visible = false, title = '', message = '' })
    end)
end)

Game.prompts.register({
    id = 'totem_card',
    priority = 12,
    label = function()
        return Totem:nearestCard() and 'COLETAR CARD' or nil
    end,
    available = function()
        return Game.session:active() and Totem:nearestCard() ~= nil
    end,
    execute = function() end,
})

Game.prompts.register({
    id = 'totem_platform',
    priority = 11,
    label = function()
        if channeling then return nil end
        if collectedCount <= 0 then return nil end
        local idx = Totem:nearestPlatform()
        if not idx then return nil end
        return ('USAR PLATAFORMA (%d cards)'):format(collectedCount)
    end,
    available = function()
        if not Game.session:active() then return false end
        if channeling then return false end
        if collectedCount <= 0 then return false end
        return Totem:nearestPlatform() ~= nil
    end,
    execute = function() end,
})

Game.session:listen('interact.pressed', function()
    if not Game.session:active() then return end

    local cardId = Totem:nearestCard()
    if cardId then
        Game.session:send('revive.collectCard', cardId)
        return
    end

    if channeling or collectedCount <= 0 then return end
    local idx = Totem:nearestPlatform()
    if not idx then return end

    channeling = true
    cycleStart = GetGameTimer()
    Game.session:send('revive.startTotem', idx)

    CreateThread(function()
        while channeling do
            Wait(0)
            if IsControlJustPressed(0, 200) then
                Game.session:send('revive.cancelTotem')
                channeling = false
                break
            end
            if GetEntityHealth(PlayerPedId()) <= 100 then
                Game.session:send('revive.cancelTotem')
                channeling = false
                break
            end
            if not Totem:nearestPlatform() then
                Game.session:send('revive.cancelTotem')
                channeling = false
                break
            end
            local pct = math.min((GetGameTimer() - cycleStart) / 5000, 1.0)
            Game.ui.send('hud:action', {
                visible = true,
                type = nil,
                text = ('REVIVENDO... (%d cards)'):format(collectedCount),
                cancelKey = 'ESC',
                progress = pct,
            })
        end
        Game.ui.send('hud:action', { visible = false, type = nil, text = '', cancelKey = '', progress = 0 })
    end)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= Game.resource then return end
    Totem:flush()
end)
