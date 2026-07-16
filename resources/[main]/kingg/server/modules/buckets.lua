while not Core do
    Wait(100)
end

---@class Buckets
---@field nextId number
---@field active table<number, true>
local Buckets = {
    nextId = 1,
    active = {},
}

---@return number bucket
function Buckets:allocate()

    local bucket = 100000 + self.nextId

    self.nextId = self.nextId + 1
    self.active[bucket] = true

    log('info', ('bucket %d allocated'):format(bucket))

    return bucket
end

---@param bucket number
function Buckets:release(bucket)

    self.active[bucket] = nil

    log('info', ('bucket %d released'):format(bucket))
end

Core.allocateBucket = function()
    return Buckets:allocate()
end

Core.releaseBucket = function(bucket)
    return Buckets:release(bucket)
end
