--!strict
--@author: Crusherfire
--@date: 11/13/26
--[[@description:
	The script a Luau Execution task runs in the CI place. It runs every spec
	in ServerScriptService.Tests.Specs and errors when one fails, because a
	task only ends FAILED on an unhandled error. tools/ci/run-tests sends it.
]]

------------------------------
-- SERVICES --
------------------------------
local ServerScriptService = game:GetService("ServerScriptService")

------------------------------
-- VARIABLES --
------------------------------
local MAX_MESSAGE_LENGTH = 1500
local MAX_LISTED_FAILURES = 20

local tests = ServerScriptService:WaitForChild("Tests")
local specs = tests:WaitForChild("Specs")

------------------------------
-- PRIVATE FUNCTIONS --
------------------------------
local function clean(message: string): string
	-- Jest colors its output with ANSI escapes, which the logs show as noise.
	local plain = string.gsub(message, "\27%[[%d;]*m", "")
	return string.sub(plain, 1, MAX_MESSAGE_LENGTH)
end

------------------------------
-- MAIN --
------------------------------
local Jest = require(tests:WaitForChild("Packages"):WaitForChild("Jest")) :: any
local status, result = Jest.runCLI(specs, { ci = true, verbose = false }, { specs }):awaitStatus()
if status ~= "Resolved" then
	local reason = if typeof(result) == "table" then result.message else result
	error(`Jest did not finish: {clean(tostring(reason))}`)
end

local results = result.results
local failures = {}
for _, file in results.testResults do
	if file.testExecError ~= nil then
		table.insert(failures, `LOAD ERROR {file.testFilePath}\n{clean(file.failureMessage or "")}`)
		continue
	end
	for _, test in file.testResults do
		if test.status == "failed" then
			local message = clean(test.failureMessages[1] or "")
			table.insert(failures, `FAIL {file.testFilePath} > {test.fullName}\n{message}`)
		end
	end
end

local summary =
	`{results.numTotalTestSuites} spec files, {results.numPassedTests} passed, {results.numFailedTests} failed`
if not results.success then
	local listed = table.concat(failures, "\n\n", 1, math.min(#failures, MAX_LISTED_FAILURES))
	if #failures == 0 then
		listed =
			"Jest reported a failure without a failing test (no spec matched, or a snapshot is obsolete)."
	end
	error(`{summary}\n\n{listed}`)
end

return summary
