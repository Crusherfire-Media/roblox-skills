--[[
	Client volume control. Every music track plays through the Music sound group and every sound
	effect through Effects, so one volume per group covers the whole game.
]]

local SoundService = game:GetService("SoundService")

local DEFAULT_MUSIC_VOLUME = 0.5
local DEFAULT_EFFECTS_VOLUME = 0.8

local GameAudio = {}

local function getOrCreateGroup(name: string, volume: number): SoundGroup
	local existing = SoundService:FindFirstChild(name)
	if existing and existing:IsA("SoundGroup") then
		return existing
	end
	local group = Instance.new("SoundGroup")
	group.Name = name
	group.Volume = volume
	group.Parent = SoundService
	return group
end

local musicGroup = getOrCreateGroup("Music", DEFAULT_MUSIC_VOLUME)
local effectsGroup = getOrCreateGroup("Effects", DEFAULT_EFFECTS_VOLUME)

-- Volumes run from 0 (silent) to 1 (full).
function GameAudio.getMusicVolume(): number
	return musicGroup.Volume
end

function GameAudio.setMusicVolume(volume: number)
	musicGroup.Volume = math.clamp(volume, 0, 1)
end

function GameAudio.getEffectsVolume(): number
	return effectsGroup.Volume
end

function GameAudio.setEffectsVolume(volume: number)
	effectsGroup.Volume = math.clamp(volume, 0, 1)
end

return GameAudio
