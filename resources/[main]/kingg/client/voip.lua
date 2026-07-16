local voiceTarget = 1
local hearList = {}
local activeChannel = nil

---@param src number
local function addPlayer(src)

    hearList[src] = true
    MumbleAddVoiceTargetPlayerByServerId(voiceTarget, src)
end

---@param src number
local function removePlayer(src)

    hearList[src] = nil
    MumbleRemoveVoiceTargetPlayerByServerId(voiceTarget, src)
end

local function restore()

    MumbleClearVoiceTarget(voiceTarget)
    MumbleSetVoiceTarget(voiceTarget)
    MumbleSetVoiceChannel(activeChannel)
    MumbleAddVoiceTargetChannel(voiceTarget, activeChannel)

    for src in pairs(hearList) do
        MumbleAddVoiceTargetPlayerByServerId(voiceTarget, src)
    end
end

---@param channel number
---@param sources number[]
local function start(channel, sources)

    hearList = {}
    activeChannel = channel

    MumbleClearVoiceTarget(voiceTarget)
    MumbleSetVoiceTarget(voiceTarget)
    MumbleSetVoiceChannel(channel)
    MumbleAddVoiceTargetChannel(voiceTarget, channel)

    local selfSrc = GetPlayerServerId(PlayerId())

    for _, src in ipairs(sources) do

        if src ~= selfSrc then
            addPlayer(src)
        end
    end
end

local function clear()

    activeChannel = nil
    hearList = {}
    MumbleClearVoiceChannel()
    MumbleClearVoiceTarget(voiceTarget)
end

AddEventHandler('mumbleConnected', function()

    if not activeChannel then return end

    restore()
end)

exports('addGroup', start)
exports('removePlayer', removePlayer)
exports('clearGroup', clear)
