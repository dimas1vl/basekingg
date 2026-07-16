--[[
    Minimal CircleZone shim that mimics PolyZone's CircleZone API surface
    used by the tracking resource. Only what we actually use is implemented.

    API:
        local zone = CircleZone:Create(center, radius, { name=, useZ=, debugPoly= })
        zone:onPlayerInOut(handler, intervalMs?)
        zone:isPointInside(point) -> bool
        zone:getCenter() / zone:getRadius()
        zone:destroy()
]]

CircleZone = {}
CircleZone.__index = CircleZone

---@param center vector3
---@param radius number
---@param options table | nil
function CircleZone:Create(center, radius, options)
    options = options or {}
    local r = (tonumber(radius) or 0.0) + 0.0
    local zone = setmetatable({
        name         = options.name or 'circle_zone',
        center       = center,
        radius       = r,
        radiusSq     = r * r,
        useZ         = options.useZ == true,
        data         = options.data,
        debugPoly    = options.debugPoly == true,
        destroyed    = false,
        playerInside = false,
        handler      = nil,
        pollMs       = 250,
        threadId     = 0,
    }, CircleZone)
    return zone
end

local function distanceSq(z, point)
    local dx = point.x - z.center.x
    local dy = point.y - z.center.y
    if z.useZ then
        local dz = point.z - z.center.z
        return dx * dx + dy * dy + dz * dz
    end
    return dx * dx + dy * dy
end

function CircleZone:isPointInside(point)
    if not point then return false end
    return distanceSq(self, point) <= self.radiusSq
end

---Register a handler that fires when the local player enters/leaves the zone.
---@param handler fun(isInside: boolean, point: vector3)
---@param intervalMs number | nil
function CircleZone:onPlayerInOut(handler, intervalMs)
    if type(handler) ~= 'function' then return end
    self.handler = handler
    if tonumber(intervalMs) then
        self.pollMs = math.max(0, tonumber(intervalMs))
    end

    self.threadId = self.threadId + 1
    local myId = self.threadId
    local self_ref = self
    CreateThread(function()
        while not self_ref.destroyed and myId == self_ref.threadId do
            local ped = PlayerPedId()
            local pc  = GetEntityCoords(ped)
            local inside = distanceSq(self_ref, pc) <= self_ref.radiusSq

            if inside ~= self_ref.playerInside then
                self_ref.playerInside = inside
                local ok, err = pcall(self_ref.handler, inside, pc)
                if not ok then
                    print(('[CircleZone shim] handler error on %s: %s'):format(self_ref.name, tostring(err)))
                end
            end

            Wait(self_ref.pollMs)
        end
    end)
end

function CircleZone:destroy()
    self.destroyed = true
    self.handler = nil
    self.threadId = self.threadId + 1 -- invalidate any running thread
end

function CircleZone:getCenter()
    return self.center
end

function CircleZone:getRadius()
    return self.radius
end

_G.CircleZone = CircleZone
