--[[
    Configurações de roupas (drawables, props e characteristics) por
    servidor (KINGG/NEXT) e por modelo de ped (masculino/feminino).
    Expoe GetMultiTrackingClothesByPedModel para consulta por hash/nome.
]]

local serverIdentifier = GetConvar("serverIdentifier", "KINGG")

local emptyProps11 = {
    [0]  = { texture = -1, collectionName = "null", localDrawableId = -1 },
    [1]  = { texture = -1, collectionName = "null", localDrawableId = -1 },
    [2]  = { texture = -1, collectionName = "null", localDrawableId = -1 },
    [3]  = { texture = -1, collectionName = "null", localDrawableId = -1 },
    [4]  = { texture = -1, collectionName = "null", localDrawableId = -1 },
    [5]  = { texture = -1, collectionName = "null", localDrawableId = -1 },
    [6]  = { texture = -1, collectionName = "null", localDrawableId = -1 },
    [7]  = { texture = -1, collectionName = "null", localDrawableId = -1 },
    [8]  = { texture = -1, collectionName = "null", localDrawableId = -1 },
    [9]  = { texture = -1, collectionName = "null", localDrawableId = -1 },
    [10] = { texture = -1, collectionName = "null", localDrawableId = -1 },
}

local function zeroCharacteristics()
    local t = {}
    for i = 1, 48 do
        t[i] = 0
    end
    return t
end

local function buildProps11()
    local t = {}
    for k, v in pairs(emptyProps11) do
        t[k] = { texture = v.texture, collectionName = v.collectionName, localDrawableId = v.localDrawableId }
    end
    return t
end

local clothesData = {
    KINGG = {
        [1885233650] = {
            clothes = {
                drawables = {
                    [3]  = { texture = 0, collectionName = "default", localDrawableId = 13 },
                    [4]  = { texture = 0, collectionName = "mp_m_proleagueplayers", localDrawableId = 45 },
                    [6]  = { texture = 0, collectionName = "Male_Apt01", localDrawableId = 0 },
                    [11] = { texture = 0, collectionName = "mp_m_proleagueplayers", localDrawableId = 66 },
                    [8]  = { texture = 0, collectionName = "default", localDrawableId = 15 },
                    [1]  = { texture = 0, collectionName = "mp_m_proleagueplayers", localDrawableId = 20 },
                },
                props = buildProps11(),
            },
            characteristics = zeroCharacteristics(),
        },
        [-1667301416] = {
            clothes = {
                drawables = {
                    [3]  = { texture = 0, collectionName = "default", localDrawableId = 13 },
                    [4]  = { texture = 0, collectionName = "mp_f_proleagueplayers", localDrawableId = 57 },
                    [11] = { texture = 0, collectionName = "mp_f_proleagueplayers", localDrawableId = 78 },
                    [6]  = { texture = 0, collectionName = "Female_Apt01", localDrawableId = 0 },
                    [7]  = { texture = 0, collectionName = "default", localDrawableId = 8 },
                    [8]  = { texture = 0, collectionName = "default", localDrawableId = 3 },
                    [1]  = { texture = 0, collectionName = "mp_f_proleagueplayers", localDrawableId = 17 },
                },
                props = buildProps11(),
            },
            characteristics = zeroCharacteristics(),
        },
    },
    NEXT = {
        [1885233650] = {
            clothes = {
                drawables = {
                    [3]  = { texture = 0, collectionName = "default", localDrawableId = 13 },
                    [8]  = { texture = 0, collectionName = "default", localDrawableId = 15 },
                    [11] = { texture = 0, collectionName = "mp_m_nextpvp", localDrawableId = 9 },
                    [6]  = { texture = 0, collectionName = "Male_Apt01", localDrawableId = 0 },
                    [4]  = { texture = 0, collectionName = "mp_m_nextpvp", localDrawableId = 5 },
                    [1]  = { texture = 0, collectionName = "mp_m_nextpvp", localDrawableId = 0 },
                },
                props = buildProps11(),
            },
            characteristics = zeroCharacteristics(),
        },
        [-1667301416] = {
            clothes = {
                drawables = {
                    ["2"]  = { texture = 0, localDrawableId = 2,  collectionName = "mp_f_bikerdlc_01" },
                    ["3"]  = { texture = 0, localDrawableId = 13, collectionName = "default" },
                    ["8"]  = { texture = 0, localDrawableId = 2,  collectionName = "default" },
                    ["11"] = { texture = 0, localDrawableId = 9,  collectionName = "mp_f_nextpvp" },
                    ["6"]  = { texture = 0, localDrawableId = 0,  collectionName = "Female_Apt01" },
                    ["4"]  = { texture = 0, localDrawableId = 6,  collectionName = "mp_f_nextpvp" },
                    ["1"]  = { texture = 0, localDrawableId = 2,  collectionName = "mp_f_nextpvp" },
                },
                props = buildProps11(),
            },
            characteristics = zeroCharacteristics(),
        },
    },
}

local activeServerClothes = clothesData[serverIdentifier] or {}

local function GetMultiTrackingClothesByPedModel(pedModel)
    if not activeServerClothes then
        return nil
    end
    if not pedModel then
        return nil
    end

    local key
    if type(pedModel) == "string" then
        key = GetHashKey(pedModel)
    end
    if not key then
        key = pedModel
    end

    return activeServerClothes[key]
end

_G.GetMultiTrackingClothesByPedModel = GetMultiTrackingClothesByPedModel
