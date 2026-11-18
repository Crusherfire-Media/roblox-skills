--!strict

local roblox = require("@lune/roblox")

-- Services where a Script with the Legacy run context runs on the server.
local LEGACY_SERVER_ROOTS = { "ServerScriptService", "Workspace" }

local Module = {}

-- Lune's types leave out class properties, so scripts are read as `any`.
local function runsOnServer(game: roblox.DataModel, script: any): boolean
	local runContext = script.RunContext.Name
	if runContext == "Server" then
		return true
	end
	if runContext ~= "Legacy" then
		return false
	end
	for _, rootName in LEGACY_SERVER_ROOTS do
		if script:IsDescendantOf(game:GetService(rootName)) then
			return true
		end
	end
	return false
end

--[[
	Turns a game build into the test place the specs run in, in place, and
	returns how many server scripts it disabled. With server Scripts off, the
	specs see the game unbooted, as in Studio's edit mode. Only the CI place
	gets this.
]]
function Module.prepare(game: roblox.DataModel): number
	local disabled = 0
	for _, instance in game:GetDescendants() do
		local script = instance :: any
		if script.ClassName == "Script" and not script.Disabled and runsOnServer(game, script) then
			script.Disabled = true
			disabled += 1
		end
	end
	-- Jest loads specs with loadstring, which a game server allows only with LoadStringEnabled.
	local serverScriptService = game:GetService("ServerScriptService") :: any
	serverScriptService.LoadStringEnabled = true
	return disabled
end

return Module
