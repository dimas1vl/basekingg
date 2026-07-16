---@class Creator
---@field active boolean
Creator = {
    active = false
}

function Creator:open()
    if self.active then
        return
    end
    self.active = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open'
    })
end

function Creator:close()
    if not self.active then
        return
    end
    self.active = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'close'
    })
end

function Creator:boot()
    DoScreenFadeOut(0)
    Wait(500)
    local state = RPC.boot()
    if state == 'register' then
        self:open()
    end
end

RPC:bind({})

RegisterNUICallback('loaded', function(_, cb)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    print('ok')
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    Creator:close()
    cb('ok')
end)

RegisterNUICallback('checkName', function(data, cb)
    cb({
        available = RPC.checkName(data.name)
    })
end)

RegisterNUICallback('register', function(data, cb)
    local ok, err = RPC.register(data)
    cb({
        ok = ok,
        error = err
    })
    if ok then
        Creator:close()
    end
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    CreateThread(function()
        Creator:boot()
    end)
end)
