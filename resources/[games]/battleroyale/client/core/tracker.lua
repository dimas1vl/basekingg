---@class Tracker
---@field entities table<string, number>
---@field blips table<string, number>
local Tracker = {}
Tracker.__index = Tracker

---@return Tracker
function Tracker.new()
    return setmetatable({
        entities = {},
        blips = {},
    }, Tracker)
end

---@param key string
---@param spawner fun(): number
function Tracker:ensure(key, spawner)
    if self.entities[key] then return self.entities[key] end
    local entity = spawner()
    if entity then
        self.entities[key] = entity
    end
    return entity
end

---@param key string
function Tracker:remove(key)
    local entity = self.entities[key]
    if entity then
        Game.removeProp(entity)
        self.entities[key] = nil
    end
end

---@param key string
---@return number | nil
function Tracker:get(key)
    return self.entities[key]
end

---@param key string
---@return boolean
function Tracker:has(key)
    return self.entities[key] ~= nil
end

---@param key string
---@param pos vector3 | table
---@param opts { icon?: number, color?: number, scale?: number, label?: string, shortRange?: boolean, display?: number }
---@return number
function Tracker:addBlip(key, pos, opts)
    if self.blips[key] then
        Game.removeBlip(self.blips[key])
    end
    local blip = Game.addBlip(pos, opts)
    self.blips[key] = blip
    return blip
end

---@param key string
function Tracker:removeBlip(key)
    if self.blips[key] then
        Game.removeBlip(self.blips[key])
        self.blips[key] = nil
    end
end

---@param key string
---@return number | nil
function Tracker:getBlip(key)
    return self.blips[key]
end

function Tracker:flush()
    for key, entity in pairs(self.entities) do
        Game.removeProp(entity)
        self.entities[key] = nil
    end
    for key, blip in pairs(self.blips) do
        Game.removeBlip(blip)
        self.blips[key] = nil
    end
end

---@param locations table
---@param opts { icon?: number, color?: number, scale?: number, label?: string, shortRange?: boolean, display?: number }
---@param getPos? fun(item: any): vector3
function Tracker:spawnBlips(locations, opts, getPos)
    for k, loc in pairs(locations) do
        local pos = getPos and getPos(loc) or loc.pos or loc
        self:addBlip(tostring(k), pos, opts)
    end
end

Game.Tracker = Tracker
