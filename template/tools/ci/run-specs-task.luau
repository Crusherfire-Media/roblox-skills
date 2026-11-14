--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local tests = ServerScriptService:WaitForChild("Tests")
local Jest = require(tests:WaitForChild("Packages"):WaitForChild("Jest")) :: any

local MAX_MESSAGE_LENGTH = 1500
local MAX_LISTED_FAILURES = 20

local specs = tests:WaitForChild("Specs")

local function clean(message: string): string
	-- Jest colors its output with ANSI escapes, which the logs show as noise.
	local plain = string.gsub(message, "\27%[[%d;]*m", "")
	return string.sub(plain, 1, MAX_MESSAGE_LENGTH)
end

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
-- A task ends FAILED only on an unhandled error, so a failing spec has to error.
if not results.success then
	local listed = table.concat(failures, "\n\n", 1, math.min(#failures, MAX_LISTED_FAILURES))
	if #failures == 0 then
		listed =
			"Jest reported a failure without a failing test (no spec matched, or a snapshot is obsolete)."
	end
	error(`{summary}\n\n{listed}`)
end

return summary
