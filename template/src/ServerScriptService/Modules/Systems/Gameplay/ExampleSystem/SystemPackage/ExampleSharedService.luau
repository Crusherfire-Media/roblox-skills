--!strict

const NAME_PLACEHOLDER = "{name}"

local Module = {}
Module.__index = Module

-- The game supplies the wording through SetGreeting, so this package holds no game-specific text.
local greeting = `Welcome, {NAME_PLACEHOLDER}!`

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
