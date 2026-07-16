-- apply_clothes.lua
-- Centralized COMPONENT_MAP / PROP_MAP. Lobby imports via exports['lobby_inventory']:GetClothesMaps().

local COMPONENT_MAP = {
    masks        = 1,
    torsos       = 3,
    legs         = 4,
    bags         = 5,
    shoes        = 6,
    accessories  = 7,
    undershirts  = 8,
    bodyArmors   = 9,
    decals       = 10,
    tops         = 11,
}

local PROP_MAP = {
    hats      = 0,
    glasses   = 1,
    ears      = 2,
    watches   = 6,
    bracelets = 7,
}

Inventario.clothesMaps = {
    component = COMPONENT_MAP,
    prop      = PROP_MAP,
}

-- Default state per prop slot (used on unapply to restore vanilla look).
local DEFAULT_PROP_SLOTS = { 0, 1, 2, 6, 7 }
local DEFAULT_COMPONENT_RESET = {
    -- componentId = { drawable, texture, palette }
    [1]  = { 0, 0, 0 },
    [3]  = { 0, 0, 0 },
    [4]  = { 0, 0, 0 },
    [5]  = { 0, 0, 0 },
    [6]  = { 0, 0, 0 },
    [7]  = { 0, 0, 0 },
    [8]  = { 0, 0, 0 },
    [9]  = { 0, 0, 0 },
    [10] = { 0, 0, 0 },
    [11] = { 0, 0, 0 },
}

local function applyClothes(ctx, item)
    local ped = ctx and ctx.ped or PlayerPedId()
    if not ped or ped == 0 then return end
    local m = item and item.metadata
    if not m or not m.slot_id then return end

    if m.kind == 'component' then
        SetPedComponentVariation(ped, m.slot_id, m.drawable or 0, m.texture or 0, m.palette or 0)
    elseif m.kind == 'prop' then
        if (m.drawable or -1) == -1 then
            ClearPedProp(ped, m.slot_id)
        else
            SetPedPropIndex(ped, m.slot_id, m.drawable, m.texture or 0, true)
        end
    end
end

Inventario:register('clothes', { spawn = true, modelChange = true }, applyClothes)

-- Reset helper used by sync.lua on unapplyOne.
---@param ped number
---@param item table
function Inventario_resetClothes(ped, item)
    if not ped or ped == 0 then return end
    local m = item and item.metadata
    if not m or not m.slot_id then return end

    if m.kind == 'component' then
        local def = DEFAULT_COMPONENT_RESET[m.slot_id] or { 0, 0, 0 }
        SetPedComponentVariation(ped, m.slot_id, def[1], def[2], def[3])
    elseif m.kind == 'prop' then
        ClearPedProp(ped, m.slot_id)
    end
end
