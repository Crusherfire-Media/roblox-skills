--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local CONFIG_PATH = "places.json"
local PLACES_DIR = "places"
local ENVIRONMENTS = { "ci", "staging", "production" }
-- Place names become paths and shell words in CI, so they stay plain.
local NAME_PATTERN = "^[%w_-]+$"

export type Environment = "ci" | "staging" | "production"
export type Place = {
	Name: string,
	PlaceId: string,
	-- The place's build, from tools/ci/build.
	BuildPath: string,
}
export type Target = {
	UniverseId: string,
	Places: { Place },
}

local Module = {}

local function fail(message: string): never
	error(`places.json: {message}`)
end

-- An id is null (not set up yet) or a positive whole number.
local function readId(value: unknown, where: string): string?
	if value == nil then
		return nil
	end
	if typeof(value) ~= "number" or value <= 0 or value % 1 ~= 0 then
		fail(`{where} must be null or the id from the Creator Dashboard, a whole number`)
	end
	return string.format("%d", value :: number)
end

local function readEnvironmentIds(value: unknown, where: string): { [string]: string? }
	if typeof(value) ~= "table" then
		fail(`{where} must be an object with "ci", "staging", and "production"`)
	end
	local ids = {}
	for _, environment in ENVIRONMENTS do
		ids[environment] = readId((value :: any)[environment], `{where}.{environment}`)
	end
	return ids
end

local function readConfig(): any
	if not fs.isFile(CONFIG_PATH) then
		fail("not found. Run CI scripts from the repo root.")
	end
	local ok, config = pcall(serde.decode, "json" :: "json", fs.readFile(CONFIG_PATH))
	if not ok or typeof(config) ~= "table" then
		fail("isn't valid JSON")
	end
	return config
end

--[[
	The place names in places.json, sorted. Errors when places.json and the
	place folders disagree, or when an experience is set up but a place has
	no id in it, so the build in Checks catches what would otherwise fail
	only at a publish.
]]
function Module.names(): { string }
	local config = readConfig()
	local universeIds = readEnvironmentIds(config.universes, "universes")
	if typeof(config.places) ~= "table" or next(config.places) == nil then
		fail(`"places" must list at least one place`)
	end

	local names = {}
	for name, value in config.places do
		if typeof(name) ~= "string" or not string.match(name, NAME_PATTERN) then
			fail(`place name "{name}" may only use letters, digits, "_", and "-"`)
		end
		if not fs.isFile(`{PLACES_DIR}/{name}/default.project.json`) then
			fail(`place "{name}" has no {PLACES_DIR}/{name}/default.project.json`)
		end
		local placeIds = readEnvironmentIds(value, `places.{name}`)
		-- Every place ships together, so each set-up experience needs them all.
		for _, environment in ENVIRONMENTS do
			if universeIds[environment] and not placeIds[environment] then
				fail(`universes.{environment} is set, but places.{name}.{environment} isn't`)
			end
		end
		table.insert(names, name)
	end
	for _, folder in fs.readDir(PLACES_DIR) do
		local hasProject = fs.isFile(`{PLACES_DIR}/{folder}/default.project.json`)
		if hasProject and config.places[folder] == nil then
			fail(`{PLACES_DIR}/{folder} has a project but no entry under "places"`)
		end
	end
	table.sort(names)
	return names
end

--[[
	The universe and places to upload to in one environment, or nil while
	that environment's universe is null (not set up yet).
]]
function Module.target(environment: Environment): Target?
	local names = Module.names()
	local config = readConfig()
	local universeId = readEnvironmentIds(config.universes, "universes")[environment]
	if not universeId then
		return nil
	end

	local places = {}
	for _, name in names do
		local placeId = readEnvironmentIds(config.places[name], `places.{name}`)[environment]
		if placeId then
			table.insert(places, {
				Name = name,
				PlaceId = placeId,
				BuildPath = `build/{name}.rbxl`,
			})
		else
			fail(`universes.{environment} is set, but places.{name}.{environment} isn't`)
		end
	end
	return { UniverseId = universeId, Places = places }
end

return Module
