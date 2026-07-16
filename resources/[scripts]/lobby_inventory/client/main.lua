---@class InventarioClient
---@field equipped table<string, table<string|number, table>>  -- equipped[category][slot] = item
---@field appliers table<string, { phases: table<string, boolean>, fn: function }>
---@field clothesMaps table | nil
Inventario = Inventario or {
    equipped = {},
    appliers = {},
    clothesMaps = nil,
    ready = false,
}
Inventario.equipped    = Inventario.equipped or {}
Inventario.appliers    = Inventario.appliers or {}
Inventario.clothesMaps = Inventario.clothesMaps or nil
if Inventario.ready == nil then Inventario.ready = false end

---@param category string
---@param phases table<string, boolean>   -- e.g. { spawn=true, modelChange=true }
---@param fn function                     -- fn(ctx, item)
function Inventario:register(category, phases, fn)
    self.appliers[category] = {
        phases = phases or {},
        fn = fn,
    }
end

---@param phase string
---@param ctx table
function Inventario:runPhase(phase, ctx)
    ctx = ctx or {}
    if not ctx.ped then
        ctx.ped = PlayerPedId()
    end

    for category, applier in pairs(self.appliers) do
        if applier.phases[phase] then
            local slots = self.equipped[category]
            if slots then
                for _, item in pairs(slots) do
                    if item then
                        local ok, err = pcall(applier.fn, ctx, item)
                        if not ok then
                            print(('[inventario] applier error category=%s phase=%s: %s'):format(category, phase, tostring(err)))
                        end
                    end
                end
            end
        end
    end
end

---@param category string
---@param item table
---@param ctx table | nil
function Inventario:applyOne(category, item, ctx)
    local applier = self.appliers[category]
    if not applier or not item then return end
    ctx = ctx or { ped = PlayerPedId() }
    if not ctx.ped then ctx.ped = PlayerPedId() end
    local ok, err = pcall(applier.fn, ctx, item)
    if not ok then
        print(('[inventario] applyOne error category=%s: %s'):format(category, tostring(err)))
    end
end

-- Register RPC response listener (no methods — only consumer of net.inventario:res).
RPC:bind({})

-- Expose COMPONENT_MAP / PROP_MAP to other resources (lobby reuses these).
exports('GetClothesMaps', function()
    return Inventario.clothesMaps or {
        component = {},
        prop = {},
    }
end)
