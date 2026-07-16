---@class LootRng

local FNV_OFFSET = 0x811c9dc5
local FNV_PRIME  = 0x01000193
local MASK_32    = 0xffffffff

---@param a number
---@param b number
---@return number
local function fnv1a(a, b)

    local h = FNV_OFFSET
    h = ((h ~ a) & MASK_32) * FNV_PRIME
    h = ((h ~ b) & MASK_32) * FNV_PRIME
    return h & MASK_32
end

---@param seed number
---@param idx number
---@param n number
---@return number float in [0, 1)
local function roll(seed, idx, n)

    local h = fnv1a(seed, idx)
    h = h ~ (h >> 13)
    h = h ~ ((h << 17) & MASK_32)
    h = h & MASK_32
    h = fnv1a(h, n)
    return (h % 100000) / 100000
end

LootRng = {
    ---@param seed number
    ---@param idx number
    ---@return number float in [0, 1)
    spawnRoll = function(seed, idx)
        return roll(seed, idx, 1)
    end,

    ---@param seed number
    ---@param idx number
    ---@param max number
    ---@return number int in [1, max]
    typeIndex = function(seed, idx, max)
        return 1 + math.floor(roll(seed, idx, 2) * max)
    end,

    ---@param seed number
    ---@param idx number
    ---@param max number
    ---@return number int in [1, max]
    lootIndex = function(seed, idx, max)
        return 1 + math.floor(roll(seed, idx, 3) * max)
    end,
}
