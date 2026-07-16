local Transport = Game.module('transport')

local LOD_RANGE = Config.BR.vehicles.lodDistance
local UNLOCK_RANGE = Config.BR.vehicles.unlockRange

local FLEET = {
    street = { 'Addon001'},
}

local fleet = {}
local seeded = false

function Transport:setup(ctx)
    ctx.tracker = Game.Tracker.new()
    fleet = {}
    seeded = false
end

function Transport:teardown(ctx)
    for _, v in ipairs(fleet) do
        self:despawn(v)
    end
    fleet = {}
    seeded = false
    ctx.tracker:flush()
end

function Transport:despawn(v)
    if v.entity and DoesEntityExist(v.entity) and not v.cracked then
        DeleteEntity(v.entity)
        v.entity = nil
    end
    Game.removeBlip(v.marker)
    v.marker = nil
end


function Transport:spawn(v)
    if v.cracked then return end
    if v.entity and DoesEntityExist(v.entity) then return end
    local h = Game.requestAsset(v.model)
    if not h then return end
    local c = v.coords
    local _, groundZ = GetGroundZFor_3dCoord(c.x, c.y, c.z, true)
    v.entity = CreateVehicle(h, c.x, c.y, groundZ or c.z, c.w, false, false)
    if not DoesEntityExist(v.entity) then return end
    SetVehicleDirtLevel(v.entity, 0.0)
    SetEntityCollision(v.entity, false, true)
    FreezeEntityPosition(v.entity, true)
    SetEntityAlpha(v.entity, 180, false)
    SetVehicleDoorsLocked(v.entity, 2)
    SetModelAsNoLongerNeeded(h)

    v.marker = Game.addBlip(vec3(c.x, c.y, c.z), {
        icon = 225, color = 3, scale = 0.7,
        shortRange = true,
    })
end

function Transport:spawnNetworked(v)
    local h = Game.requestAsset(v.model)
    if not h then return nil end
    local c = v.coords
    local veh = CreateVehicle(h, c.x, c.y, c.z, c.w, true, true)
    if not DoesEntityExist(veh) then return nil end
    SetVehicleDirtLevel(veh, 0.0)
    SetEntityCollision(veh, true, true)
    FreezeEntityPosition(veh, false)
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetModelAsNoLongerNeeded(h)
    return veh
end

function Transport:findNearest()
    local origin = GetEntityCoords(PlayerPedId())
    local best, bestDist = nil, UNLOCK_RANGE + 1
    for _, v in ipairs(fleet) do
        if v.cracked then goto skip end
        local c = v.coords
        local d = #(origin - vec3(c.x, c.y, c.z))
        if d < bestDist then best, bestDist = v, d end
        ::skip::
    end
    return best, bestDist
end

Game.session:onNet('match.seed', function(seed)
    local spawnData = gVehicleCoords
    if not spawnData then return end

    fleet = {}

    for i, entry in ipairs(spawnData) do
        local x, y, z, heading = entry.x, entry.y, entry.z, entry.w
        if LootRng.spawnRoll(seed, i) < Config.BR.vehicles.spawnChance then
            if type(isCoordsSafezone) == 'function' and not isCoordsSafezone(x, y) then
                goto next
            end
            local models = FLEET.street
            local mi = LootRng.typeIndex(seed, i, #models)
            fleet[#fleet + 1] = {
                idx = i,
                coords = vector4(x, y, z, heading),
                category = 'street',
                model = models[mi],
                entity = nil,
                marker = nil,
                cracked = false,
            }
        end
        ::next::
    end

    seeded = true
end)

Game.session:onNet('vehicles.unlocked', function(vehicleIndex, unlockerSrc)
    local me = GetPlayerServerId(PlayerId())
    for _, v in ipairs(fleet) do
        if v.idx == vehicleIndex then
            v.cracked = true
            if v.entity and DoesEntityExist(v.entity) then
                DeleteEntity(v.entity)
                v.entity = nil
            end
            Game.removeBlip(v.marker)
            v.marker = nil
            if unlockerSrc == me then
                v.entity = Transport:spawnNetworked(v)
                if v.entity then
                    SetPedIntoVehicle(PlayerPedId(), v.entity, -1)
                end
            end
            break
        end
    end
end)

CreateThread(function()
    while true do
        if seeded and Game.session:active() then
            local cam = GetFinalRenderedCamCoord()
            for _, v in ipairs(fleet) do
                local c = v.coords
                local d = #(vec2(cam.x, cam.y) - vec2(c.x, c.y))
                if d <= LOD_RANGE then
                    Transport:spawn(v)
                else
                    Transport:despawn(v)
                end
            end
            Wait(800)
        else
            Wait(2000)
        end
    end
end)

Game.prompts.register({
    id = 'transport_unlock',
    priority = 5,
    label = function()
        local v = Transport:findNearest()
        if not v then return nil end
        return 'DESTRANCAR'
    end,
    available = function()
        if not seeded then return false end
        if Game.session:currentPhase() ~= MatchState.STARTED then return false end
        return Transport:findNearest() ~= nil
    end,
    execute = function() end,
})

Game.session:listen('interact.pressed', function()
    if not seeded then return end
    if Game.session:currentPhase() ~= MatchState.STARTED then return end

    local v = Transport:findNearest()
    if not v then return end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return end
    if Core.prone() then return end

    Game.session:send('vehicles.unlock', v.idx)
end)


Game.session:onNet('radar.vehicles', function(range)
    local origin = GetEntityCoords(PlayerPedId())
    for _, veh in pairs(GetGamePool('CVehicle')) do
        local pos = GetEntityCoords(veh)
        local d = #(origin - pos)
        if d <= range then
            local b = Game.addBlip(pos, { icon = 225, color = 22, scale = 0.7, shortRange = true, label = 'Veiculo' })
            SetTimeout(10000, function() Game.removeBlip(b) end)
        end
    end
end)
