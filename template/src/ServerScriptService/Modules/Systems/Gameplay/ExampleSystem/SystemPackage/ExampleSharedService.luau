--!strict
--@author: Crusherfire
--@date: 11/13/26
--[[@description:
	Builds the message that welcomes a player. The game supplies the wording
	through SetGreeting, so this package holds no game-specific text.

	ExampleSystem shows the layout every system follows. Replace it with the
	game's first real system.
]]

------------------------------
-- VARIABLES --
------------------------------
const NAME_PLACEHOLDER = "{name}"

local Module = {}
Module.__index = Module

local greeting = `Welcome, {NAME_PLACEHOLDER}!`

------------------------------
-- PUBLIC FUNCTIONS --
------------------------------

--[[
	Sets the welcome message. Every "{name}" in it becomes the player's name.
]]
function Module:SetGreeting(newGreeting: string)
	greeting = newGreeting
end

function Module:FormatGreeting(playerName: string): string
	-- A function replacement keeps "%" in a name from being read as a pattern escape.
	local message = string.gsub(greeting, NAME_PLACEHOLDER, function()
		return playerName
	end)
	return message
end

return Module
