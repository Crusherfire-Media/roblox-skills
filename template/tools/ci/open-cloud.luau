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
local OPERATION_POLL_INTERVAL = 2
local OPERATION_DEADLINE = 5 * 60

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

-- A random boundary that never appears in the file, so the form parses.
local function makeBoundary(contents: string): string
	while true do
		local boundary = `----roblox-ci-{math.random(1e9)}{math.random(1e9)}`
		if not string.find(contents, boundary, 1, true) then
			return boundary
		end
	end
end

--[[
	The place id from ROBLOX_PLACE_ID.
]]
function Module.placeId(): string
	return readId("ROBLOX_PLACE_ID")
end

--[[
	The universe id from ROBLOX_UNIVERSE_ID, which Luau Execution needs.
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
	Uploads a place file as a new version of ROBLOX_PLACE_ID through the
	Assets API and returns the version number. A published version is the
	one players join; an unpublished one is only saved.
]]
function Module.uploadPlace(contents: string, isPublished: boolean): number
	local placeId = Module.placeId()
	local boundary = makeBoundary(contents)
	local requestJson = serde.encode("json", {
		assetId = tonumber(placeId),
		assetType = "Place",
		published = isPublished,
	})
	local form = table.concat({
		`--{boundary}\r\n`,
		'Content-Disposition: form-data; name="request"\r\n',
		"Content-Type: application/json\r\n\r\n",
		requestJson,
		`\r\n--{boundary}\r\n`,
		'Content-Disposition: form-data; name="fileContent"; filename="place.rbxl"\r\n',
		"Content-Type: application/octet-stream\r\n\r\n",
		contents,
		`\r\n--{boundary}--\r\n`,
	})
	local operation = Module.request(
		"PATCH",
		`/assets/v1/assets/{placeId}`,
		form,
		`multipart/form-data; boundary={boundary}`
	)

	local deadline = os.time() + OPERATION_DEADLINE
	while not operation.done do
		if os.time() > deadline then
			error(`upload still processing after {OPERATION_DEADLINE} seconds: {operation.path}`)
		end
		task.wait(OPERATION_POLL_INTERVAL)
		operation = Module.request("GET", `/assets/v1/{operation.path}`)
	end
	if operation.error then
		error(`upload failed: {serde.encode("json", operation.error)}`)
	end
	local version = tonumber(operation.response and operation.response.revisionId)
	if not version then
		error(`upload finished without a version number: {serde.encode("json", operation)}`)
	end
	return version
end

return Module
