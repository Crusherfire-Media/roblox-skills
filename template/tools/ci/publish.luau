--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local OpenCloud = require("./open-cloud")
local Places = require("./places")

local environment = process.args[1]
if environment ~= "staging" and environment ~= "production" then
	error("usage: lune run tools/ci/publish <staging|production>")
end

local target = Places.target(environment)
if not target then
	print(`places.json has no {environment} universe yet, so nothing is published`)
	process.exit(0)
end
local places = (target :: Places.Target).Places
local universeId = (target :: Places.Target).UniverseId

-- Every place is prepared and checked before the first upload, so a bad build
-- never leaves the experience with some places updated and others not.
local contents = {}
for index, place in places do
	local game = roblox.deserializePlace(fs.readFile(place.BuildPath))
	-- ServerScriptService.Tests (the specs and Jest) runs only in Studio and CI, so players never get it.
	local tests = game:GetService("ServerScriptService"):FindFirstChild("Tests")
	if tests then
		tests:Destroy()
	end
	contents[index] = roblox.serializePlace(game)
	if #contents[index] > OpenCloud.MaxPlaceBytes then
		error(`place "{place.Name}" is {#contents[index]} bytes, over the 10 MB publishing limit`)
	end
end

for index, place in places do
	local version = OpenCloud.uploadPlace(universeId, place.PlaceId, contents[index], true)
	print(`Published "{place.Name}" (place {place.PlaceId}) as version {version}`)
end
