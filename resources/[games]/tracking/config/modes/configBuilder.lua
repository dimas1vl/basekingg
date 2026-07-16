--[[
    Construtor de configuração persistente do MultiTracking.
    Cada gameModeIndex (general/vehicles/parachute/runner/roll/area) ganha
    um builder com get/set/addConstraint/applyDifficultyLevel etc.
    Os valores escolhidos são persistidos via KVP do recurso.
]]

local serverIdentifier = GetConvar("serverIdentifier", "KINGG")
local kvpKey = string.format("%s:multitracking:config", serverIdentifier)

local function loadPersistedConfig()
    local ok, result = pcall(function()
        local raw = GetResourceKvpString(kvpKey)
        if not raw then
            return {}
        end
        return json.decode(raw)
    end)
    if not ok then
        return {}
    end
    if type(result) ~= "table" or not result then
        return {}
    end
    return result
end

local persistedConfig = loadPersistedConfig()

local function createConfigBuilder(gameModeIndex, defaultSettings, noCustomSettings, levelsDifficulty)
    local builder = {}
    local SELECTED_LEVEL_KEY = "__selectedLevelDifficulty"
    local constraints = {}

    local state = {
        gameModeIndex = gameModeIndex,
        customSettings = {},
        selectedLevelDifficulty = 1,
        isApplyingDifficulty = false,
        noCustomSettings = (type(noCustomSettings) == "table" and noCustomSettings) or {},
        defaultSettings = (type(defaultSettings) == "table" and defaultSettings) or {},
        levelsDifficulty = (type(levelsDifficulty) == "table" and levelsDifficulty) or {},
    }

    local function extractValueLabel(entry)
        if type(entry) == "table" and entry.value ~= nil then
            return entry.value, entry.label
        end
        return entry, nil
    end

    local function applyConstraint(key, value)
        local c = constraints[key]
        if not c or type(value) ~= "number" then
            return value
        end
        return math.max(c.min, math.min(c.max, value))
    end

    local function persist()
        local snapshot = {}
        for k, v in pairs(state.customSettings) do
            snapshot[k] = v
        end
        snapshot[SELECTED_LEVEL_KEY] = state.selectedLevelDifficulty
        persistedConfig[state.gameModeIndex] = snapshot
        SetResourceKvp(kvpKey, json.encode(persistedConfig))
    end

    function builder.get(key)
        local fromNoCustom = state.noCustomSettings
        if fromNoCustom then
            local value = fromNoCustom[key]
            if value ~= nil then
                return value
            end
        end

        if state.customSettings[key] ~= nil then
            local raw = state.customSettings[key]
            local value = extractValueLabel(raw)
            return applyConstraint(key, value)
        end

        local raw = state.defaultSettings[key]
        local value = extractValueLabel(raw)
        return value
    end

    function builder.addConstraint(key, min, max)
        constraints[key] = { min = min, max = max }
    end

    function builder.set(key, value)
        if state.noCustomSettings then
            if state.noCustomSettings[key] ~= nil then
                return
            end
        end

        local _, defaultLabel = extractValueLabel(state.defaultSettings[key])

        if type(value) == "table" and value.value ~= nil then
            state.customSettings[key] = value
        else
            state.customSettings[key] = { value = value, label = defaultLabel }
        end

        if not state.isApplyingDifficulty then
            local wasAlreadyCustom = (state.selectedLevelDifficulty == -1)
            state.selectedLevelDifficulty = -1
            if not wasAlreadyCustom then
                TriggerEvent("multiTracking:client:difficultyApplied", state.gameModeIndex, -1)
            end
        end

        persist()
    end

    function builder.getSettingsLevelDifficulty()
        local levels = state.levelsDifficulty
        if type(levels) ~= "table" then
            return {}
        end
        return levels
    end

    function builder.getSelectedLevelDifficulty()
        return state.selectedLevelDifficulty
    end

    function builder.markCustomDifficulty()
        state.selectedLevelDifficulty = -1
        persist()
    end

    function builder.applyDifficultyLevel(levelIndex)
        local levels = state.levelsDifficulty
        if type(levels) ~= "table" then
            return
        end
        if type(levelIndex) ~= "number" then
            return
        end
        if levelIndex < 1 then
            return
        end
        if levelIndex > #levels then
            return
        end
        local levelSettings = levels[levelIndex]
        if type(levelSettings) ~= "table" then
            return
        end

        state.isApplyingDifficulty = true
        for k, v in pairs(levelSettings) do
            builder.set(k, v)
        end
        state.isApplyingDifficulty = false

        state.selectedLevelDifficulty = levelIndex
        persist()

        TriggerEvent("multiTracking:client:difficultyApplied", state.gameModeIndex, levelIndex)
    end

    -- Aplica o estado persistido ao novo builder
    if type(persistedConfig) == "table" then
        local saved = persistedConfig[state.gameModeIndex]
        if type(saved) == "table" then
            local savedLevel = tonumber(saved[SELECTED_LEVEL_KEY])
            if savedLevel then
                state.selectedLevelDifficulty = savedLevel
            end
            state.isApplyingDifficulty = true
            for k, v in pairs(saved) do
                if k ~= SELECTED_LEVEL_KEY then
                    builder.set(k, v)
                end
            end
            state.isApplyingDifficulty = false
        end
    end

    return builder
end

-- ============================================================
-- Definições de defaults por categoria
-- ============================================================

local vehiclesCategory = {
    defaultSettings = {
        vehicleSpawnEnabled = true,
        maxGenerateVehicles = 5,
        spawnCooldownMs = 1000, -- 1s entre spawns (slider F7 override)
        autoDeleteTimeoutMs = 90000,
        driveSpeedMultiplier = 1.0,
    },
    noCustomSettings = {
        arriveDistance = 20.0,
        driveSpeed = 20.0,
        driveSpeedStep = 20.0,
        driveSpeedMin = 10.0,
        driveSpeedMax = 180.0,
        launchSpeedMax = 12.0,
        drivingStyle = 786603,
    },
    levelsDifficulty = {
        {
            maxGenerateVehicles = 6,
            spawnCooldownMs = 2000,
            autoDeleteTimeoutMs = 90000,
            driveSpeedMultiplier = 1.0,
        },
        {
            maxGenerateVehicles = 6,
            spawnCooldownMs = 1200,
            autoDeleteTimeoutMs = 130000,
            driveSpeedMultiplier = 1.8,
        },
    },
}

local parachuteCategory = {
    defaultSettings = {
        enabled = false,
        maxGeneratePeds = 6,
        spawnCooldownMs = 2000,
    },
    levelsDifficulty = {
        {
            enabled = true,
            maxGeneratePeds = 6,
            spawnCooldownMs = 2000,
        },
        {
            enabled = true,
            maxGeneratePeds = 6,
            spawnCooldownMs = 1000,
        },
    },
}

local runnerCategory = {
    defaultSettings = {
        maxGeneratePeds = 4,
        spawnCooldownMs = 1500,
        runSpeed = 3.0,
    },
    noCustomSettings = {
        runDistance = 120.0,
    },
    levelsDifficulty = {
        {
            maxGeneratePeds = 4,
            spawnCooldownMs = 1500,
            runSpeed = 3.0,
        },
        {
            maxGeneratePeds = 4,
            spawnCooldownMs = 800,
            runSpeed = 6.0,
        },
    },
}

local rollCategory = {
    defaultSettings = {
        maxGeneratePeds = 6,
        spawnCooldownMs = 1500,
        rollDeleteDelayMs = 1500,
    },
    levelsDifficulty = {
        {
            maxGeneratePeds = 6,
            spawnCooldownMs = 1500,
            rollDeleteDelayMs = 1500,
        },
        {
            maxGeneratePeds = 6,
            spawnCooldownMs = 800,
            rollDeleteDelayMs = 900,
        },
    },
}

local areaCategory = {
    defaultSettings = {
        maxGeneratePeds = 6,
        spawnCooldownMs = 1500,
        pedLifetimeMs = 12000,
    },
    levelsDifficulty = {
        {
            maxGeneratePeds = 6,
            spawnCooldownMs = 1500,
            pedLifetimeMs = 12000,
        },
        {
            maxGeneratePeds = 6,
            spawnCooldownMs = 800,
            pedLifetimeMs = 7000,
        },
    },
}

local generalCategory = {
    defaultSettings = {
        mapBlipsEnabled = false,
        spawnBlipsEnabled = true,
        hitmarkerEnabled = true,
    },
}

local weatherCategory = {
    defaultSettings = {
        overrideHour    = false,
        hour            = 12,
        overrideWeather = false,
        weather         = 'EXTRASUNNY',
    },
}

local builders = {}
builders.general   = createConfigBuilder("general",   generalCategory.defaultSettings)
builders.weather   = createConfigBuilder("weather",   weatherCategory.defaultSettings)
builders.vehicles  = createConfigBuilder("vehicles",  vehiclesCategory.defaultSettings,  vehiclesCategory.noCustomSettings, vehiclesCategory.levelsDifficulty)
builders.parachute = createConfigBuilder("parachute", parachuteCategory.defaultSettings, nil,                                parachuteCategory.levelsDifficulty)
builders.runner    = createConfigBuilder("runner",    runnerCategory.defaultSettings,    runnerCategory.noCustomSettings,    runnerCategory.levelsDifficulty)
builders.roll      = createConfigBuilder("roll",      rollCategory.defaultSettings,      nil,                                rollCategory.levelsDifficulty)
builders.area      = createConfigBuilder("area",      areaCategory.defaultSettings,      nil,                                areaCategory.levelsDifficulty)

local function GetGlobalConfigBuilder(category)
    if type(category) ~= "string" then
        return nil
    end
    local builder = builders and builders[category]
    if type(builder) ~= "table" then
        return nil
    end
    return builder
end

_G.GetGlobalConfigBuilder = GetGlobalConfigBuilder
