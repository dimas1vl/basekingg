Game = {}
Game.resource = GetCurrentResourceName()

Core = {
    _items = {},
}

function Core.prone()
    return Core._proneCheck and Core._proneCheck() or false
end

function Core.layingDown()
    return Core._layingCheck and Core._layingCheck() or false
end

function Core.setCrawl(val)
    if Core._crawlSet then Core._crawlSet(val) end
end

function Core.hasItem(key)
    return Core._items[key] and Core._items[key]() or false
end


---@param name string | number
---@param kind? 'anim' | 'audio'
---@return number | boolean | nil
function Game.requestAsset(name, kind)
    if kind == 'anim' then
        if HasAnimDictLoaded(name) then return true end
        RequestAnimDict(name)
        local timeout_at = GetGameTimer() + 10000
        while not HasAnimDictLoaded(name) do
            if GetGameTimer() > timeout_at then return nil end
            Wait(60)
        end
        if not HasAnimDictLoaded(name) then
            print("Game.requestAsset: anim dict not loaded", name)
            return false
        end
        return true
    end

    if kind == 'audio' then
        local ok = RequestScriptAudioBank(name, false)
        if ok then return true end
        local timeout_at = GetGameTimer() + 10000
        while not RequestScriptAudioBank(name, false) do
            if GetGameTimer() > timeout_at then return nil end
            Wait(60)
        end
        return true
    end

    local h = type(name) == 'number' and name or GetHashKey(name)
    if HasModelLoaded(h) then return h end
    if not IsModelInCdimage(h) then return nil end
    RequestModel(h)
    local timeout_at = GetGameTimer() + 10000
    while not HasModelLoaded(h) do
        if GetGameTimer() > timeout_at then return nil end
        Wait(80)
    end
    if not HasModelLoaded(h) then
        print("Game.requestAsset: model not loaded", name)
    end
    return h
end

---@param pos vector3 | table
---@param opts { icon?: number, color?: number, scale?: number, label?: string, display?: number, shortRange?: boolean, heading?: boolean, priority?: number }
---@return number
function Game.addBlip(pos, opts)
    local x = pos.x or pos[1]
    local y = pos.y or pos[2]
    local z = pos.z or pos[3] or 0.0
    local b = AddBlipForCoord(x, y, z)
    SetBlipDisplay(b, opts.display or 2)
    SetBlipScale(b, opts.scale or 0.8)
    if opts.heading then
        ShowHeadingIndicatorOnBlip(b, true)
    end
    SetBlipColour(b, opts.color or 0)
    SetBlipSprite(b, opts.icon or 1)
    SetBlipAsShortRange(b, opts.shortRange ~= false)
    if opts.priority then
        SetBlipPriority(b, opts.priority)
    end
    if opts.label then
        AddTextEntry('BL_' .. tostring(b), opts.label)
        BeginTextCommandSetBlipName('BL_' .. tostring(b))
        EndTextCommandSetBlipName(b)
    end
    return b
end

---@param blip number
function Game.removeBlip(blip)
    if DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
end

---@param hash number
---@param pos vector3 | table
---@param heading? number
---@param opts? { lod?: number, noCollision?: boolean, noFreeze?: boolean }
---@return number | nil
function Game.spawnProp(hash, pos, heading, opts)
    opts = opts or {}
    local h = Game.requestAsset(hash)
    if not h then return nil end
    local x = pos.x or pos[1]
    local y = pos.y or pos[2]
    local z = pos.z or pos[3]
    local entity = CreateObjectNoOffset(h, x, y, z, false, true, false)
    if not opts.noFreeze then
        FreezeEntityPosition(entity, true)
    end
    SetEntityCollision(entity, not opts.noCollision, not opts.noCollision)
    SetEntityHeading(entity, heading or 0.0)
    SetEntityLodDist(entity, opts.lod or 500)
    SetEntityAsMissionEntity(entity, true, true)
    SetModelAsNoLongerNeeded(h)
    return entity
end

---@param items table
---@param maxRange number
---@param getPos? fun(item: any): vector3
---@return any, any, number
function Game.closest(items, maxRange, getPos)
    local origin = GetEntityCoords(PlayerPedId())
    local pick, pickKey, pickDist = nil, nil, maxRange
    for k, v in pairs(items) do
        local p = getPos and getPos(v) or v.pos
        local d = #(origin - p)
        if d <= pickDist then
            pick, pickKey, pickDist = v, k, d
        end
    end
    return pickKey, pick, pickDist
end

---@param entity number
function Game.removeProp(entity)
    if DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, false, true)
        DeleteEntity(entity)
    end
end

---@param entity number
---@return boolean
function Game.loadCollision(entity)
    if not DoesEntityExist(entity) then return false end
    local pos = GetEntityCoords(entity)
    RequestCollisionAtCoord(pos.x, pos.y, pos.z)
    local tries = 40
    while not HasCollisionLoadedAroundEntity(entity) do
        tries = tries - 1
        if tries <= 0 then return false end
        Wait(80)
    end
    return true
end
