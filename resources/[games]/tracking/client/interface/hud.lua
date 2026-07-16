--[[ HUD client: contador de kills do treino e mensagem do
     footer controller (NUI). Inclui keymapping para resetar kills. ]]

local killsCount = 0

local function resetKills()
    killsCount = 0
    TriggerEvent("hud:startTraining", { kills = killsCount })
end

local function incrementKills()
    killsCount = killsCount + 1
    TriggerEvent("hud:updateTrainingStats", { kills = killsCount })
end

local function sendFooterControllerMessage(visible, spawn)
    SendNUIMessage({
        action = "footerController",
        data = {
            visible = visible == true,
            spawn = spawn or "",
        },
    })
end
SendFooterControllerMessage = sendFooterControllerMessage

AddEventHandler("multiTracking:client:npcKilled", function()
    incrementKills()
end)

AddEventHandler("multiTracking:client:resetKills", function()
    resetKills()
end)

RegisterCommand("multiTracking:resetKills", function()
    if not IsEnabledMultiTracking() then return end
    resetKills()
end, false)

local function toggleTrainingHud(active)
    if active then
        TriggerEvent("hud:startTraining", { kills = killsCount })
    else
        resetKills()
    end
end

RegisterKeyMapping("multiTracking:resetKills", "[Tracking Paraquedas] Resetar kills", "keyboard", "RETURN")

AddEventHandler("multiTracking:whenEnter", function()
    toggleTrainingHud(true)
end)

AddEventHandler("multiTracking:whenLeave", function()
    toggleTrainingHud(false)
end)
