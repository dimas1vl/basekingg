Game.ui = {}

---@param action string
---@param data? any
function Game.ui.send(action, data)
    SendNUIMessage({ action = action, data = data })
end

---@param text string
---@param duration? number
function Game.ui.notify(text, duration)
    Game.ui.send('hud:safezone', {
        visible = true,
        title = 'ATENÇÃO',
        message = text,
    })
    if duration then
        SetTimeout(duration * 1000, function()
            Game.ui.send('hud:safezone', { visible = false, title = '', message = '' })
        end)
    end
end

---@class HoldActionOpts
---@field label string
---@field key? string
---@field duration number
---@field type? 'medkit' | 'reload'
---@field done? fun()
---@field fail? fun()
---@field check? fun(pct: number): boolean
---@field onProgress? fun(pct: number)

---@param opts HoldActionOpts
---@return fun()
function Game.ui.holdAction(opts)
    local t0 = GetGameTimer()
    local alive = true
    local finished = false
    local actionType = opts.type or 'medkit'

    local function hide()
        Game.ui.send('hud:action', { visible = false, type = actionType, text = '', cancelKey = '', progress = 0 })
    end

    Game.ui.send('hud:action', {
        visible = true,
        type = actionType,
        text = opts.label,
        cancelKey = opts.key or 'E',
        progress = 0,
    })

    if opts.onProgress then opts.onProgress(0) end

    local function step()
        if not alive then return end
        local pct = (GetGameTimer() - t0) / opts.duration
        if pct >= 1.0 then
            alive = false
            finished = true
            if opts.onProgress then opts.onProgress(1) end
            hide()
            if opts.done then opts.done() end
            return
        end
        if opts.check and opts.check(pct) then
            alive = false
            if opts.onProgress then opts.onProgress(0) end
            hide()
            if opts.fail then opts.fail() end
            return
        end
        if opts.onProgress then opts.onProgress(pct) end
        Game.ui.send('hud:action', {
            visible = true,
            type = actionType,
            text = opts.label,
            cancelKey = opts.key or 'E',
            progress = pct,
        })
        SetTimeout(0, step)
    end

    step()

    return function()
        if not alive then return end
        alive = false
        if opts.onProgress then opts.onProgress(0) end
        hide()
        if not finished and opts.fail then opts.fail() end
    end
end
