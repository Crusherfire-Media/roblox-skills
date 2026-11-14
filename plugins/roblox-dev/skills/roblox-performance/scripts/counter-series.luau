-- Usage: lute counter-series.luau <file.gprx> <counter mask> [every=25]
-- Prints the matched counter's path, then its samples as frame:value, every Nth one plus the last.
-- Pass 1 to print all. The mask is LibMP's counter search, where $ anchors the end, such as
-- "instance_count/part$" or "memory/physics/broadphase$".
local process = require("@lute/process")
local LibMP = require("./LibMP")

local path = process.args[2]
local mask = process.args[3]
if not path or not mask then
	print("Usage: lute counter-series.luau <file.gprx> <counter mask> [every=25]")
	return
end

local session = LibMP.Session.OpenFromFile(path)
assert(session, "could not open " .. path)
local id = session:FindCounterId(mask, false)
assert(id ~= 0, "no counter " .. mask)

-- A loose mask matches the first counter it finds, so show which one that was.
local names = {}
local walk = id
while walk ~= 0 do
	local desc = session:FetchCounterDesc(walk)
	table.insert(names, 1, desc.CounterName)
	walk = desc.Parent
end
print(table.concat(names, "/"))

local every = tonumber(process.args[4]) or 25
local samples = session:FetchCounterSamples(id)
local line = {}
for index, sample in samples do
	if every <= 1 or index % every == 1 or index == #samples then
		table.insert(line, ("%d:%.10g"):format(sample.FrameId, sample.Value))
	end
end
print(table.concat(line, "  "))
session:Dispose()
