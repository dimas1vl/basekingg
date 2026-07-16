while not Core do
    Wait(100)
end

---@class Matchmaking
---@field queues table<string, number[]>
---@field playerQueue table<number, string>
---@field playerFill table<number, boolean>
---@field playerGroup table<number, number>
---@field groupMembers table<number, number[]>
---@field nextGroupId number
local Matchmaking = {
    queues = {},
    playerQueue = {},
    playerFill = {},
    playerGroup = {},
    groupMembers = {},
    nextGroupId = 1,
}

---@param mode string
---@param subMode string
---@param squadType string
---@return string
function Matchmaking:getQueueKey(mode, subMode, squadType)

    return ('%s|%s|%s'):format(mode, subMode, squadType)
end

---@param queueKey string
---@return string mode
---@return string subMode
---@return string squadType
function Matchmaking:parseQueueKey(queueKey)

    local mode, subMode, squadType = queueKey:match('^(.+)|(.+)|(.+)$')
    return mode, subMode, squadType
end

---@param mode string
---@param subMode string
---@param squadType string
---@return number
function Matchmaking:getRequiredSquads(mode, subMode, squadType)

    return Config.Modes[mode].sub_modes[subMode].requiredSquads
end

---@param queue number[]
---@return number[], number[] fillSources, nonFillSources
function Matchmaking:splitFill(queue)

    local fill = {}
    local noFill = {}

    for i = 1, #queue do
        local src = queue[i]

        if self.playerFill[src] then
            fill[#fill + 1] = src
        else
            noFill[#noFill + 1] = src
        end
    end

    return fill, noFill
end

---@param queue number[]
---@return number squadCount
function Matchmaking:countSquads(queue)

    local fill, noFill = self:splitFill(queue)
    local count = #noFill

    if #fill > 0 then
        count = count + 1
    end

    return count
end

---@param queue number[]
---@return number[][] squadGroups
---@return number[] batch
function Matchmaking:buildSquadGroups(queue)

    local fill, noFill = self:splitFill(queue)
    local squadGroups = {}
    local batch = {}

    for i = 1, #noFill do
        squadGroups[#squadGroups + 1] = { noFill[i] }
        batch[#batch + 1] = noFill[i]
    end

    if #fill > 0 then
        squadGroups[#squadGroups + 1] = fill

        for i = 1, #fill do
            batch[#batch + 1] = fill[i]
        end
    end

    return squadGroups, batch
end

---@param sources number[]
---@param mode string
---@param subMode string
---@param squadType string
---@param fill? boolean
---@return boolean success
---@return string | nil errorMessage
function Matchmaking:addPlayers(sources, mode, subMode, squadType, fill)

    assert(type(sources) == 'table' and #sources > 0, 'sources must be a non-empty array')
    assert(Config.Modes[mode], ('mode "%s" not found in Config.Modes'):format(mode))
    assert(Config.Modes[mode].sub_modes[subMode], ('sub_mode "%s" not found'):format(subMode))
    assert(Config.Modes[mode].sub_modes[subMode].squads[squadType], ('squadType "%s" not found'):format(squadType))

    for i = 1, #sources do
        local src = tonumber(sources[i])

        if not src or not DoesPlayerExist(src) then
            return false, ('player source %s does not exist'):format(tostring(sources[i]))
        end

        if self.playerQueue[src] then
            return false, ('player %s is already in queue "%s"'):format(src, self.playerQueue[src])
        end
    end

    local key = self:getQueueKey(mode, subMode, squadType)

    if not self.queues[key] then
        self.queues[key] = {}
    end

    local groupId = nil

    if #sources > 1 then
        groupId = self.nextGroupId
        self.nextGroupId = self.nextGroupId + 1
        self.groupMembers[groupId] = {}
    end

    for i = 1, #sources do

        local src = tonumber(sources[i])

        self.queues[key][#self.queues[key] + 1] = src
        self.playerQueue[src] = key
        self.playerFill[src] = fill == true

        if groupId then
            self.playerGroup[src] = groupId
            self.groupMembers[groupId][#self.groupMembers[groupId] + 1] = src
        end
    end

    log('info', ('added %d player(s) to queue "%s" fill=%s (total=%d)'):format(
        #sources, key, tostring(fill == true), #self.queues[key]
    ))
    return true
end

---@param src number
function Matchmaking:removePlayer(src)

    src = tonumber(src)

    if not src then return end

    local key = self.playerQueue[src]

    if not key or not self.queues[key] then
        self.playerQueue[src] = nil
        self.playerFill[src] = nil
        return
    end

    local queue = self.queues[key]

    for i = #queue, 1, -1 do
        if queue[i] == src then
            table.remove(queue, i)
            break
        end
    end

    self.playerQueue[src] = nil
    self.playerFill[src] = nil

    local gid = self.playerGroup[src]

    if gid then
        self.playerGroup[src] = nil

        local members = self.groupMembers[gid]

        if members then

            for i = #members, 1, -1 do

                if members[i] == src then
                    table.remove(members, i)
                    break
                end
            end

            if #members == 0 then
                self.groupMembers[gid] = nil
            end
        end
    end

    if #queue == 0 then
        self.queues[key] = nil
    end

    log('info', ('removed player %s from queue "%s"'):format(src, key))
end

RegisterNetEvent('net.kingg:matchmaking.leave', function()

    local src = source
    Matchmaking:removePlayer(src)
end)

AddEventHandler('playerDropped', function()

    local src = source
    Matchmaking:removePlayer(src)
end)

CreateThread(function()

    while true do
        Wait(1000)

        local ok, err = pcall(function()

            for key, queue in pairs(Matchmaking.queues) do

                for i = #queue, 1, -1 do

                    if not DoesPlayerExist(queue[i]) then

                        local src = queue[i]

                        Matchmaking.playerFill[src] = nil
                        Matchmaking.playerQueue[src] = nil

                        local gid = Matchmaking.playerGroup[src]

                        if gid then
                            Matchmaking.playerGroup[src] = nil

                            local members = Matchmaking.groupMembers[gid]

                            if members then

                                for j = #members, 1, -1 do

                                    if members[j] == src then
                                        table.remove(members, j)
                                        break
                                    end
                                end

                                if #members == 0 then
                                    Matchmaking.groupMembers[gid] = nil
                                end
                            end
                        end

                        table.remove(queue, i)
                    end
                end

                if #queue == 0 then
                    Matchmaking.queues[key] = nil
                    goto continue
                end

                local mode, subMode, squadType = Matchmaking:parseQueueKey(key)

                local batch = {}
                local fillMap = {}
                local groupMap = {}
                local seenGroups = {}

                for i = 1, #queue do

                    local src = queue[i]

                    batch[i] = src
                    fillMap[src] = Matchmaking.playerFill[src] or false

                    local gid = Matchmaking.playerGroup[src]

                    if gid and not seenGroups[gid] then
                        seenGroups[gid] = true
                        groupMap[gid] = Matchmaking.groupMembers[gid]
                    end
                end

                for i = 1, #batch do

                    local src = batch[i]
                    local gid = Matchmaking.playerGroup[src]

                    Matchmaking.playerQueue[src] = nil
                    Matchmaking.playerFill[src] = nil
                    Matchmaking.playerGroup[src] = nil

                    if gid then
                        Matchmaking.groupMembers[gid] = nil
                    end
                end

                Matchmaking.queues[key] = nil

                log('info', ('matchmaking dispatch: mode=%s subMode=%s squad=%s players=%d'):format(
                    mode, subMode, squadType, #batch
                ))
                TriggerEvent('kingg:matchmaking:start', batch, mode, subMode, squadType, fillMap, groupMap)

                ::continue::
            end
        end)

        if not ok then
            log('error', ('matchmaking thread error: %s'):format(tostring(err)))
        end
    end
end)


---@param sources number[]
---@param mode string
---@param subMode string
---@param squadType string
---@param fill? boolean
---@return boolean success
---@return string | nil errorMessage
Core.addPlayerToQueue = function(sources, mode, subMode, squadType, fill)
    return Matchmaking:addPlayers(sources, mode, subMode, squadType, fill)
end

---@param src number
---@return boolean success
---@return string | nil errorMessage
Core.removePlayerFromQueue = function(src)
    return Matchmaking:removePlayer(src)
end

---@param mode string
---@param subMode string
---@param squadType string
---@return number size
Core.getQueueSize = function(mode, subMode, squadType)
    local key = Matchmaking:getQueueKey(mode, subMode, squadType)
    local queue = Matchmaking.queues[key]
    return queue and #queue or 0
end

---@param mode string
---@param subMode string
---@param squadType string
---@return number[] sources
---@return table<number, boolean> fillMap
Core.getQueuePlayers = function(mode, subMode, squadType)
    local key = Matchmaking:getQueueKey(mode, subMode, squadType)
    local queue = Matchmaking.queues[key]

    if not queue then return {}, {} end

    local sources = {}
    local fillMap = {}

    for i = 1, #queue do
        sources[i] = queue[i]
        fillMap[queue[i]] = Matchmaking.playerFill[queue[i]] or false
    end

    return sources, fillMap
end

---@param mode string
---@param subMode string
---@param squadType string
Core.clearQueue = function(mode, subMode, squadType)
    local key = Matchmaking:getQueueKey(mode, subMode, squadType)
    local queue = Matchmaking.queues[key]

    if not queue then return end

    for i = 1, #queue do
        Matchmaking.playerQueue[queue[i]] = nil
        Matchmaking.playerFill[queue[i]] = nil
    end

    Matchmaking.queues[key] = nil
end

local function normalize(s)
    return tostring(s or '')
        :lower()
        :gsub('[%s_]+', '-')
        :gsub('[^%w%-]', '')
end

---@param modeId string
---@param subModeId string
---@param squadTypeId string | nil
---@return string | nil modeKey
---@return string | nil subModeKey
---@return string | nil squadKey
Core.resolveMatchKeys = function(modeId, subModeId, squadTypeId)
    if not Config.Modes then return nil, nil, nil end

    local target = normalize(modeId)
    local modeKey
    for key in pairs(Config.Modes) do
        if normalize(key) == target then modeKey = key break end
    end
    if not modeKey then return nil, nil, nil end

    target = normalize(subModeId)
    local subModeKey
    for key in pairs(Config.Modes[modeKey].sub_modes) do
        if normalize(key) == target then subModeKey = key break end
    end
    if not subModeKey then return modeKey, nil, nil end

    local squads = Config.Modes[modeKey].sub_modes[subModeKey].squads
    local squadKey
    if squadTypeId then
        target = normalize(squadTypeId)
        for key in pairs(squads) do
            if normalize(key) == target then squadKey = key break end
        end
    end
    if not squadKey then squadKey = next(squads) end

    return modeKey, subModeKey, squadKey
end

---@param sources number[]
---@param fillMap table<number, boolean>
---@return number[][] squadGroups
---@return number[] batch
Core.buildSquadGroups = function(sources, fillMap)
    local fill = {}
    local noFill = {}

    for i = 1, #sources do
        local src = sources[i]
        if fillMap[src] then
            fill[#fill + 1] = src
        else
            noFill[#noFill + 1] = src
        end
    end

    local squadGroups = {}
    local batch = {}

    for i = 1, #noFill do
        squadGroups[#squadGroups + 1] = { noFill[i] }
        batch[#batch + 1] = noFill[i]
    end

    if #fill > 0 then
        squadGroups[#squadGroups + 1] = fill
        for i = 1, #fill do
            batch[#batch + 1] = fill[i]
        end
    end

    return squadGroups, batch
end
