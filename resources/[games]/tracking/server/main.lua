while not Core do
    Wait(100)
end

_G.log = Core.log

local TRACKING_MODE     = 'Treinamento'
local TRACKING_SUB_MODE = 'Rolamento com Bots + Tracking'

---@class TrackingSession
---@field src number
---@field bucket number
local sessions = {}

local function enterTracking(src)
    if sessions[src] then return end

    local bucket = Core.allocateBucket()
    SetPlayerRoutingBucket(tostring(src), bucket)

    sessions[src] = { src = src, bucket = bucket }

    TriggerClientEvent('tracking:enter', src)
    log('info', ('tracking: player %d entered (bucket %d)'):format(src, bucket))
end

local function leaveTracking(src)
    local session = sessions[src]
    if not session then return end

    TriggerClientEvent('tracking:leave', src)

    if DoesPlayerExist(tostring(src)) then
        SetPlayerRoutingBucket(tostring(src), src)
    end

    Core.releaseBucket(session.bucket)
    sessions[src] = nil

    log('info', ('tracking: player %d left'):format(src))
end

AddEventHandler('kingg:matchmaking:start', function(batch, mode, subMode)
    if mode ~= TRACKING_MODE or subMode ~= TRACKING_SUB_MODE then return end

    for i = 1, #batch do
        enterTracking(batch[i])
    end
end)

AddEventHandler('kingg:player:leave', function(src)
    leaveTracking(src)
end)

AddEventHandler('playerDropped', function()
    leaveTracking(source)
end)

RegisterNetEvent('multiTracking:server:whenKillNpc', function()
    -- Reservado pra estatística futura (XP, score, etc).
    -- Hoje só ignora pra não logar warning.
end)

-- Allow external callers to push a player back to the lobby (or kick them out).
exports('isInTracking', function(src)
    return sessions[src] ~= nil
end)

exports('leaveTracking', function(src)
    leaveTracking(src)
end)
