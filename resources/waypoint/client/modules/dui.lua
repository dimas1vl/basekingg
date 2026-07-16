---@class StandaloneDui
local StandaloneDui = {}
StandaloneDui.__index = StandaloneDui

local instanceId = 0

---@param options { url: string, width: number, height: number }
---@return StandaloneDui
function StandaloneDui.new(options)
    instanceId = instanceId + 1

    local txdName = ('swp_txd_%d'):format(instanceId)
    local txnName = ('swp_txn_%d'):format(instanceId)
    local duiObject = CreateDui(options.url, options.width, options.height)
    local duiHandle = GetDuiHandle(duiObject)
    local txd = CreateRuntimeTxd(txdName)

    CreateRuntimeTextureFromDuiHandle(txd, txnName, duiHandle)

    return setmetatable({
        duiObject = duiObject,
        duiHandle = duiHandle,
        dictName = txdName,
        txtName = txnName,
    }, StandaloneDui)
end

---@param payload table
function StandaloneDui:sendMessage(payload)
    if not self.duiObject then
        return
    end

    SendDuiMessage(self.duiObject, json.encode(payload))
end

function StandaloneDui:remove()
    if not self.duiObject then
        return
    end

    DestroyDui(self.duiObject)
    self.duiObject = nil
    self.duiHandle = nil
end

return StandaloneDui
