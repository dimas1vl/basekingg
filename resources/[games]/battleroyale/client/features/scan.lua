local Scan = Game.module('scan')

local hasDevice = false
local activeBlips = {}

function Scan:setup(ctx)
    hasDevice = false
    activeBlips = {}
end

function Scan:teardown(ctx)
    hasDevice = false
    self:clearBlips()
end

function Scan:clearBlips()
    for i = 1, #activeBlips do
        Game.removeBlip(activeBlips[i])
    end
    activeBlips = {}
end

Core._items['UAV'] = function() return hasDevice end

Game.session:onNet('vant.set', function(enabled)
    hasDevice = enabled
    if enabled then
        Game.ui.notify('Habilidade especial disponivel [X]', 5)
    end
end)

RegisterCommand('+br:vant', function()
    if not Game.session:active() then return end
    if not hasDevice then return end
    hasDevice = false
    Game.session:send('vant.use')
end, false)
RegisterKeyMapping('+br:vant', 'Usar UAV', 'keyboard', 'X')

Game.session:onNet('vant.result', function(positions, radius)
    Scan:clearBlips()

    for _, pos in ipairs(positions) do
        local b = AddBlipForCoord(pos.x, pos.y, pos.z)
        SetBlipDisplay(b, 2)
        SetBlipSprite(b, 423)
        SetBlipScale(b, 0.75)
        SetBlipColour(b, 3)
        activeBlips[#activeBlips + 1] = b
    end

    if radius then
        local coords = GetEntityCoords(PlayerPedId())
        local rb = AddBlipForRadius(coords.x, coords.y, 0.0, radius * 1.0)
        SetBlipColour(rb, 3)
        SetBlipAlpha(rb, 80)
        activeBlips[#activeBlips + 1] = rb
    end

    SetTimeout(Config.BR.vant.duration, function()
        Scan:clearBlips()
    end)
end)


local Radar = {
    cooldown = 0,
    blips = {},
    models = {
        [`kingg_lootbox_red`] = {color = 1, sprite = 587},
        [`kingg_lootbox_blue`] = {color = 3, sprite = 587},
        [`kingg_lootbox_grenn`] = {color = 2, sprite = 587},
        [`kingg_lootbox_yellow`] = {color = 5, sprite = 587},
        [`kingg_lootbox_purple`] = {color = 27, sprite = 587},
        [`Addon001`] = {color = 0, sprite = 225},
    }
}

function Radar:parsePool(pool_name)
    local pool = GetGamePool(pool_name)
    for i = 1, #pool do
        local entity = pool[i]
        local model = GetEntityModel(entity)
        if self.models[model] then
            local sprite, color = self.models[model].sprite, self.models[model].color
            local blip = AddBlipForEntity(entity)
            SetBlipSprite(blip, sprite)
            SetBlipColour(blip, color)
            SetBlipScale(blip, 0.7)
            SetBlipAsShortRange(blip, true)
            SetBlipHiddenOnLegend(blip, true)
            SetBlipDisplay(blip, 2)
            self.blips[#self.blips + 1] = blip
        end
    end
    
end

RegisterCommand("br:detect", function()
    if not Game.session:active() then return end
    local now = GetGameTimer()
    if now < Radar.cooldown then return end
    Radar.cooldown = now + 8000
    Radar:parsePool('CVehicle')
    Radar:parsePool('CObject')
    SetTimeout(8000, function()
        for i = 1, #Radar.blips do
            if DoesBlipExist(Radar.blips[i]) then
                RemoveBlip(Radar.blips[i])
            end
        end
        Radar.blips = {}
    end)
end)

RegisterKeyMapping("br:detect", "Detectar baús e veículos próximos.", "keyboard", "Y")
