# Running specs in Studio

Specs run in the edit DataModel of the open place. Any Studio MCP that can run Luau in the edit
session can run them: send the script below, with the filters set, and read the table it returns.
When the connected MCP has its own run-the-specs action, use it with the same filters and read its
result the same way.

Before a run:

- No playtest is running: edit-mode actions fail or target the wrong DataModel while one runs.
- In a Rojo repo, the spec and the code under test are saved and synced, and `rojo serve` is still
  running (the `rojo-workflow` skill's Changing code steps).
- When several Studio windows are connected, the run targets the place whose code you changed.

## The runner

```lua
local ServerScriptService = game:GetService("ServerScriptService")

-- Regex on spec paths such as "Specs/DataCatalogs/FoodCatalog.spec", or nil for every spec.
local PATH_PATTERN = "Specs/DataCatalogs/FoodCatalog"
-- Regex on the describe chain plus the test name, or nil for every test.
local NAME_PATTERN = nil

local Tests = ServerScriptService:FindFirstChild("Tests")
local Jest = Tests and Tests:FindFirstChild("Packages") and Tests.Packages:FindFirstChild("Jest")
local root = Tests and Tests:FindFirstChild("Specs")
if not Jest or not root or not root:FindFirstChild("jest.config") then
	return { setupError = "Tests.Packages.Jest or Tests.Specs['jest.config'] is missing" }
end

local status, result = require(Jest).runCLI(root, {
	ci = false,
	verbose = false,
	testPathPattern = PATH_PATTERN,
	testNamePattern = NAME_PATTERN,
}, { root }):awaitStatus()

if status == "Rejected" then
	return { runnerError = tostring(result) }
end

local results = result.results
local summary = {
	success = results.success,
	passed = results.numPassedTests,
	failed = results.numFailedTests,
	filesFailedToLoad = results.numRuntimeErrorTestSuites,
	failures = {},
	loadErrors = {},
}
for _, file in results.testResults do
	if file.testExecError ~= nil then
		table.insert(summary.loadErrors, { file = file.testFilePath, message = file.failureMessage })
	end
	for _, case in file.testResults do
		if case.status == "failed" then
			table.insert(summary.failures, {
				file = file.testFilePath,
				test = case.fullName,
				message = table.concat(case.failureMessages or {}, "\n"),
			})
		end
	end
end
if results.numTotalTests == 0 then
	summary.note = "No test ran: no spec matched the filters, or no spec exists yet."
end
return summary
```

Adjust the `Tests` path when the place keeps its specs elsewhere (read `jest.config`'s location).

## Reading the result

- `success` is true only when every test passed and every spec file loaded.
- `passed` and `failed` count test cases: every row of an `it.each` counts as its own test.
- `failures` lists each failing test with its file, full name, and Jest's failure message. The
  last frame of the message usually points at the spec line.
- `loadErrors` lists spec files that never ran. A syntax error or an error at require time names
  the module and line. In a Rojo repo, a module reported missing usually means the sync hasn't
  happened yet or `rojo serve` stopped.
- `note` explains an empty run.
- `runnerError` means Jest itself failed (an invalid config, say); `setupError` means Jest isn't
  installed in the place (follow [setup.md](setup.md)).

Jest also prints its own report to the Output window. With the `StatusReporter` from
[setup.md](setup.md) installed, it prints a green or red circle per spec file instead, which you
can read from the output log when a run's returned table is cut short.

## Filters

- `PATH_PATTERN` is a regex matched against each spec's path. One spec:
  `"Specs/DataCatalogs/FoodCatalog"`. A folder: `"Specs/Integration/"`. Several specs:
  `"FoodCatalog|IngredientCatalog"`.
- `NAME_PATTERN` is a regex matched against the test's full name, the `describe` chain plus the
  `it` title.
- Both are regexes: `.` matches any character, and `"\\."` in the Luau string
  matches a literal dot.

A long run can outlast the MCP's time limit for one call. Run the suite in batches by folder
(`Specs/<Folder>/`) instead.
