--[[ Criacao e configuracao de peds de tracking: carrega modelo, spawna,
     aplica flags padrao, roupas/aparencia e tocas animacao de roll. ]]

local createdPeds = {}

local function LoadPedModel(model)
    local attempts = 0
    local hashedModel = model
    if type(model) == "string" then
        hashedModel = GetHashKey(model) or model
    end

    if HasModelLoaded(hashedModel) then
        return true
    end

    RequestModel(model)
    while not HasModelLoaded(hashedModel) and attempts < 100 do
        attempts = attempts + 1
        Wait(50)
    end

    if not HasModelLoaded(hashedModel) then
        print(('^3[tracking] LoadPedModel failed: %s (hash=%s)^7'):format(tostring(model), tostring(hashedModel)))
        return false
    end

    return true
end

local function PreloadAllTrackingPedModels()
    local models = MultitrackingValidPedModels or {}
    for model in pairs(models) do
        CreateThread(function()
            if not LoadPedModel(model) then
                print(('^3[tracking] preload skipped model %s^7'):format(tostring(model)))
            end
        end)
    end
end
_G.PreloadAllTrackingPedModels = PreloadAllTrackingPedModels

local function SpawnPedAtCoords(model, coords)
    local ped = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, 0.0, false, false)

    local attempts = 0
    while not DoesEntityExist(ped) and attempts < 30 do
        attempts = attempts + 1
        Wait(100)
    end

    if ped and DoesEntityExist(ped) then
        return ped
    end
    return nil
end

local function ApplyPedConfiguration(ped, options)
    options = options or {}

    local maxHealth = tonumber(options.maxHealth) or 150
    local canRagdoll = options.canRagdoll == true
    local keepTask = options.keepTask ~= false
    local registerExtraDamage = options.registerExtraDamage ~= false
    local setupAppearance = options.setupAppearance ~= false
    local setupUnarmed = options.setupUnarmed ~= false

    SetEntityMaxHealth(ped, maxHealth)
    SetPedMaxHealth(ped, maxHealth)
    SetEntityHealth(ped, maxHealth)
    SetPedConfigFlag(ped, 363, true)
    SetPedConfigFlag(ped, 2, false)
    SetPedSuffersCriticalHits(ped, true)
    SetPedCanRagdoll(ped, canRagdoll)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetEntityNoCollisionEntity(ped, PlayerPedId(), false)
    SetEntityVisible(ped, false, false)

    if keepTask then
        SetPedKeepTask(ped, true)
    end

    if setupUnarmed then
        RemoveAllPedWeapons(ped, true)
        SetCurrentPedWeapon(ped, -1569615261, true)
    end

    if setupAppearance then
        SetPedDefaultComponentVariation(ped)
        -- Roupas/cabelos opcionais (clotheshop/barbershop podem não estar presentes)
        local clothesData = GetMultiTrackingClothesByPedModel(GetEntityModel(ped))
        if GetResourceState('clotheshop') == 'started' then
            pcall(function() exports.clotheshop:changeClothesToPed(ped, clothesData and clothesData.clothes) end)
        end
        if GetResourceState('barbershop') == 'started' then
            pcall(function() exports.barbershop:changeCharacteristicsToPed(ped, clothesData and clothesData.characteristics) end)
        end
    end

    if registerExtraDamage then
        TriggerEvent("hitDamage:registerExtraEntity", ped)
    end

    SetEntityVisible(ped, true, true)
end

local function ApplyTrackingPedFlags(ped)
    SetEntityAsMissionEntity(ped, true, false)
    SetPedAsCop(ped, false)

    SetEntityMaxHealth(ped, 150)
    SetEntityHealth(ped, 150)
    SetPedSuffersCriticalHits(ped, true)
    SetPedDiesInstantlyInWater(ped, true)
    SetEntityProofs(ped, false, false, false, true, false, false, false, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)

    RemoveAllPedWeapons(ped, true)
    GiveWeaponToPed(ped, -72657034, 1, false, true)
    SetPedConfigFlag(ped, 446, false)
    SetPedConfigFlag(ped, 441, true)
    SetPedConfigFlag(ped, 410, true)
    SetPedConfigFlag(ped, 17, true)
    SetPedConfigFlag(ped, 14, true)
    SetPedConfigFlag(ped, 48, true)
    SetPedConfigFlag(ped, 416, true)
    SetPedConfigFlag(ped, 23, false)
    SetPedConfigFlag(ped, 319, false)
    SetPedConfigFlag(ped, 134, false)
    SetPedConfigFlag(ped, 212, false)
    SetPedConfigFlag(ped, 213, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    DisablePedPainAudio(ped, true)

    MultiTrackingApplyDefaultPedFlags(ped, {
        setupAppearance = true,
        registerExtraDamage = false,
        keepTask = false,
        setupUnarmed = false,
    })
end

local function GetValidPedModelList()
    local list = {}
    local models = MultitrackingValidPedModels or {}
    for modelName, _ in pairs(models) do
        table.insert(list, modelName)
    end
    return list
end

local function CreateMultiTrackingPed(coords)
    math.randomseed(GetGameTimer())

    local models = GetValidPedModelList()
    if #models == 0 then
        return nil
    end

    local chosenModel = models[math.random(1, #models)]
    if not (chosenModel and LoadPedModel(chosenModel)) then
        print("^3 multi_tracking:CreateMultiTrackingPed - failed to load model^0", chosenModel)
        return nil
    end

    local ped = SpawnPedAtCoords(chosenModel, coords)
    if not ped then
        print("^3 multi_tracking:CreateMultiTrackingPed - failed to create ped^0")
        return nil
    end

    ApplyTrackingPedFlags(ped)
    createdPeds[ped] = true
    return ped
end
_G.CreateMultiTrackingPed = CreateMultiTrackingPed

local function HasValidTrackingPedModel(model)
    if not model or model == 0 then
        return
    end
    local validModels = MultitrackingValidPedModels or {}
    return validModels[model] and true or false
end
_G.HasValidTrackingPedModel = HasValidTrackingPedModel

local function MultiTrackingApplyDefaultPedFlags(ped, options)
    if not (ped and DoesEntityExist(ped)) then
        return
    end
    ApplyPedConfiguration(ped, options)
end
_G.MultiTrackingApplyDefaultPedFlags = MultiTrackingApplyDefaultPedFlags

local function GetAnimationDictsWithClips(animations)
    local dictsWithClips = {}
    for dictName, clips in pairs(animations) do
        if type(dictName) == "string" and type(clips) == "table" and #clips > 0 then
            dictsWithClips[#dictsWithClips + 1] = dictName
        end
    end
    return dictsWithClips
end

local function PickRandomRollAnimation(modeConfig)
    local animations = (modeConfig and modeConfig.animations) or MultitrackingModeRollAnimations or {}

    local dicts = GetAnimationDictsWithClips(animations)
    if #dicts == 0 then
        return nil, nil
    end

    math.randomseed(GetGameTimer())
    local dict = dicts[math.random(1, #dicts)]
    local clips = animations[dict]

    if not (clips and #clips ~= 0) then
        return nil, nil
    end

    local clip = clips[math.random(1, #clips)]
    return dict, clip
end

local function PlayRollAnimation(ped, modeConfig, duration)
    if not (ped and DoesEntityExist(ped)) then
        return false
    end

    local dict, clip = PickRandomRollAnimation(modeConfig)
    if not dict or not clip then
        print("^3 multi_tracking:PlayRollAnimation - nil dict or clip^0")
        return false
    end

    RequestAnimDict(dict)
    local attempts = 0
    while not HasAnimDictLoaded(dict) and attempts < 30 do
        attempts = attempts + 1
        Wait(10)
    end

    if not HasAnimDictLoaded(dict) then
        return false
    end

    local animDuration = duration or 1200
    TaskPlayAnim(ped, dict, clip, 8.0, -8.0, animDuration, 0, 0.0, false, false, false)
    return true
end
_G.PlayRollAnimation = PlayRollAnimation
