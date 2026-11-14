-- Usage: lute overview.luau <file.gprx> [topN]
local process = require("@lute/process")
local LibMP = require("./LibMP")

local path = process.args[2]
local topN = tonumber(process.args[3]) or 12

local session = LibMP.Session.OpenFromFile(path)
assert(session, "could not open " .. tostring(path))

local tickToMs = session:FetchGlobalDesc().TickToMsCpu
local minId, maxId = session:GetFrameIdMin(), session:GetFrameIdMax()
print(("frames %d..%d (%d)"):format(minId, maxId, maxId - minId + 1))

local threads = session:FetchThreadIds()
local names = {}
for _, id in threads do
	local d = session:FetchThreadDesc(id)
	table.insert(names, ("%d:%s"):format(id, d.ThreadName))
end
print("threads: " .. table.concat(names, ", "))

local frames = {}
for id = minId, maxId do
	local d = session:FetchFrameDesc(id)
	if not d.IsIncomplete then
		table.insert(frames, {
			Id = id,
			Abs = d.FrameAbsoluteId,
			Ms = (d.TickEndCpu - d.TickStartCpu) * tickToMs,
			Start = d.TickStartCpu,
		})
	end
end

local sorted = table.clone(frames)
table.sort(sorted, function(a, b)
	return a.Ms < b.Ms
end)
local function pct(p)
	return sorted[math.max(1, math.ceil(#sorted * p))].Ms
end
local sum = 0
for _, f in frames do
	sum += f.Ms
end
print(("p50 %.2f  p90 %.2f  p99 %.2f  max %.2f  avg %.2f ms"):format(pct(0.5), pct(0.9), pct(0.99), sorted[#sorted].Ms, sum / #frames))

local t0 = frames[1].Start
print("\nlongest frames (id/abs, ms, seconds into dump):")
for i = #sorted, math.max(1, #sorted - topN + 1), -1 do
	local f = sorted[i]
	print(("  %d/%d  %.2f ms  t=%.2fs"):format(f.Id, f.Abs, f.Ms, (f.Start - t0) * tickToMs / 1000))
end

-- A strip of every frame time, to see clusters.
local line = {}
for _, f in frames do
	table.insert(line, ("%d:%.0f"):format(f.Id, f.Ms))
end
print("\nall frames (id:ms):")
for i = 1, #line, 16 do
	print("  " .. table.concat(line, " ", i, math.min(#line, i + 15)))
end

session:Dispose()
