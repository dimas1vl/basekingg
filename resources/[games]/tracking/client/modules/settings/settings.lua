--[[ Registra o painel customizado de configuracoes do MultiTracking
     na resource `settings`, expondo controles por categoria (geral,
     paraquedas, veiculos, corrida, rolamento, area) e presets de dificuldade. ]]

local function OpenMultiTrackingSettingsPanel(useNearestZone)
    -- O novo painel F7 (panel.lua) substitui isto. Esta função antiga só roda
    -- se houver uma resource externa `settings` (sistema legado).
    if GetResourceState("settings") ~= "started" then
        return
    end
    if not IsEnabledMultiTracking() then
        return
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearestZoneLabel = GetNearestZoneLabel(playerCoords)

    local defaultCategory
    if useNearestZone then
        defaultCategory = nearestZoneLabel
    end

    exports.settings:openCustomPanel("multiTracking", defaultCategory)
end

local function BuildDifficultyOptions(configBuilder)
    if not configBuilder then
        return nil
    end
    if not configBuilder.getSettingsLevelDifficulty then
        return nil
    end

    local levels = configBuilder.getSettingsLevelDifficulty()
    if "table" ~= type(levels) then
        return nil
    end
    if 0 == #levels then
        return nil
    end

    local options = {}
    options[1] = {
        label = "Customizado",
        value = 0,
    }
    for i = 1, #levels do
        local idx = #options + 1
        options[idx] = {
            label = "N\195\173vel " .. i,
            value = #options,
        }
    end
    return options
end

local function AppendDifficultyItem(items, configBuilder, category, stateName)
    local options = BuildDifficultyOptions(configBuilder)
    if not options then
        return
    end

    local idx = #items + 1
    local item = {
        stateName = stateName,
        title = "N\195\173vel de Dificuldade",
        tooltip = "Aplica um preset de dificuldade para este modo",
        type = "input",
        category = category,
        order = 0,
        options = options,
    }

    function item.getCurrentValue()
        if not configBuilder then
            return 0
        end
        if not configBuilder.getSelectedLevelDifficulty then
            return 0
        end
        local current = configBuilder.getSelectedLevelDifficulty()
        local num = tonumber(current)
        if not num then
            num = -1
        end
        if num <= 0 then
            return 0
        end
        return num
    end

    function item.whenExecute(value)
        if not configBuilder then
            return
        end
        local num = tonumber(value)
        if not num then
            num = 0
        end
        if num <= 0 then
            if configBuilder.markCustomDifficulty then
                configBuilder.markCustomDifficulty()
            end
            return
        end
        if not configBuilder.applyDifficultyLevel then
            return
        end
        configBuilder.applyDifficultyLevel(num)
    end

    items[idx] = item
end

AddEventHandler("multiTracking:client:difficultyApplied", function(modeName, levelValue)
    if "string" ~= type(modeName) then
        return
    end
    if not tonumber(levelValue) then
        return
    end
    OpenMultiTrackingSettingsPanel(false)
end)

local vehicleModeEnabled = GetConvarBool("multiTrackingVehicleModeEnabled", true)

local function RegisterSettingsPanel()
    if "started" ~= GetResourceState("settings") then
        return
    end

    local generalConfig = GetGlobalConfigBuilder("general")
    local vehiclesConfig = nil
    if vehicleModeEnabled then
        vehiclesConfig = GetGlobalConfigBuilder("vehicles")
    end
    local parachuteConfig = GetGlobalConfigBuilder("parachute")
    local runnerConfig = GetGlobalConfigBuilder("runner")
    local rollConfig = GetGlobalConfigBuilder("roll")
    local areaConfig = GetGlobalConfigBuilder("area")

    local items = {}

    -- general: mapBlipsEnabled
    local mapBlipsItem = {
        stateName = "mapBlipsEnabled",
        title = "Blips no Mapa",
        tooltip = "Exibe blips dos alvos no mapa",
        type = "toggle",
        category = "general",
        order = 1,
    }
    function mapBlipsItem.getCurrentValue()
        if not generalConfig then
            return false
        end
        return true == generalConfig.get("mapBlipsEnabled")
    end
    function mapBlipsItem.whenExecute(value)
        SetMapBlipsEnabled(value)
    end

    -- general: spawnBlipsEnabled
    local spawnBlipsItem = {
        stateName = "spawnBlipsEnabled",
        title = "Blips de Spawn",
        tooltip = "Exibe blips das zonas e rotas de spawn no mapa",
        type = "toggle",
        category = "general",
        order = 2,
    }
    function spawnBlipsItem.getCurrentValue()
        if not generalConfig then
            return true
        end
        local current = generalConfig.get("spawnBlipsEnabled")
        if nil == current then
            return true
        end
        return true == current
    end
    function spawnBlipsItem.whenExecute(value)
        SetSpawnBlipsEnabled(value)
    end

    -- parachute: enabled
    local parachuteEnabledItem = {
        stateName = "parachutePedsActive",
        title = "Spawn Habilitado",
        tooltip = "Habilita o spawn de alvos de paraquedas",
        type = "toggle",
        category = "parachute",
        order = 1,
    }
    function parachuteEnabledItem.getCurrentValue()
        if not parachuteConfig then
            return false
        end
        local current = parachuteConfig.get("enabled")
        if not current then
            current = false
        end
        return current
    end
    function parachuteEnabledItem.whenExecute(value)
        if not parachuteConfig then
            return
        end
        parachuteConfig.set("enabled", value)
    end

    -- parachute: maxGeneratePeds
    local parachutePedsItem = {
        stateName = "parachutePeds",
        title = "N\195\186mero de Alvos",
        tooltip = "Ajusta o n\195\186mero m\195\161ximo de alvos que podem ser criados",
        type = "range",
        category = "parachute",
        order = 2,
        min = 1,
        max = 30,
        step = 1,
    }
    function parachutePedsItem.getCurrentValue()
        if not parachuteConfig then
            return 0
        end
        local current = parachuteConfig.get("maxGeneratePeds")
        if not current then
            current = 0
        end
        return current
    end
    function parachutePedsItem.whenExecute(value)
        if not parachuteConfig then
            return
        end
        parachuteConfig.set("maxGeneratePeds", value)
    end

    -- parachute: spawnCooldownMs
    local parachuteIntervalItem = {
        stateName = "parachuteInterval",
        title = "Intervalo de Spawn (segundos)",
        tooltip = "Ajusta o intervalo de spawn dos alvos de paraquedas em segundos",
        type = "range",
        category = "parachute",
        order = 3,
        min = 0.1,
        max = 10,
        step = 0.1,
    }
    function parachuteIntervalItem.getCurrentValue()
        if not parachuteConfig then
            return 0
        end
        local current = parachuteConfig.get("spawnCooldownMs")
        if not current then
            current = 0
        end
        return current / 1000
    end
    function parachuteIntervalItem.whenExecute(value)
        if not parachuteConfig then
            return
        end
        local ms = value * 1000
        parachuteConfig.set("spawnCooldownMs", ms)
    end

    items[1] = mapBlipsItem
    items[2] = spawnBlipsItem
    items[3] = parachuteEnabledItem
    items[4] = parachutePedsItem
    items[5] = parachuteIntervalItem

    if vehicleModeEnabled and vehiclesConfig then
        -- vehicles: vehicleSpawnEnabled
        local idx = #items + 1
        local vehicleSpawnItem = {
            stateName = "vehicleSpawnEnabled",
            title = "Spawn de Ve\195\173culos",
            tooltip = "Habilita ou desabilita o spawn de ve\195\173culos",
            type = "toggle",
            category = "vehicles",
            order = 0,
        }
        function vehicleSpawnItem.getCurrentValue()
            if not vehiclesConfig then
                return true
            end
            local current = vehiclesConfig.get("vehicleSpawnEnabled")
            if nil == current then
                return true
            end
            return true == current
        end
        function vehicleSpawnItem.whenExecute(value)
            if not vehiclesConfig then
                return
            end
            vehiclesConfig.set("vehicleSpawnEnabled", true == value)
            if not value then
                TriggerEvent("multiTracking:vehicle:client:spawnDisabled")
            end
        end
        items[idx] = vehicleSpawnItem

        -- vehicles: maxGenerateVehicles
        idx = #items + 1
        local vehicleMaxItem = {
            stateName = "vehicleMaxVehicles",
            title = "N\195\186mero m\195\161ximo de Ve\195\173culos",
            tooltip = "N\195\186mero m\195\161ximo de ve\195\173culos por rota (limitado tamb\195\169m pelo teto global da rota)",
            type = "range",
            category = "vehicles",
            order = 1,
            min = 1,
            max = 15,
            step = 1,
        }
        function vehicleMaxItem.getCurrentValue()
            if not vehiclesConfig then
                return 6
            end
            local current = vehiclesConfig.get("maxGenerateVehicles")
            if not current then
                current = 6
            end
            return current
        end
        function vehicleMaxItem.whenExecute(value)
            if not vehiclesConfig then
                return
            end
            vehiclesConfig.set("maxGenerateVehicles", value)
        end
        items[idx] = vehicleMaxItem

        -- vehicles: spawnCooldownMs
        idx = #items + 1
        local vehicleIntervalItem = {
            stateName = "vehicleSpawnInterval",
            title = "Intervalo de Spawn (segundos)",
            tooltip = "Intervalo em segundos entre o spawn de cada ve\195\173culo na rota",
            type = "range",
            category = "vehicles",
            order = 2,
            min = 1,
            max = 8,
            step = 1,
        }
        function vehicleIntervalItem.getCurrentValue()
            if not vehiclesConfig then
                return 2
            end
            local current = vehiclesConfig.get("spawnCooldownMs")
            if not current then
                current = 2000
            end
            return current / 1000
        end
        function vehicleIntervalItem.whenExecute(value)
            if not vehiclesConfig then
                return
            end
            vehiclesConfig.set("spawnCooldownMs", value * 1000)
        end
        items[idx] = vehicleIntervalItem

        -- vehicles: driveSpeedMultiplier
        idx = #items + 1
        local vehicleSpeedItem = {
            stateName = "vehicleSpeedMultiplier",
            title = "Multiplicador de Velocidade",
            tooltip = "Ajusta o multiplicador da velocidade dos ve\195\173culos",
            type = "range",
            category = "vehicles",
            order = 3,
            min = 0.1,
            max = 3.0,
            step = 0.1,
        }
        function vehicleSpeedItem.getCurrentValue()
            if not vehiclesConfig then
                return 0
            end
            local current = vehiclesConfig.get("driveSpeedMultiplier")
            if not current then
                current = 0
            end
            return current
        end
        function vehicleSpeedItem.whenExecute(value)
            if not vehiclesConfig then
                return
            end
            vehiclesConfig.set("driveSpeedMultiplier", value)
            TriggerEvent("multiTracking:vehicle:client:refreshPlaybackSpeed")
        end
        items[idx] = vehicleSpeedItem
    end

    local extraItems = {}

    -- runner: spawnCooldownMs
    local runnerIntervalItem = {
        stateName = "runnerInterval",
        title = "Intervalo de Spawn (segundos)",
        tooltip = "Ajusta o intervalo de spawn dos alvos de corrida em segundos",
        type = "range",
        category = "runner",
        order = 1,
        min = 0.1,
        max = 10,
        step = 0.1,
    }
    function runnerIntervalItem.getCurrentValue()
        if not runnerConfig then
            return 0
        end
        local current = runnerConfig.get("spawnCooldownMs")
        if not current then
            current = 0
        end
        return current / 1000
    end
    function runnerIntervalItem.whenExecute(value)
        if not runnerConfig then
            return
        end
        local ms = value * 1000
        runnerConfig.set("spawnCooldownMs", ms)
    end

    -- runner: maxGeneratePeds
    local runnerMaxItem = {
        stateName = "runnerMaxGeneratePeds",
        title = "M\195\161ximo de Alvos",
        tooltip = "Ajusta o m\195\161ximo de alvos de corrida que podem ser criados",
        type = "range",
        category = "runner",
        order = 2,
        min = 1,
        max = 20,
        step = 1,
    }
    function runnerMaxItem.getCurrentValue()
        if not runnerConfig then
            return 0
        end
        local current = runnerConfig.get("maxGeneratePeds")
        if not current then
            current = 0
        end
        return current
    end
    function runnerMaxItem.whenExecute(value)
        if not runnerConfig then
            return
        end
        runnerConfig.set("maxGeneratePeds", value)
    end

    -- runner: runSpeed
    local runnerSpeedItem = {
        stateName = "runnerRunSpeed",
        title = "Velocidade de Corrida",
        tooltip = "Ajusta a velocidade de corrida dos alvos",
        type = "range",
        category = "runner",
        order = 3,
        min = 0.1,
        max = 20,
        step = 0.1,
    }
    function runnerSpeedItem.getCurrentValue()
        if not runnerConfig then
            return 0
        end
        local current = runnerConfig.get("runSpeed")
        if not current then
            current = 0
        end
        return current
    end
    function runnerSpeedItem.whenExecute(value)
        if not runnerConfig then
            return
        end
        runnerConfig.set("runSpeed", value)
    end

    -- runner: aimRollEnabled
    local runnerAimRollItem = {
        stateName = "runnerAimRollEnabled",
        title = "Rolamento ao Mirar",
        tooltip = "Executa um rolamento ao iniciar mira",
        type = "toggle",
        category = "runner",
        order = 4,
    }
    function runnerAimRollItem.getCurrentValue()
        if not runnerConfig then
            return false
        end
        local current = runnerConfig.get("aimRollEnabled")
        if not current then
            current = false
        end
        return current
    end
    function runnerAimRollItem.whenExecute(value)
        if not runnerConfig then
            return
        end
        runnerConfig.set("aimRollEnabled", value)
    end

    -- roll: spawnCooldownMs
    local rollIntervalItem = {
        stateName = "rollInterval",
        title = "Intervalo de Spawn (segundos)",
        tooltip = "Ajusta o intervalo de spawn dos alvos de rolamento em segundos",
        type = "range",
        category = "roll",
        order = 1,
        min = 0.1,
        max = 10,
        step = 0.1,
    }
    function rollIntervalItem.getCurrentValue()
        if not rollConfig then
            return 0
        end
        local current = rollConfig.get("spawnCooldownMs")
        if not current then
            current = 0
        end
        return current / 1000
    end
    function rollIntervalItem.whenExecute(value)
        if not rollConfig then
            return
        end
        local ms = value * 1000
        rollConfig.set("spawnCooldownMs", ms)
    end

    -- roll: maxGeneratePeds
    local rollMaxItem = {
        stateName = "rollMaxGeneratePeds",
        title = "M\195\161ximo de Alvos",
        tooltip = "Ajusta o m\195\161ximo de alvos que podem ser criados",
        type = "range",
        category = "roll",
        order = 2,
        min = 1,
        max = 10,
        step = 1,
    }
    function rollMaxItem.getCurrentValue()
        if not rollConfig then
            return 0
        end
        local current = rollConfig.get("maxGeneratePeds")
        if not current then
            current = 0
        end
        return current
    end
    function rollMaxItem.whenExecute(value)
        if not rollConfig then
            return
        end
        rollConfig.set("maxGeneratePeds", value)
    end

    -- roll: rollDeleteDelayMs
    local rollDeleteDelayItem = {
        stateName = "rollDeleteDelay",
        title = "Delay para Remover Alvo (segundos)",
        tooltip = "Ajusta o tempo para remover o alvo ap\195\179s terminar o rolamento",
        type = "range",
        category = "roll",
        order = 3,
        min = 0.7,
        max = 1.5,
        step = 0.1,
    }
    function rollDeleteDelayItem.getCurrentValue()
        if not rollConfig then
            return 0
        end
        local current = rollConfig.get("rollDeleteDelayMs")
        if not current then
            current = 0
        end
        return current / 1000
    end
    function rollDeleteDelayItem.whenExecute(value)
        if not rollConfig then
            return
        end
        local ms = value * 1000
        rollConfig.set("rollDeleteDelayMs", ms)
    end

    -- area: spawnCooldownMs
    local areaIntervalItem = {
        stateName = "areaInterval",
        title = "Intervalo de Spawn (segundos)",
        tooltip = "Ajusta o intervalo de spawn dos alvos da area em segundos",
        type = "range",
        category = "area",
        order = 1,
        min = 0.1,
        max = 10,
        step = 0.1,
    }
    function areaIntervalItem.getCurrentValue()
        if not areaConfig then
            return 0
        end
        local current = areaConfig.get("spawnCooldownMs")
        if not current then
            current = 0
        end
        return current / 1000
    end
    function areaIntervalItem.whenExecute(value)
        if not areaConfig then
            return
        end
        local ms = value * 1000
        areaConfig.set("spawnCooldownMs", ms)
    end

    -- area: maxGeneratePeds
    local areaMaxItem = {
        stateName = "areaMaxGeneratePeds",
        title = "M\195\161ximo de Alvos",
        tooltip = "Ajusta o m\195\161ximo de alvos que podem ser criados",
        type = "range",
        category = "area",
        order = 2,
        min = 1,
        max = 10,
        step = 1,
    }
    function areaMaxItem.getCurrentValue()
        if not areaConfig then
            return 0
        end
        local current = areaConfig.get("maxGeneratePeds")
        if not current then
            current = 0
        end
        return current
    end
    function areaMaxItem.whenExecute(value)
        if not areaConfig then
            return
        end
        areaConfig.set("maxGeneratePeds", value)
    end

    -- area: pedLifetimeMs
    local areaDeleteDelayItem = {
        stateName = "areaDeleteDelay",
        title = "Delay para Remover Alvo (segundos)",
        tooltip = "Ajusta o tempo para remover o alvo da area",
        type = "range",
        category = "area",
        order = 3,
        min = 0.1,
        max = 30,
        step = 0.1,
    }
    function areaDeleteDelayItem.getCurrentValue()
        if not areaConfig then
            return 0
        end
        local current = areaConfig.get("pedLifetimeMs")
        if not current then
            current = 0
        end
        return current / 1000
    end
    function areaDeleteDelayItem.whenExecute(value)
        if not areaConfig then
            return
        end
        local ms = value * 1000
        areaConfig.set("pedLifetimeMs", ms)
    end

    extraItems[1] = runnerIntervalItem
    extraItems[2] = runnerMaxItem
    extraItems[3] = runnerSpeedItem
    extraItems[4] = runnerAimRollItem
    extraItems[5] = rollIntervalItem
    extraItems[6] = rollMaxItem
    extraItems[7] = rollDeleteDelayItem
    extraItems[8] = areaIntervalItem
    extraItems[9] = areaMaxItem
    extraItems[10] = areaDeleteDelayItem

    for _, item in ipairs(extraItems) do
        items[#items + 1] = item
    end

    if vehicleModeEnabled and vehiclesConfig then
        vehiclesConfig.addConstraint("driveSpeedMultiplier", 0.1, 30.0)
        vehiclesConfig.addConstraint("maxGenerateVehicles", 1, 40)
        vehiclesConfig.addConstraint("spawnCooldownMs", 50, 10000)
    end

    if parachuteConfig then
        parachuteConfig.addConstraint("maxGeneratePeds", 1, 30)
        parachuteConfig.addConstraint("spawnCooldownMs", 100, 30000)
    end

    if runnerConfig then
        runnerConfig.addConstraint("maxGeneratePeds", 1, 20)
        runnerConfig.addConstraint("spawnCooldownMs", 100, 30000)
        runnerConfig.addConstraint("runSpeed", 0.1, 20)
    end

    if rollConfig then
        rollConfig.addConstraint("maxGeneratePeds", 1, 10)
        rollConfig.addConstraint("spawnCooldownMs", 100, 30000)
        rollConfig.addConstraint("rollDeleteDelayMs", 700, 1500)
    end

    if areaConfig then
        areaConfig.addConstraint("maxGeneratePeds", 1, 10)
        areaConfig.addConstraint("spawnCooldownMs", 100, 30000)
        areaConfig.addConstraint("pedLifetimeMs", 100, 30000)
    end

    AppendDifficultyItem(items, parachuteConfig, "parachute", "parachuteDifficultyLevel")
    if vehicleModeEnabled then
        AppendDifficultyItem(items, vehiclesConfig, "vehicles", "vehiclesDifficultyLevel")
    end
    AppendDifficultyItem(items, runnerConfig, "runner", "runnerDifficultyLevel")
    AppendDifficultyItem(items, rollConfig, "roll", "rollDifficultyLevel")
    AppendDifficultyItem(items, areaConfig, "area", "areaDifficultyLevel")

    local categories = {}
    categories.general = { label = "Geral", order = 0 }
    categories.parachute = { label = "Paraquedas", order = 1 }
    categories.runner = { label = "Corrida", order = 3 }
    categories.roll = { label = "Rolamento", order = 4 }
    categories.area = { label = "Spawn", order = 5 }
    if vehicleModeEnabled then
        categories.vehicles = { label = "Ve\195\173culos", order = 2 }
    end

    exports.settings:registerCustomPanel("multiTracking", {
        title = "Configuracao do tracking",
        categories = categories,
        defaultCategory = "tracking",
        items = items,
    })
end

RegisterCommand("openSettingsPanel", function()
    OpenMultiTrackingSettingsPanel(true)
end, false)

AddEventHandler("settings:whenDennyEnabledOpen", function()
    OpenMultiTrackingSettingsPanel(true)
end)

Citizen.CreateThread(function()
    RegisterSettingsPanel()
end)

AddEventHandler("onResourceStart", function(resourceName)
    if "settings" ~= resourceName then
        return
    end
    Wait(1000)
    RegisterSettingsPanel()
end)

AddConvarChangeListener("multiTrackingVehicleModeEnabled", function()
    vehicleModeEnabled = GetConvarBool("multiTrackingVehicleModeEnabled", true)
    RegisterSettingsPanel()
end)
