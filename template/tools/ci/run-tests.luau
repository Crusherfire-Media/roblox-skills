--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local task = require("@lune/task")

local OpenCloud = require("./open-cloud")

local TASK_SCRIPT_PATH = "tools/ci/run-specs-task.luau"
local TASK_TIMEOUT = "300s"
local POLL_INTERVAL = 3
-- A task can wait in QUEUED before its 5 minutes start.
local TASK_DEADLINE = 12 * 60
-- Roblox sometimes ends a stuck task with INTERNAL_ERROR; a second task usually runs.
local MAX_TASK_ATTEMPTS = 2
local RETRYABLE_ERROR = "INTERNAL_ERROR"

local function readLogs(taskPath: string): string
	local ok, logs = pcall(function()
		return OpenCloud.request("GET", `/cloud/v2/{taskPath}/logs`)
	end)
	if not ok then
		return `(couldn't read the logs: {logs})`
	end
	local lines = {}
	for _, page in logs.luauExecutionSessionTaskLogs or {} do
		for _, message in page.messages or {} do
			table.insert(lines, message)
		end
	end
	return table.concat(lines, "\n")
end

-- Returns the finished task, or nil and a reason when it never finished.
local function runTask(
	universeId: string,
	placeId: string,
	version: number,
	source: string
): (any, string?)
	local created = OpenCloud.request(
		"POST",
		`/cloud/v2/universes/{universeId}/places/{placeId}/versions/{version}/luau-execution-session-tasks`,
		serde.encode("json", { script = source, timeout = TASK_TIMEOUT }),
		"application/json"
	)
	local deadline = os.time() + TASK_DEADLINE
	local state = created
	while state.state == "QUEUED" or state.state == "PROCESSING" do
		if os.time() > deadline then
			return nil, `task still {state.state} after {TASK_DEADLINE} seconds: {created.path}`
		end
		task.wait(POLL_INTERVAL)
		state = OpenCloud.request("GET", `/cloud/v2/{created.path}`)
	end
	return state, nil
end

local placePath = process.args[1]
if not placePath or not fs.isFile(placePath) then
	error("usage: lune run tools/ci/run-tests <test.rbxl>")
end
local universeId, placeId = OpenCloud.universeId(), OpenCloud.placeId()
local source = fs.readFile(TASK_SCRIPT_PATH)

-- Each task is pinned to its own saved version, so two pull requests never run each other's code.
local version = OpenCloud.uploadPlace(fs.readFile(placePath), false)
print(`Saved the test place as version {version}`)

-- The whole suite runs as one task, since Luau Execution allows 5 task creates per minute per key owner.
local finished, reason
for attempt = 1, MAX_TASK_ATTEMPTS do
	finished, reason = runTask(universeId, placeId, version, source)
	local isRetryable = finished
		and finished.state == "FAILED"
		and typeof(finished.error) == "table"
		and finished.error.code == RETRYABLE_ERROR
	if not isRetryable or attempt == MAX_TASK_ATTEMPTS then
		break
	end
	print(`Roblox ended the task with {RETRYABLE_ERROR}; running it once more`)
end

if not finished then
	print(reason)
	process.exit(1)
end

print(readLogs(finished.path))
if finished.state == "COMPLETE" then
	local results = finished.output and finished.output.results
	print(`\n{if results then results[1] else "Specs passed"}`)
	process.exit(0)
end

local failure = if typeof(finished.error) == "table" then finished.error else {}
print(`\nThe specs failed ({failure.code or finished.state}):\n{failure.message or ""}`)
process.exit(1)
