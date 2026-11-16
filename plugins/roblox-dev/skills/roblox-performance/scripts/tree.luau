-- Usage: lute tree.luau <file.gprx> <startFrame> <endFrame> [minMs=0.3] [maxDepth=14] [threadMask=*Worker*|*Main*]
-- Prints the call tree of scopes averaged per frame over the range: one tree per thread, except
-- that every worker thread goes into one merged tree, since engine jobs move between workers.
local process = require("@lute/process")
local LibMP = require("./LibMP")

local path = process.args[2]
local startFrame = tonumber(process.args[3])
local endFrame = tonumber(process.args[4])
local minMs = tonumber(process.args[5]) or 0.3
local maxDepth = tonumber(process.args[6]) or 14
local threadMask = process.args[7] or "*Worker*|*Main*"

local session = LibMP.Session.OpenFromFile(path)
assert(session, "could not open " .. tostring(path))

local global = session:FetchGlobalDesc()
local frameCount = endFrame - startFrame + 1

local timerNames = {}
local function timerName(id)
	local name = timerNames[id]
	if name == nil then
		local d = session:FetchTimerDesc(id)
		local group = session:FetchGroupDesc(d.GroupId)
		name = d.TimerName .. (if group then " [" .. group.GroupName .. "]" else "")
		timerNames[id] = name
	end
	return name
end

local threadIds = session:FindThreadIds(threadMask, false)
local MERGED_WORKERS = "workers, merged (roots add up across threads)"
-- The tree each thread's scopes go into: its own, or the one all worker threads share.
local treeNames = {}
for _, id in threadIds do
	local name = session:FetchThreadDesc(id).ThreadName
	treeNames[id] = if string.find(name, "Worker", 1, true) then MERGED_WORKERS else name
end

local iter = session:CreateLogIterator()
iter:Configure({
	SkipEvents = true,
	EmitThreadFrameEnd = true,
	ThreadIds = threadIds,
})

-- trees[treeName][pathKey] = { Ms, Count, Depth, Name, Parent }
local trees = {}
local function record(threadId, isGpu, pathIds, ticks)
	local treeName = treeNames[threadId] or tostring(threadId)
	local tree = trees[treeName]
	if tree == nil then
		tree = {}
		trees[treeName] = tree
	end
	local key = table.concat(pathIds, "/")
	local node = tree[key]
	if node == nil then
		local parentKey = table.concat(pathIds, "/", 1, #pathIds - 1)
		node = {
			Ms = 0,
			Count = 0,
			Depth = #pathIds,
			Name = timerName(pathIds[#pathIds]),
			ParentKey = if #pathIds > 1 then parentKey else nil,
			Key = key,
		}
		tree[key] = node
	end
	node.Ms += ticks * (if isGpu then global.TickToMsGpu else global.TickToMsCpu)
	node.Count += 1
end

local state = iter:GetState()
iter:RewindTo(math.max(session:GetFrameIdMin(), startFrame - 1), endFrame)
local pathIds = {}
local frameStart = {}

while iter:Step() do
	if state:IsFrameBoundary() then
		continue
	end
	local frameId = state:FrameId()
	if frameId < startFrame then
		continue
	end
	local threadId = state:ThreadId()
	local isGpu = state:IsGpuThread()

	if state:IsThreadFrameEnd() then
		local exitTs = state:Timestamp()
		local depth = state:ThreadStackDepth()
		for localDepth = depth - 1, 0, -1 do
			table.clear(pathIds)
			local complete = true
			for i = 0, localDepth do
				local el = iter:GetCurrentThreadStackElement(i)
				if el == nil then
					complete = false
					table.insert(pathIds, 0)
				else
					table.insert(pathIds, el:EnterTimerId())
				end
			end
			local el = iter:GetCurrentThreadStackElement(localDepth)
			if el and complete then
				record(threadId, isGpu, pathIds, exitTs - el:EnterTimestampFrameLocal())
			end
		end
	elseif state:IsExit() and not state:ThreadStackWasOverflowed() then
		local depth = state:ThreadStackDepth()
		local timerId = state:TimerId()
		local exitTs = state:Timestamp()
		if state:ThreadStackIsUnderflowed() then
			local d = session:FetchFrameDesc(frameId)
			local enterTs = if isGpu then d.TickStartGpu else d.TickStartCpu
			table.clear(pathIds)
			table.insert(pathIds, timerId)
			record(threadId, isGpu, pathIds, exitTs - enterTs)
		else
			local enterTs = iter:GetCurrentThreadStackElement(depth):EnterTimestampFrameLocal()
			table.clear(pathIds)
			local complete = true
			for i = 0, depth - 1 do
				local el = iter:GetCurrentThreadStackElement(i)
				if el == nil then
					complete = false
					table.insert(pathIds, 0)
				else
					table.insert(pathIds, el:EnterTimerId())
				end
			end
			table.insert(pathIds, timerId)
			record(threadId, isGpu, pathIds, exitTs - enterTs)
		end
	end
end

timerNames[0] = "?"

local function frameMs(id)
	local d = session:FetchFrameDesc(id)
	return (d.TickEndCpu - d.TickStartCpu) * global.TickToMsCpu
end
local totalFrame = 0
for id = startFrame, endFrame do
	totalFrame += frameMs(id)
end
print(("frames %d..%d, avg frame %.2f ms"):format(startFrame, endFrame, totalFrame / frameCount))

for treeName, tree in trees do
	local children = {}
	local roots = {}
	for key, node in tree do
		if node.ParentKey and tree[node.ParentKey] then
			children[node.ParentKey] = children[node.ParentKey] or {}
			table.insert(children[node.ParentKey], node)
		else
			table.insert(roots, node)
		end
	end
	local function byMs(a, b)
		return a.Ms > b.Ms
	end
	table.sort(roots, byMs)
	local total = 0
	for _, r in roots do
		total += r.Ms
	end
	if total / frameCount < minMs then
		continue
	end
	print(("\n== %s (roots %.2f ms/frame) =="):format(treeName, total / frameCount))
	local function walk(node, indent)
		local avg = node.Ms / frameCount
		if avg < minMs or indent > maxDepth then
			return
		end
		local kids = children[node.Key] or {}
		local childMs = 0
		for _, k in kids do
			childMs += k.Ms
		end
		print(("%s%7.2f ms (self %.2f, n=%.1f/f)  %s"):format(string.rep("  ", indent), avg, (node.Ms - childMs) / frameCount, node.Count / frameCount, node.Name))
		table.sort(kids, byMs)
		for _, k in kids do
			walk(k, indent + 1)
		end
	end
	for _, r in roots do
		walk(r, 0)
	end
end

iter:Dispose()
session:Dispose()
