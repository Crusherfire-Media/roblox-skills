-- Usage: lute series.luau <file.gprx> <startFrame> <endFrame> <timerMask1|timerMask2|...>
-- Per frame: frame ms, then for each matched timer the outermost-inclusive ms and call count, across all threads.
local process = require("@lute/process")
local LibMP = require("./LibMP")

local path = process.args[2]
local startFrame = tonumber(process.args[3])
local endFrame = tonumber(process.args[4])
local masks = string.split(process.args[5], "|")

local session = LibMP.Session.OpenFromFile(path)
assert(session, "could not open " .. tostring(path))
local global = session:FetchGlobalDesc()

local columns = {}
local columnOf = {}
for _, mask in masks do
	local ids = session:FindTimerIds(mask, false)
	local column = { Mask = mask }
	table.insert(columns, column)
	for _, id in ids do
		columnOf[id] = column
	end
end

local perFrame = {}
local iter = session:CreateLogIterator()
iter:Configure({
	SkipEvents = true,
	SkipGpuThreads = true,
	EmitThreadFrameEnd = true,
})
local state = iter:GetState()
iter:RewindTo(math.max(session:GetFrameIdMin(), startFrame - 1), endFrame)

local function add(frameId, column, ticks, isExit)
	local row = perFrame[frameId]
	if row == nil then
		row = {}
		perFrame[frameId] = row
	end
	local cell = row[column]
	if cell == nil then
		cell = { Ms = 0, Count = 0 }
		row[column] = cell
	end
	cell.Ms += ticks * global.TickToMsCpu
	if isExit then
		cell.Count += 1
	end
end

-- True when an outer stack element belongs to the same column, so nested repeats are not double counted.
local function nestedInSame(column, depth)
	for i = 0, depth - 1 do
		local el = iter:GetCurrentThreadStackElement(i)
		if el and columnOf[el:EnterTimerId()] == column then
			return true
		end
	end
	return false
end

while iter:Step() do
	if state:IsFrameBoundary() then
		continue
	end
	local frameId = state:FrameId()
	if frameId < startFrame then
		continue
	end
	if state:IsThreadFrameEnd() then
		local exitTs = state:Timestamp()
		local depth = state:ThreadStackDepth()
		for localDepth = 0, depth - 1 do
			local el = iter:GetCurrentThreadStackElement(localDepth)
			if el then
				local column = columnOf[el:EnterTimerId()]
				if column and not nestedInSame(column, localDepth) then
					add(frameId, column, exitTs - el:EnterTimestampFrameLocal(), false)
				end
			end
		end
	elseif state:IsExit() and not state:ThreadStackWasOverflowed() then
		local column = columnOf[state:TimerId()]
		if column then
			local depth = state:ThreadStackDepth()
			if state:ThreadStackIsUnderflowed() then
				local d = session:FetchFrameDesc(frameId)
				add(frameId, column, state:Timestamp() - d.TickStartCpu, true)
			elseif not nestedInSame(column, depth) then
				local el = iter:GetCurrentThreadStackElement(depth)
				add(frameId, column, state:Timestamp() - el:EnterTimestampFrameLocal(), true)
			end
		end
	end
end

local header = { "frame", "ms" }
for _, c in columns do
	table.insert(header, c.Mask)
end
print(table.concat(header, " | "))
for id = startFrame, endFrame do
	local d = session:FetchFrameDesc(id)
	local cells = { tostring(id), ("%.1f"):format((d.TickEndCpu - d.TickStartCpu) * global.TickToMsCpu) }
	local row = perFrame[id] or {}
	for _, c in columns do
		local cell = row[c]
		table.insert(cells, if cell then ("%.2f/%d"):format(cell.Ms, cell.Count) else "-")
	end
	print(table.concat(cells, " | "))
end

iter:Dispose()
session:Dispose()
