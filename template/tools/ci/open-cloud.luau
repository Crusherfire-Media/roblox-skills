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
-- Rate limits count per minute (Luau Execution allows 5 task creates per
-- minute per key owner), so a 429 without Retry-After waits 15, 30, then
-- 60 seconds: long enough to outlast the window.
local FIRST_RATE_LIMIT_DELAY = 15
local TOO_MANY_REQUESTS = 429
local SERVER_ERROR = 500
local MAX_PLACE_BYTES = 10 * 1024 * 1024

local Module = {}

-- Place Publishing's limit on a place file.
Module.MaxPlaceBytes = MAX_PLACE_BYTES

local function readEnv(name: string): string
	local value = process.env[name]
	if not value or value == "" then
		error(`{name} is not set. tools/ci/README.md covers the secret CI needs.`)
	end
	return value
end

--[[
	A secret pasted into GitHub's web form often keeps the line break after
	it, which Lune rejects as a header value with no hint of which header.
	Surrounding whitespace is trimmed; anything left that a header can't hold
	means a mangled key. The error never includes the key.
]]
local function readApiKey(): string
	local key = string.match(readEnv("ROBLOX_API_KEY"), "^%s*(.-)%s*$") :: string
	if key == "" then
		error("ROBLOX_API_KEY holds only whitespace. Store it again with tools/set-api-key.ps1.")
	end
	if string.find(key, "[%s%c]") then
		error(
			"ROBLOX_API_KEY has spaces, line breaks, or control characters inside it. "
				.. "Store it again with tools/set-api-key.ps1 or tools/set-api-key.sh."
		)
	end
	return key
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
	if retryAfter then
		return retryAfter
	end
	local firstDelay = if response.statusCode == TOO_MANY_REQUESTS
		then FIRST_RATE_LIMIT_DELAY
		else FIRST_RETRY_DELAY
	return math.min(firstDelay * 2 ^ (attempt - 1), MAX_RETRY_AFTER)
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
	local headers: net.HttpHeaderMap = { ["x-api-key"] = readApiKey() }
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
	Uploads a binary place file as a new version of a place through the
	Place Publishing API and returns the version number. A published
	version is the one players join; a saved one isn't.

	This needs the universe-places Write permission, which can be restricted
	to experiences. The Assets API's Update Asset can't: its Write reaches
	every asset the key's account can access.
]]
function Module.uploadPlace(
	universeId: string,
	placeId: string,
	contents: string,
	isPublished: boolean
): number
	if #contents > MAX_PLACE_BYTES then
		error(`the place file is {#contents} bytes, over Place Publishing's 10 MB limit`)
	end
	local versionType = if isPublished then "Published" else "Saved"
	local path = `/universes/v1/{universeId}/places/{placeId}/versions?versionType={versionType}`
	local result = Module.request("POST", path, contents, "application/octet-stream")
	local version = tonumber(result.versionNumber)
	if not version then
		error(`upload finished without a version number: {serde.encode("json", result)}`)
	end
	return version
end

return Module
