-- Exports

---@param items table | nil
local function show(items)

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    SendNUIMessage({ action = 'show' })

    if items then
        SetTimeout(100, function()
            SendNUIMessage({ action = 'setInventory', data = { items = items } })
        end)
    end
end

local function hide()

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'close' })
end

---@param items table
local function setItems(items)

    SendNUIMessage({ action = 'setInventory', data = { items = items } })
end

exports('Show', show)
exports('Hide', hide)
exports('SetItems', setItems)

-- NUI Callbacks

RegisterNUICallback('swapSlots', function(data, cb)

    TriggerEvent('inventory:swapSlots', data)
    cb('ok')
end)

RegisterNUICallback('useItem', function(data, cb)

    TriggerEvent('inventory:useItem', data)
    cb('ok')
end)

RegisterNUICallback('moveItem', function(data, cb)

    TriggerEvent('inventory:moveItem', data)
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    TriggerEvent('inventory:close')
    cb('ok')
end)
