-- applier.lua
-- Generic applier registry. The actual register/runPhase implementation lives
-- on the Inventario object (client/main.lua); this file is intentionally light
-- so it loads first and exposes shared helpers if needed by other appliers.

-- Defensive: ensure Inventario exists even if module load order swaps. main.lua
-- replaces the table with the fully-featured version (same identity preserved
-- via merge below if needed).
if not Inventario then
    Inventario = {
        equipped = {},
        appliers = {},
        clothesMaps = nil,
        ready = false,
    }
    function Inventario:register(category, phases, fn)
        self.appliers[category] = { phases = phases or {}, fn = fn }
    end
    function Inventario:runPhase(phase, ctx)
        ctx = ctx or {}
        if not ctx.ped then ctx.ped = PlayerPedId() end
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
end

---Helper used by appliers when they need to await a value (e.g. control of an entity)
---@param check function   -- () -> boolean
---@param timeoutMs number | nil
---@param stepMs number | nil
---@return boolean ok
function Inventario_waitFor(check, timeoutMs, stepMs)
    timeoutMs = timeoutMs or 1000
    stepMs = stepMs or 50
    local deadline = GetGameTimer() + timeoutMs
    while GetGameTimer() < deadline do
        if check() then return true end
        Wait(stepMs)
    end
    return check() and true or false
end
