--!strict
--@author: Crusherfire
--@date: 11/13/26
--[[@description:
	Publishes a build to the place in ROBLOX_PLACE_ID as the version players
	join:

		lune run tools/ci/publish <game.rbxl>

	ServerScriptService.Tests (the specs and Jest) only runs in Studio and in
	CI, so it's removed first.
]]

------------------------------
-- DEPENDENCIES --
------------------------------
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local OpenCloud = require("./open-cloud")

------------------------------
-- MAIN --
------------------------------
local placePath = process.args[1]
if not placePath or not fs.isFile(placePath) then
	error("usage: lune run tools/ci/publish <game.rbxl>")
end

local game = roblox.deserializePlace(fs.readFile(placePath))
local tests = game:GetService("ServerScriptService"):FindFirstChild("Tests")
if tests then
	tests:Destroy()
end

local version = OpenCloud.uploadPlace(roblox.serializePlace(game), true)
print(`Published place {OpenCloud.placeId()} as version {version}`)
