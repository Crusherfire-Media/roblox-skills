--[[
	Plays UI sounds for the local player.
]]

local SoundService = game:GetService("SoundService")

local UiSounds = {}

--[[
	Plays the sound with <soundId> once.
]]
function UiSounds.play(soundId: string)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Parent = SoundService
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
end

return UiSounds
