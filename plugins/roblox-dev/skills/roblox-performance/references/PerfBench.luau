--!strict
--!optimize 2

const RunService = game:GetService("RunService")
const Stats = game:GetService("Stats")

const DEFAULT_EVENT: FrameEvent = "PreSimulation"
const DEFAULT_FRAMES = 120
const DEFAULT_WARMUP = 30
const DEFAULT_ITERATIONS = 100000
const DEFAULT_SAMPLES = 5
const DEFAULT_ROUNDS = 3
const DEFAULT_MINIMUM_BYTES = 1
const P90_FRACTION = 0.9
const MILLISECONDS_PER_SECOND = 1000
const NANOSECONDS_PER_SECOND = 1e9
const BYTES_PER_MB = 1024 * 1024

export type Summary = {
	Median: number,
	P90: number,
	Mean: number,
}

export type FrameEvent =
	"PreAnimation"
	| "PreSimulation"
	| "PostSimulation"
	| "Heartbeat"
	| "PreRender"

export type FrameOptions = {
	Event: FrameEvent?,
	Frames: number?,
	Warmup: number?,
}

export type FrameResult = {
	Script: Summary,
	Frame: Summary,
	PhysicsJob: Summary,
	Heartbeat: Summary,
	RenderCpu: Summary,
}

export type CompareOptions = {
	Iterations: number?,
	Samples: number?,
	Rounds: number?,
}

export type CompareResult = { [string]: Summary }

export type MemoryDeltaOptions = {
	ItemCount: number,
	MinimumBytes: number?,
}

type Case = (iterations: number) -> any

local function summarize(samples: { number }): Summary
	table.sort(samples)

	local sum = 0
	for _, value in samples do
		sum += value
	end

	return {
		Median = samples[math.ceil(#samples / 2)],
		P90 = samples[math.ceil(#samples * P90_FRACTION)],
		Mean = sum / #samples,
	}
end

local function formatSummary(name: string, summary: Summary): string
	return string.format("%s %.2f/%.2f/%.2f", name, summary.Median, summary.P90, summary.Mean)
end

local function getFrameSignal(event: FrameEvent): RBXScriptSignal
	if event == "PreAnimation" then
		return RunService.PreAnimation
	elseif event == "PreSimulation" then
		return RunService.PreSimulation
	elseif event == "PostSimulation" then
		return RunService.PostSimulation
	elseif event == "Heartbeat" then
		return RunService.Heartbeat
	elseif event == "PreRender" then
		return RunService.PreRender
	end

	error(`Unhandled frame event: {event}`)
end

local Module = {}

--[[
	Runs step on each firing of Event (PreSimulation by default) and returns the times in
	milliseconds. PreSimulation can fire more than once per drawn frame, so on a client pass
	PreRender for one run per drawn frame.

	Script is the time inside step. Frame is the interval between firings, which only means
	something when the workload exceeds the frame cap. PhysicsJob, Heartbeat, and RenderCpu are
	the engine's own timers, which include work that step queued for later in the frame.
]]
function Module.measureFramesAsync(step: (frame: number) -> (), options: FrameOptions?): FrameResult
	local resolved: FrameOptions = options or {}
	local frames = resolved.Frames or DEFAULT_FRAMES
	local warmup = resolved.Warmup or DEFAULT_WARMUP
	assert(frames >= 1, "Frames must be at least 1")

	local scriptTimes, frameTimes, physicsTimes, heartbeatTimes, renderTimes = {}, {}, {}, {}, {}
	local frame = 0
	local lastFrameStart = os.clock()
	local waitingThread = coroutine.running()

	local connection: RBXScriptConnection
	connection = getFrameSignal(resolved.Event or DEFAULT_EVENT):Connect(function()
		frame += 1

		local frameStart = os.clock()
		step(frame)
		local scriptSeconds = os.clock() - frameStart

		if frame > warmup then
			table.insert(scriptTimes, scriptSeconds * MILLISECONDS_PER_SECOND)
			table.insert(frameTimes, (frameStart - lastFrameStart) * MILLISECONDS_PER_SECOND)
			table.insert(physicsTimes, Stats.PhysicsStepTime * MILLISECONDS_PER_SECOND)
			table.insert(heartbeatTimes, Stats.HeartbeatTime * MILLISECONDS_PER_SECOND)
			table.insert(renderTimes, Stats.RenderCPUFrameTime * MILLISECONDS_PER_SECOND)
		end
		lastFrameStart = frameStart

		if frame >= warmup + frames then
			connection:Disconnect()
			task.spawn(waitingThread)
		end
	end)

	coroutine.yield()

	return {
		Script = summarize(scriptTimes),
		Frame = summarize(frameTimes),
		PhysicsJob = summarize(physicsTimes),
		Heartbeat = summarize(heartbeatTimes),
		RenderCpu = summarize(renderTimes),
	}
end

--[[
	Times pure-Luau alternatives against each other and returns nanoseconds per iteration.

	Each case receives the iteration count, runs its own loop, and returns something computed
	from the work, so the compiler cannot drop the loop as unused. Cases run in a shuffled order
	every round, so drift and one-off stalls land on all of them.
]]
function Module.compare(cases: { [string]: Case }, options: CompareOptions?): CompareResult
	local resolved: CompareOptions = options or {}
	local iterations = resolved.Iterations or DEFAULT_ITERATIONS
	local samples = resolved.Samples or DEFAULT_SAMPLES
	local rounds = resolved.Rounds or DEFAULT_ROUNDS
	assert(iterations >= 1 and samples >= 1 and rounds >= 1, "Counts must be at least 1")

	local names = {}
	local timings: { [string]: { number } } = {}
	for name, case in cases do
		table.insert(names, name)
		timings[name] = {}
		case(iterations)
	end

	local random = Random.new()
	for _ = 1, rounds do
		random:Shuffle(names)
		for _, name in names do
			local case = cases[name]
			for _ = 1, samples do
				local start = os.clock()
				case(iterations)
				local seconds = os.clock() - start
				table.insert(timings[name], seconds / iterations * NANOSECONDS_PER_SECOND)
			end
		end
	end

	local results: CompareResult = {}
	for name, caseTimings in timings do
		results[name] = summarize(caseTimings)
	end

	return results
end

--[[
	Returns memory in megabytes for every DeveloperMemoryTag, keyed by tag name.
]]
function Module.readMemory(): { [string]: number }
	local snapshot = {}
	for _, tag in Enum.DeveloperMemoryTag:GetEnumItems() do
		snapshot[tag.Name] = Stats:GetMemoryUsageMbForTag(tag)
	end

	return snapshot
end

--[[
	Describes what changed between two readMemory snapshots as bytes per item, leaving out tags
	that moved by less than MinimumBytes per item.
]]
function Module.formatMemoryDelta(
	before: { [string]: number },
	after: { [string]: number },
	options: MemoryDeltaOptions
): string
	local minimumBytes = options.MinimumBytes or DEFAULT_MINIMUM_BYTES
	assert(options.ItemCount >= 1, "ItemCount must be at least 1")

	local parts = {}
	for name, megabytes in after do
		local bytesPerItem = (megabytes - before[name]) * BYTES_PER_MB / options.ItemCount
		if math.abs(bytesPerItem) >= minimumBytes then
			table.insert(parts, string.format("%s %.0f", name, bytesPerItem))
		end
	end
	table.sort(parts)

	return table.concat(parts, " | ")
end

--[[
	Returns the mean of Stats.DataSendKbps over the given time, in kilobytes per second.
]]
function Module.measureSendRateAsync(seconds: number): number
	assert(seconds > 0, "seconds must be positive")

	local sum, count = 0, 0
	local deadline = os.clock() + seconds
	repeat
		RunService.Heartbeat:Wait()
		sum += Stats.DataSendKbps
		count += 1
	until os.clock() >= deadline

	return sum / count
end

--[[
	Formats a frame result as one line of median/p90/mean values in milliseconds.
]]
function Module.formatFrames(label: string, result: FrameResult): string
	return string.format(
		"%s | %s | %s | %s | %s | %s",
		label,
		formatSummary("script", result.Script),
		formatSummary("frame", result.Frame),
		formatSummary("physicsJob", result.PhysicsJob),
		formatSummary("heartbeat", result.Heartbeat),
		formatSummary("renderCpu", result.RenderCpu)
	)
end

--[[
	Formats a compare result as one line per case of median/p90/mean nanoseconds.
]]
function Module.formatCompare(results: CompareResult): string
	local names = {}
	for name in results do
		table.insert(names, name)
	end
	table.sort(names)

	local lines = {}
	for _, name in names do
		table.insert(lines, formatSummary(name, results[name]) .. " ns")
	end

	return table.concat(lines, "\n")
end

return Module
