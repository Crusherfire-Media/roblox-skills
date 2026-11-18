--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local task = require("@lune/task")

local OpenCloud = require("./open-cloud")
local Places = require("./places")
local PrepareTestPlace = require("./prepare-test-place")

local TASK_SCRIPT_PATH = "tools/ci/run-specs-task.luau"
local TASK_TIMEOUT = "300s"
local POLL_INTERVAL = 3
-- A task can wait in QUEUED before its 5 minutes start.
local TASK_DEADLINE = 12 * 60
-- Roblox sometimes ends a stuck task with INTERNAL_ERROR; a second task usually runs.
local MAX_TASK_ATTEMPTS = 2
local RETRYABLE_ERROR = "INTERNAL_ERROR"

type Outcome = {
	Passed: boolean,
	Output: string,
}

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

-- Saves one place's test build as an unpublished version and runs its specs.
local function testPlace(universeId: string, place: Places.Place, source: string): Outcome
	local game = roblox.deserializePlace(fs.readFile(place.BuildPath))
	local disabled = PrepareTestPlace.prepare(game)
	-- Each task is pinned to its own saved version, so two pull requests never run each other's code.
	local version =
		OpenCloud.uploadPlace(universeId, place.PlaceId, roblox.serializePlace(game), false)
	print(`{place.Name}: disabled {disabled} server scripts, saved as version {version}`)

	local finished, reason
	for attempt = 1, MAX_TASK_ATTEMPTS do
		finished, reason = runTask(universeId, place.PlaceId, version, source)
		local isRetryable = finished
			and finished.state == "FAILED"
			and typeof(finished.error) == "table"
			and finished.error.code == RETRYABLE_ERROR
		if not isRetryable or attempt == MAX_TASK_ATTEMPTS then
			break
		end
		print(`{place.Name}: Roblox ended the task with {RETRYABLE_ERROR}; running it once more`)
	end
	if not finished then
		return { Passed = false, Output = reason or "the task never finished" }
	end

	local logs = readLogs(finished.path)
	if finished.state == "COMPLETE" then
		local results = finished.output and finished.output.results
		local summary = if results then results[1] else "Specs passed"
		return { Passed = true, Output = `{logs}\n\n{summary}` }
	end
	local failure = if typeof(finished.error) == "table" then finished.error else {}
	local heading = `The specs failed ({failure.code or finished.state}):`
	return { Passed = false, Output = `{logs}\n\n{heading}\n{failure.message or ""}` }
end

local target = Places.target("ci")
if not target then
	print("places.json has no CI universe yet, so there's nothing to test (tools/ci/README.md)")
	process.exit(0)
end
local places = (target :: Places.Target).Places
local universeId = (target :: Places.Target).UniverseId
local source = fs.readFile(TASK_SCRIPT_PATH)

-- Every place tests at once, one task each, so the run takes about as long as
-- the slowest place. Luau Execution allows 5 task creates per minute per key
-- owner; past 5 places, request() waits out the 429s.
local outcomes: { Outcome } = {}
local pending = #places
for index, place in places do
	task.spawn(function()
		local ok, result = pcall(testPlace, universeId, place, source)
		outcomes[index] = if ok then result else { Passed = false, Output = tostring(result) }
		pending -= 1
	end)
end
while pending > 0 do
	task.wait(1)
end

local failed = {}
for index, place in places do
	local outcome = outcomes[index]
	print(`\n===== {place.Name} =====\n{outcome.Output}`)
	if not outcome.Passed then
		table.insert(failed, place.Name)
	end
end
if #failed > 0 then
	print(`\nSpecs failed in: {table.concat(failed, ", ")}`)
	process.exit(1)
end
print(`\nSpecs passed in every place ({#places})`)
