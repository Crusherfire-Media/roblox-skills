--[[
	Dev-only frame report, run by the debug panel's "Frame report" button during a playtest. For
	each recent frame it returns the frame time, the time the main thread spent in the Physics
	group, the GPU time, and the five scopes that took longest on the main thread. It also returns
	the Luau heap size at the end of the capture.
]]

local LibMP = require(script.Parent.LibMPLoader)
local FpsOverlay = require(script.Parent.FpsOverlay)

local REPORT_FRAMES = 120
local TOP_SCOPES = 5

export type ScopeTime = {
	Name: string,
	Ms: number,
}

export type FrameRow = {
	FrameId: number,
	FrameMs: number,
	GpuMs: number,
	PhysicsMs: number,
	TopScopes: { ScopeTime },
}

export type Report = {
	Frames: { FrameRow },
	LuauHeap: number?,
}

local FrameReport = {}

local function scopeName(session: any, timerId: number): string
	local timer = session:GetTimerDesc(timerId)
	local group = session:FetchGroupDesc(timer:GroupId())
	return `{timer:TimerName()} [{group.GroupName}]`
end

function FrameReport.run(): Report
	-- Hold the data still while we read it, and keep enough frames for the report.
	LibMP.Control:EnableCapture(false)
	LibMP.Control:SetFrameLimit(256)

	local session = FpsOverlay.getSession() or LibMP.Session.OpenFromLiveData()
	assert(session, "could not open the MicroProfiler data")
	local global = session:FetchGlobalDesc()
	local lastId = session:GetFrameIdMax()
	local firstId = math.max(session:GetFrameIdMin(), lastId - REPORT_FRAMES + 1)

	local rows: { [number]: FrameRow } = {}
	local scopeMs: { [number]: { [number]: number } } = {}
	for frameId = firstId, lastId do
		local frame = session:FetchFrameDesc(frameId)
		rows[frameId] = {
			FrameId = frameId,
			FrameMs = (frame.TickEndCpu - frame.TickStartCpu) * global.TickToMsCpu,
			GpuMs = (frame.TickEndGpu - frame.TickStartGpu) * global.TickToMsCpu,
			PhysicsMs = 0,
			TopScopes = {},
		}
		scopeMs[frameId] = {}
	end

	local iter = session:CreateLogIterator()
	local state = iter:GetState()
	local mainThreadId = session:FindThreadId("Main")
	iter:Configure({
		SkipEvents = true,
		ThreadIds = { mainThreadId },
	})
	iter:RewindTo(firstId, lastId)

	while iter:Step() do
		if
			state:IsExit()
			and not state:ThreadStackIsUnderflowed()
			and not state:ThreadStackWasOverflowed()
		then
			local row = rows[state:FrameId()]
			if row then
				local element = iter:GetCurrentThreadStackElement(state:ThreadStackDepth())
				local ms = (state:Timestamp() - element:EnterTimestamp()) * global.TickToMsCpu
				local timerId = state:TimerId()
				local frameScopes = scopeMs[row.FrameId]
				frameScopes[timerId] = (frameScopes[timerId] or 0) + ms
				if session:FetchTimerDesc(timerId).GroupId == session:FindGroupId("Physics") then
					row.PhysicsMs += ms
				end
			end
		end
	end

	local frames: { FrameRow } = {}
	for frameId = firstId, lastId do
		local row = rows[frameId]
		local scopes: { ScopeTime } = {}
		for timerId, ms in scopeMs[frameId] do
			table.insert(scopes, { Name = scopeName(session, timerId), Ms = ms })
		end
		table.sort(scopes, function(a, b)
			return a.Ms > b.Ms
		end)
		for index = 1, math.min(TOP_SCOPES, #scopes) do
			table.insert(row.TopScopes, scopes[index])
		end
		table.insert(frames, row)
	end

	local heapId = session:FindCounterId("**/Luau/heap")
	local heapSamples = session:GetCounterSamples(heapId)
	local lastHeapSample = heapSamples:FetchLastSample()

	iter:Dispose()
	session:Dispose()

	return {
		Frames = frames,
		LuauHeap = if lastHeapSample then lastHeapSample.Value else nil,
	}
end

return FrameReport
