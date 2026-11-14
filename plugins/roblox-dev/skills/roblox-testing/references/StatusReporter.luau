--!strict
--@author: #Author
--@date: #Date
--[[@description:
	Jest reporter for the Output window: a green or red circle per spec file as it finishes, each
	failing test and Jest's failure details under a red file, and a summary line at the end.
]]
-----------------------------
-- TYPES --
-----------------------------
type TestCaseResult = {
	title: string,
	status: string,
}

type TestResult = {
	testFilePath: string,
	numPassingTests: number?,
	numFailingTests: number?,
	testExecError: any?,
	failureMessage: string?,
	testResults: { TestCaseResult },
}

type AggregatedResult = {
	numPassedTests: number,
	numFailedTests: number,
	numPendingTests: number,
	numTotalTestSuites: number,
	numRuntimeErrorTestSuites: number,
	snapshot: { failure: boolean },
}

-----------------------------
-- VARIABLES --
-----------------------------
const PASS = "🟢"
const FAIL = "🔴"

local Module = {}
Module.__index = Module

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------

--[[
	Jest builds the reporter with its global config and the reporter's options from jest.config;
	neither is needed here.
]]
function Module.new(_globalConfig: any, _options: any)
	return setmetatable({}, Module)
end

--[[
	Prints one spec file's result when the file finishes. A file whose tests were all filtered out
	prints nothing.
]]
function Module:onTestResult(_test: any, result: TestResult, _aggregated: any)
	local passed = result.numPassingTests or 0
	local failed = result.numFailingTests or 0

	if result.testExecError ~= nil then
		print(`{FAIL} {result.testFilePath} (failed to load)\n{result.failureMessage or ""}`)
		return
	end

	if failed > 0 then
		local lines = { `{FAIL} {result.testFilePath} ({passed}/{passed + failed})` }
		for _, testCase in result.testResults do
			if testCase.status == "failed" then
				table.insert(lines, `   {FAIL} {testCase.title}`)
			end
		end
		table.insert(lines, result.failureMessage or "")
		print(table.concat(lines, "\n"))
		return
	end

	if passed > 0 then
		print(`{PASS} {result.testFilePath} ({passed})`)
	end
end

--[[
	Prints the run's summary line.
]]
function Module:onRunComplete(_contexts: any, results: AggregatedResult)
	local counts = { `{results.numPassedTests} passed`, `{results.numFailedTests} failed` }
	if results.numPendingTests > 0 then
		table.insert(counts, `{results.numPendingTests} skipped`)
	end
	if results.numRuntimeErrorTestSuites > 0 then
		table.insert(counts, `{results.numRuntimeErrorTestSuites} failed to load`)
	end
	-- Jest sets results.success only after every reporter's onRunComplete returns.
	local hasFailed = results.numFailedTests > 0
		or results.numRuntimeErrorTestSuites > 0
		or results.snapshot.failure
	local status = if hasFailed then FAIL else PASS
	print(`{status} {table.concat(counts, ", ")} ({results.numTotalTestSuites} files)`)
end

-----------------------------
-- MAIN --
-----------------------------
return Module
