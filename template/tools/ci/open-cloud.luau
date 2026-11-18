--!strict

local net = require("@lune/net")
local process = require("@lune/process")
local serde = require("@lune/serde")
local task = require("@lune/task")

local API_ROOT = "https://apis.roblox.com"
local MAX_ATTEMPTS = 5
local FIRST_RETRY_DELAY = 2
-- A longer Retry-After means an hourly lockout, which retrying can't outlast.
local MAX_RETRY_AFTER = 60
local TOO_MANY_REQUESTS = 429
local SERVER_ERROR = 500
local MAX_PLACE_BYTES = 10 * 1024 * 1024

local Module = {}

local function readEnv(name: string): string
	local value = process.env[name]
	if not value or value == "" then
		error(`{name} is not set. tools/ci/README.md lists the secrets and variables CI needs.`)
	end
	return value
end

local function readId(name: string): string
	local value = readEnv(name)
	if not string.match(value, "^%d+$") then
		error(`{name} must be a number, the id shown in the Creator Dashboard`)
	end
	return value
end

local function retryDelay(response: net.FetchResponse, attempt: number): number?
	local isRetryable = response.statusCode == TOO_MANY_REQUESTS
		or response.statusCode >= SERVER_ERROR
	if not isRetryable or attempt == MAX_ATTEMPTS then
		return nil
	end
	local retryAfter = tonumber(response.headers["retry-after"])
	if retryAfter and retryAfter > MAX_RETRY_AFTER then
		return nil
	end
	return retryAfter or FIRST_RETRY_DELAY * 2 ^ (attempt - 1)
end

--[[
	The place id from ROBLOX_PLACE_ID.
]]
function Module.placeId(): string
	return readId("ROBLOX_PLACE_ID")
end

--[[
	The universe id from ROBLOX_UNIVERSE_ID, which Place Publishing and Luau
	Execution need.
]]
function Module.universeId(): string
	return readId("ROBLOX_UNIVERSE_ID")
end

--[[
	Sends a request and returns its decoded JSON body. Rate limits and server
	errors are retried with a growing wait, honoring Retry-After. Any other
	failure errors with the status and body, which name the problem (a
	missing permission, an unknown place) and never contain the key.
]]
function Module.request(
	method: net.HttpMethod,
	path: string,
	body: string?,
	contentType: string?
): any
	local headers: net.HttpHeaderMap = { ["x-api-key"] = readEnv("ROBLOX_API_KEY") }
	if contentType then
		headers["content-type"] = contentType
	end
	local response
	for attempt = 1, MAX_ATTEMPTS do
		response = net.request({
			url = `{API_ROOT}{path}`,
			method = method,
			headers = headers,
			body = body,
		})
		local delay = retryDelay(response, attempt)
		if response.ok or not delay then
			break
		end
		print(`{method} {path} returned {response.statusCode}; retrying in {delay} seconds`)
		task.wait(delay)
	end
	if not response.ok then
		error(`{method} {path} failed with {response.statusCode}: {response.body}`)
	end
	if response.body == "" then
		return {}
	end
	return serde.decode("json", response.body)
end

--[[
	Uploads a binary place file as a new version of ROBLOX_PLACE_ID through
	the Place Publishing API and returns the version number. A published
	version is the one players join; a saved one isn't.

	This needs the universe-places Write permission, which can be restricted
	to experiences. The Assets API's Update Asset can't: its Write reaches
	every asset the key's account can access.
]]
function Module.uploadPlace(contents: string, isPublished: boolean): number
	if #contents > MAX_PLACE_BYTES then
		error(`the place file is {#contents} bytes, over Place Publishing's 10 MB limit`)
	end
	local versionType = if isPublished then "Published" else "Saved"
	local path = `/universes/v1/{Module.universeId()}/places/{Module.placeId()}`
		.. `/versions?versionType={versionType}`
	local result = Module.request("POST", path, contents, "application/octet-stream")
	local version = tonumber(result.versionNumber)
	if not version then
		error(`upload finished without a version number: {serde.encode("json", result)}`)
	end
	return version
end

return Module
