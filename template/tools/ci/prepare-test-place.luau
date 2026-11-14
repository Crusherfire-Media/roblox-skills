--!strict
--@author: Crusherfire
--@date: 11/13/26
--[[@description:
	Turns a build into the place CI runs the specs in:

		lune run tools/ci/prepare-test-place <game.rbxl> <test.rbxl>

	Jest loads specs with loadstring, which a game server allows only with
	ServerScriptService.LoadStringEnabled, so the test place turns it on.
	Server Scripts are disabled so the specs see the game unbooted, as in
	Studio's edit mode. Nothing here reaches a place players join.
]]

------------------------------
-- DEPENDENCIES --
------------------------------
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

------------------------------
-- VARIABLES --
------------------------------
-- Services where a Script with the Legacy run context runs on the server.
local LEGACY_SERVER_ROOTS = { "ServerScriptService", "Workspace" }

------------------------------
-- PRIVATE FUNCTIONS --
------------------------------
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

------------------------------
-- MAIN --
------------------------------
local inputPath, outputPath = process.args[1], process.args[2]
if not inputPath or not outputPath or not fs.isFile(inputPath) then
	error("usage: lune run tools/ci/prepare-test-place <game.rbxl> <test.rbxl>")
end

local game = roblox.deserializePlace(fs.readFile(inputPath))
local disabled = 0
for _, instance in game:GetDescendants() do
	local script = instance :: any
	if script.ClassName == "Script" and not script.Disabled and runsOnServer(game, script) then
		script.Disabled = true
		disabled += 1
	end
end
local serverScriptService = game:GetService("ServerScriptService") :: any
serverScriptService.LoadStringEnabled = true

fs.writeFile(outputPath, roblox.serializePlace(game))
print(`Disabled {disabled} server scripts and turned on LoadStringEnabled`)
