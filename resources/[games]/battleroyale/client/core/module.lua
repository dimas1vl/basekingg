local registry = {}

---@class ModuleContext
---@field alive boolean
---@field _timers table
---@field _threads table
local ModuleContext = {}
ModuleContext.__index = ModuleContext

function ModuleContext.new()
    return setmetatable({
        alive = false,
        _timers = {},
        _threads = {},
    }, ModuleContext)
end

---@param interval number
---@param fn fun()
function ModuleContext:poll(interval, fn)
    self.alive = true
    local id = #self._timers + 1
    local function tick()
        if not self.alive then return end
        fn()
        if self.alive then
            self._timers[id] = SetTimeout(interval, tick)
        end
    end
    self._timers[id] = SetTimeout(interval, tick)
end

---@param fn fun()
function ModuleContext:tick(fn)
    self.alive = true
    local id = #self._threads + 1
    self._threads[id] = true
    CreateThread(function()
        while self.alive do
            fn()
            Wait(0)
        end
        self._threads[id] = nil
    end)
end

function ModuleContext:destroy()
    self.alive = false
    self._timers = {}
    self._threads = {}
end

---@param name string
---@return table
function Game.module(name)
    local mod = { _name = name }
    local ctx = ModuleContext.new()

    function mod:_activate(...)
        ctx = ModuleContext.new()
        ctx.alive = true
        if self.setup then
            self:setup(ctx, ...)
        end
        if self.activate then
            self:activate(ctx)
        end
    end

    function mod:_teardown()
        if self.teardown then
            pcall(self.teardown, self, ctx)
        end
        ctx:destroy()
    end

    function mod:ctx()
        return ctx
    end

    registry[name] = mod
    return mod
end

Game.session:listen('phaseChange', function(newState)

    if newState == MatchState.STARTED then

        print('[module] phaseChange → STARTED: activating all modules')

        for name, mod in pairs(registry) do

            print(('[module] activating: %s'):format(name))

            local ok, err = pcall(mod._activate, mod)

            if not ok then
                print(('[module] FAILED to activate %s: %s'):format(name, tostring(err)))
            end
        end
    end
end)

Game.session:listen('ended', function()

    print('[module] match ended: tearing down all modules')

    for name, mod in pairs(registry) do
        pcall(mod._teardown, mod)
    end
end)
