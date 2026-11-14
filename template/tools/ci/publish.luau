--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local OpenCloud = require("./open-cloud")

local placePath = process.args[1]
if not placePath or not fs.isFile(placePath) then
	error("usage: lune run tools/ci/publish <game.rbxl>")
end

local game = roblox.deserializePlace(fs.readFile(placePath))
-- ServerScriptService.Tests (the specs and Jest) runs only in Studio and CI, so players never get it.
local tests = game:GetService("ServerScriptService"):FindFirstChild("Tests")
if tests then
	tests:Destroy()
end

local version = OpenCloud.uploadPlace(roblox.serializePlace(game), true)
print(`Published place {OpenCloud.placeId()} as version {version}`)
