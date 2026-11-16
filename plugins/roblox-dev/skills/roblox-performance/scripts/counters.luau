-- Usage: lute counters.luau <file.gprx> [text]
-- Prints every counter whose path contains <text> (plain text, any case; no $ or * masks), with
-- its first and last sample. Counter paths look like memory/physics/contacts and
-- instance_count/part. Leave out <text> to list every counter.
local process = require("@lute/process")
local LibMP = require("./LibMP")

local path = process.args[2]
if not path then
	print("Usage: lute counters.luau <file.gprx> [text]")
	return
end
local mask = string.lower(process.args[3] or "")

local session = LibMP.Session.OpenFromFile(path)
assert(session, "could not open " .. path)

local iter = session:CreateCounterIterator()
local state = iter:GetState()
iter:Configure({ RootCounterIds = {} })
while iter:Step() do
	local id = state:CounterId()
	local parts = {}
	for i = 0, state:Level() do
		local elementId = iter:GetStackElement(i)
		table.insert(parts, session:FetchCounterDesc(elementId).CounterName)
	end
	local full = table.concat(parts, "/")
	if mask == "" or string.find(string.lower(full), mask, 1, true) then
		local samples = session:FetchCounterSamples(id)
		if #samples > 0 then
			print(("%-70s first %.10g  last %.10g  (%d samples)"):format(full, samples[1].Value, samples[#samples].Value, #samples))
		end
	end
end
iter:Dispose()
session:Dispose()
