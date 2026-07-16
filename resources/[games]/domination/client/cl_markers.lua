local lastHp = {}

local function seedNearby()
    local myPed = PlayerPedId()
    if myPed == 0 then return end
    local present = {}
    for _, pid in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(pid)
        if ped ~= 0 and ped ~= myPed and DoesEntityExist(ped) then
            present[ped] = true
            local cur = GetEntityHealth(ped)
            local prev = lastHp[ped]
            if prev == nil or cur > prev then
                lastHp[ped] = cur
            end
        end
    end
    for ped in pairs(lastHp) do
        if not present[ped] then lastHp[ped] = nil end
    end
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    if not Zone.active or not DomSettings then return end

    local victim   = args[1]
    local attacker = args[2]
    local myPed    = PlayerPedId()

    if attacker == myPed and victim and victim ~= 0 and victim ~= myPed
        and IsEntityAPed(victim) and IsPedAPlayer(victim) then
        local now  = GetEntityHealth(victim)
        local prev = lastHp[victim]
        lastHp[victim] = now
        local delta = prev and (prev - now) or 0
        if prev == nil or delta > 0 then
            SendNUIMessage({ action = 'sfx', cat = 'hit' })
        end
        if prev and delta > 0 and DomSettings.hud.dmgMarker then
            local pos = GetEntityCoords(victim)
            local onScreen, sx, sy = GetScreenCoordFromWorldCoord(pos.x, pos.y, pos.z + 0.65)
            if onScreen then
                SendNUIMessage({
                    action = 'damageMarker',
                    amount = math.floor(delta + 0.5),
                    x      = sx,
                    y      = sy,
                    color  = DomSettings.hud.dmgColor,
                })
            end
        end
    elseif victim == myPed and attacker and attacker ~= 0 and attacker ~= myPed
        and IsEntityAPed(attacker) and IsPedAPlayer(attacker) then
        SendNUIMessage({ action = 'sfx', cat = 'ping' })
    end
end)

CreateThread(function()
    while true do
        if Zone.active then
            seedNearby()
            Wait(300)
        else
            if next(lastHp) then lastHp = {} end
            Wait(1000)
        end
    end
end)
