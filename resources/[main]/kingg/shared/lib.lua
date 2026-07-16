local CURRENT_RESOURCE = GetCurrentResourceName()
local isServer = IsDuplicityVersion()

if CURRENT_RESOURCE ~= 'kingg' and isServer then
    _G.Core = exports['kingg']:GetCore()
end

RPC = {}
RPC.__index = RPC


local callbacks = {}
local requestId = 0
local promise = promise

local function genId()
    requestId = requestId + 1
    return requestId
end

function RPC:bind(api)
    local res = GetCurrentResourceName()

    for name, fn in pairs(api) do
        if type(fn) == "function" then
            local event = ("net.%s:%s"):format(res, name)

            RegisterNetEvent(event)
            AddEventHandler(event, function(args, id)
                local src = source
                local result = { fn(table.unpack(args)) }

                if id then
                    local resEvent = ("net.%s:res"):format(res)

                    if isServer then
                        TriggerClientEvent(resEvent, src, id, result)
                    else
                        TriggerServerEvent(resEvent, id, result)
                    end
                end
            end)
        end
    end

    local resEvent = ("net.%s:res"):format(res)

    RegisterNetEvent(resEvent)
    AddEventHandler(resEvent, function(id, result)
        local cb = callbacks[id]
        if cb then
            callbacks[id] = nil
            cb(table.unpack(result))
        end
    end)
end

function RPC:new(resource)
    return setmetatable({ resource = resource }, {
        __index = function(self, key)
            local noWait = key:sub(1,1) == "_"
            local fname = noWait and key:sub(2) or key

            return function(...)
                local args = {...}
                local id = nil

                if not noWait then
                    id = genId()
                end

                local event = ("net.%s:%s"):format(self.resource, fname)
                local p = nil
                if not noWait then
                    p = promise.new()

                    callbacks[id] = function(...)
                        p:resolve({...})
                    end
                end

                if isServer then
                    local target = args[1]
                    table.remove(args,1)

                    TriggerClientEvent(event, target, args, id)
                else
                    TriggerServerEvent(event, args, id)
                end

                if not noWait then
                    local res = Citizen.Await(p)
                    return table.unpack(res)
                end
            end
        end
    })
end

setmetatable(RPC, {
    __index = function(_, key)
        local current = RPC:new(GetCurrentResourceName())
        return current[key]
    end
})

