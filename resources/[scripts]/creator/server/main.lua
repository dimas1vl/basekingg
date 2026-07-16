while not Core do
    Wait(100)
end

local API = {}

---@class Creator
Creator = {}

---@param src number
---@return boolean
function Creator.isRegistered(src)
    local info = Core.getUserInfo(src)
    return info ~= nil and info.gender ~= nil and info.appearance ~= nil
end

---@param gender 'male' | 'female'
---@return table | nil
function Creator.buildDefaultAppearance(gender)
    local preset = Config.defaultPeds[gender]
    if not preset then return nil end

    local clothes = {}
    for k, v in pairs(preset.clothes) do
        clothes[k] = v
    end
    clothes.modelhash = gender == 'male' and `mp_m_freemode_01` or `mp_f_freemode_01`

    return {
        character = preset.apparence or {},
        clothes = clothes,
        tattoos = {},
    }
end

---@param name string
---@param userId number?
---@return boolean
function Creator.isNameAvailable(name, userId)
    if type(name) ~= 'string' then return false end
    local q = 'SELECT `id` FROM `users` WHERE LOWER(`name`) = LOWER(?)'
    local params = { name }
    if userId then
        q = q .. ' AND `id` != ?'
        params[#params + 1] = userId
    end
    return exports['oxmysql']:singleSync(q, params) == nil
end

---@param name string
---@return boolean, string?
function Creator.validateName(name)
    if type(name) ~= 'string' then return false, 'name_invalid' end
    if #name < 3 or #name > 20 then return false, 'name_invalid' end
    if not name:match('^[%w_-]+$') then return false, 'name_invalid' end
    return true
end

---@param day number
---@param month number
---@param year number
---@return boolean
local function isValidDate(day, month, year)
    if day < 1 or day > 31 or month < 1 or month > 12 then return false end
    if year < 1900 or year > 2020 then return false end
    local daysPerMonth = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    if month == 2 and ((year % 4 == 0 and year % 100 ~= 0) or year % 400 == 0) then
        daysPerMonth[2] = 29
    end
    return day <= daysPerMonth[month]
end

---@param birthdate table { day, month, year }
---@return boolean, string?, string?
function Creator.validateBirthdate(birthdate)
    if type(birthdate) ~= 'table' then return false, 'birthdate_invalid' end
    local day = tonumber(birthdate.day)
    local month = tonumber(birthdate.month)
    local year = tonumber(birthdate.year)
    if not day or not month or not year then return false, 'birthdate_invalid' end
    if not isValidDate(day, month, year) then return false, 'birthdate_invalid' end
    return true, nil, ('%04d-%02d-%02d'):format(year, month, day)
end

---@param src number
---@param name string
---@param gender 'male' | 'female'
---@param birthdate table
---@return boolean, string?
function Creator.register(src, name, gender, birthdate)
    local userId = Core.getUserId(src)
    if not userId then return false, 'user_not_found' end

    if Creator.isRegistered(src) then
        return false, 'already_registered'
    end

    local nameOk, nameErr = Creator.validateName(name)
    if not nameOk then return false, nameErr end

    if gender ~= 'male' and gender ~= 'female' then
        return false, 'gender_invalid'
    end

    local dateOk, dateErr, isoDate = Creator.validateBirthdate(birthdate)
    if not dateOk then return false, dateErr end

    if not Creator.isNameAvailable(name, userId) then
        return false, 'name_taken'
    end

    local appearance = Creator.buildDefaultAppearance(gender)
    if not appearance then return false, 'gender_invalid' end

    exports['oxmysql']:updateSync(
        'UPDATE `users` SET `name` = ?, `gender` = ?, `birthdate` = ?, `appearance` = ? WHERE `id` = ?',
        { name, gender, isoDate, json.encode(appearance), userId }
    )

    Core.updateUserInfo(userId, {
        name = name,
        gender = gender,
        birthdate = isoDate,
        appearance = appearance,
    })

    print(('[creator] User %s registered as %s (%s, %s)'):format(userId, name, gender, isoDate))
    return true
end

---@return 'register' | 'lobby' | 'error'
function API.boot()
    local src = source
    if not Core.getUserId(src) then return 'error' end
    if Creator.isRegistered(src) then
        TriggerClientEvent('lobby:displayLobby', src)
        return 'lobby'
    end
    return 'register'
end

---@param name string
---@return boolean
function API.checkName(name)
    local userId = Core.getUserId(source)
    return Creator.isNameAvailable(name, userId)
end

---@param payload table { name, gender, birthdate }
---@return boolean, string?
function API.register(payload)
    if type(payload) ~= 'table' then return false, 'payload_invalid' end
    local src = source
    local ok, err = Creator.register(src, payload.name, payload.gender, payload.birthdate)
    if ok then
        TriggerClientEvent('lobby:displayLobby', src)
    end
    return ok, err
end

RPC:bind(API)
