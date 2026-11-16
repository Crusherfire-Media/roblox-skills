# Jest Roblox 3.20 reference

Only what differs from JS Jest 27 or is Roblox-specific. JS Jest APIs missing from the Jest Roblox docs are listed at the end; do not assume they exist.

## Running in Studio

```lua
local status, result = Jest.runCLI(root, {
	verbose = true,
	ci = false,
}, { root }):awaitStatus()

if status == "Rejected" then
	error(result)
end

if not result.results.success then
	error("Tests failed")
end
```

- The Studio runner in [running-in-studio.md](running-in-studio.md) and the CI entry script in [ci.md](ci.md) both call `runCLI` this way. `Jest` is the `Jest` package (installed next to `JestGlobals`). `root` is the Instance holding `jest.config`. The third argument lists the project roots, which are Instances that each hold a `jest.config`.
- No fast flag is needed. Without `debug.loadmodule`, Jest loads each module with `loadstring(Source)`.
- `Rejected` means the runner itself failed (for example, an invalid config). A run with failing tests still resolves, with `result.results.success == false`.

## Spec file skeleton

```lua
const JestGlobals = require("@game/ServerScriptService/Tests/Packages/JestGlobals")
const describe = JestGlobals.describe
const it = JestGlobals.it
const expect = JestGlobals.expect
const jest = JestGlobals.jest
const beforeEach = JestGlobals.beforeEach

const Inventory = require("@game/ServerScriptService/Modules/Utilities/Inventory")

describe("Inventory", function()
	local inventory

	beforeEach(function()
		inventory = Inventory.new()
	end)

	it("stacks identical items", function()
		inventory:Add("Arrow", 5)

		inventory:Add("Arrow", 3)

		expect(inventory:GetCount("Arrow")).toBe(8)
	end)
end)
```

- A spec is a ModuleScript whose name ends in `.spec`. This project's `jest.config` sets `testMatch = { "**/*.spec" }`. A spec needs no `return`.
- There are no test globals. Require every name you use from `JestGlobals`: `describe`, `it`, `test`, `expect`, `jest`, `beforeEach`, `afterEach`, `beforeAll`, `afterAll`, and aliases such as `fit`, `xit`, `xtest`, `fdescribe`, `xdescribe`.
- Call matchers and mock methods with `.`, never `:`. Examples: `expect(x).toBe(y)`, `mock.mockReturnValue(1)`.
- Jest-defined keys keep Jest's names: config and `runCLI` options, `{ pass, message }` from matchers, and `{ type, value }` in `mock.results`. The PascalCase-key rule covers only your own tables.

### `require` inside specs

- Jest sandboxes `require`. It accepts ModuleScript instances and string paths: `./X` for a sibling, `../X` for the parent's sibling, `@self/X` for a child, and `@game/...` for an absolute path. `..` in the middle of a path (`./A/../B`) is not supported.
- Each spec file gets fresh module instances loaded from `Source`. Module state never leaks between spec files, and a spec never shares module instances with the running game. Inside one file, the registry lasts across tests. Use `jest.resetModules()` or `jest.isolateModules()` to get a fresh copy per test.

## Deviations that JS habits get wrong

### Globals

- `.each` has no tagged templates. It is curried as `(name, fn, timeout?)` and has three forms:

```lua
-- Keyed rows: fn gets one table, and names interpolate $Key.
test.each({
	{ A = 1, B = 1, Sum = 2 },
	{ A = 2, B = 1, Sum = 3 },
})("$A + $B = $Sum", function(row)
	expect(row.A + row.B).toBe(row.Sum)
end)

-- Heading string (or { "A | B | Sum" }) followed by rows as varargs: fn gets one table.
test.each("A | B | Sum",
	{ 1, 1, 2 },
	{ 2, 1, 3 }
)("$A + $B = $Sum", function(row)
	expect(row.A + row.B).toBe(row.Sum)
end)
```

  The third form passes rows as arrays: `test.each({ { 1, 1, 2 } })(name, function(a, b, sum) ... end)` receives positional arguments. A flat list `{ 1, 2 }` becomes `{ { 1 }, { 2 } }`. `describe.each`, `.only.each` and `.skip.each` take the same forms.
- `test.failing`, `test.only.failing` and `test.skip.failing` exist. `test.todo(name)` throws if you pass it a callback.

### Expect

- `.never` replaces `.not`, which is a reserved word. It also works on asymmetric matchers: `expect.never.arrayContaining`, `expect.never.objectContaining`, `expect.never.stringContaining` and `expect.never.stringMatching`. Their aliases are `expect.arrayNotContaining`, `objectNotContaining`, `stringNotContaining` and `stringNotMatching`.
- Truthiness follows Lua: only `false` and `nil` are falsy. `expect(0).toBeFalsy()` fails, and `expect(0).toBeTruthy()` passes.
- Use `toBeNil()` and `never.toBeNil()`. `toBeNull` and `toBeUndefined` are identical to `toBeNil`, and `toBeDefined` is identical to `never.toBeNil`.
- `toHaveLength(n)` uses the `#` operator, or the table's `.length` field if it has one. Dictionaries report 0. It cannot check a function's argument count.
- `toMatch(p)` and `expect.stringMatching(p)` treat a string argument as a **Lua pattern**, so `.`, `%`, `-` and other magic characters need escaping with `%`. For a literal substring, use `toContain`. For a real regex, pass `RegExp("...")` from the separate LuauRegExp package (`roblox/regexp`).
- `toContain` checks arrays with `table.find` (identity) and strings with a plain `string.find`. Use `toContainEqual` for a deep comparison.
- `expect.any("number")` takes a typename string and compares it against `typeof(received)`, so Roblox types work: `expect.any("Vector3")`, `expect.any("Instance")`, `expect.any("DateTime")`. A table argument is treated as a prototype class and checked with LuauPolyfill `instanceof`.
- `expect.nothing()` matches only `nil`. Use it inside `toEqual`, `toMatchObject` or `toHaveBeenCalledWith` to assert that a key or argument is absent. `expect.anything()` matches anything except `nil`.
- `expect.callable()` matches functions, callable tables and callable userdata. Prefer it to `expect.any("function")`, which rejects callable tables such as `jest.fn()` mocks.
- `toStrictEqual` is `toEqual` plus a type check based on metatable inheritance. It does **not** check array sparseness or undefined keys.
- `toBeInstanceOf(Class)` uses LuauPolyfill `instanceof` against a metatable prototype. Give the class a `__tostring` for readable failure messages.
- `toThrow(arg?)` needs the call wrapped in a function. A string argument means the message contains that substring. A `RegExp` means the message matches. A LuauPolyfill `Error` object means the message is equal. An `Error` class means the error is an instance of it. `toEqual` compares two `Error`s by `message` only.
- `toBeNan` has the alias `toBeNaN`. Numeric indexes count from 1: `toHaveProperty({ "Items", 1 })`, `toHaveBeenNthCalledWith(1, ...)`, `toHaveNthReturnedWith(1, ...)`.
- `toMatchInstance(tbl)` is Roblox-only. It matches an Instance's properties. A nested table keyed by a child's `Name` matches that child. `ClassName` is optional; leave it out to match any class.

```lua
expect(shopFrame).toMatchInstance({
	ClassName = "Frame",
	Visible = true,
	Title = { ClassName = "TextLabel", Text = "Shop" },
})
```

- Custom matchers always take `self` (the matcher context) as their first parameter; name it `_` if you don't use it. `self` provides `self.isNot`, `self.equals(a, b)` and `self.utils` (`matcherHint`, `printExpected`, `printReceived`). An extended matcher also works as an asymmetric matcher: `expect.toBeWithinRange(1, 10)` and `expect.never.toBeWithinRange(11, 20)`.

```lua
expect.extend({
	toBeWithinRange = function(self, received, floor, ceiling)
		local pass = received >= floor and received <= ceiling
		return {
			pass = pass,
			message = function()
				local verb = if self.isNot then "not to be" else "to be"
				return `expected {received} {verb} within {floor}..{ceiling}`
			end,
		}
	end,
})
```

## Mocking

### `jest.fn`

```lua
local mock, mockFn = jest.fn()
mock.mockReturnValue(true)

Shop.purchase("Sword", mockFn)

expect(mock).toHaveBeenCalledWith("Sword")
expect(mock.mock.calls[1][1]).toBe("Sword")
```

- `jest.fn(impl?)` returns two values: `mock`, a callable table, and `mockFn`, a real function that forwards to `mock`. Configure and assert on `mock`. Pass `mockFn` wherever the code needs a real function, such as `typeof(f) == "function"` checks or `:Connect`. Calls made through either one are recorded on `mock`.
- Capture both values from the `jest.fn(...)` call, then configure `mock` in separate statements. A chain like `jest.fn().mockReturnValue(1)` gives you the mock only.
- `mock.new(...)` is the equivalent of JS `new mockFn()`. The instances it creates are recorded in `mock.mock.instances`.
- Documented state: `mock.calls` (1-based, so `mock.calls[1][1]` is the first argument of the first call), `mock.results` (entries of `{ type = "return" | "throw" | "incomplete", value }`), `mock.instances` and `mock.lastCall`.
- A call through `jest.fn` or `jest.spyOn` returns only the FIRST value of its implementation (verified in Studio). A stub whose caller reads `ok, reason` needs a plain function that records its calls, or a wrapper that returns every value.
- Documented methods: `mockImplementation`, `mockImplementationOnce`, `mockReturnValue`, `mockReturnValueOnce`, `mockReturnThis`, `mockName`, `getMockName`, `mockClear`, `mockReset` and `mockRestore`. `mockRestore` works only on `spyOn` mocks. `mockClear` and `mockReset` replace the `mock.mock` table, so do not hold on to it.
- `jest.clearAllMocks()`, `jest.resetAllMocks()` and `jest.restoreAllMocks()` behave as in JS. `restoreAllMocks` affects `spyOn` mocks only.

### `jest.spyOn`

- `jest.spyOn(object, "method")` calls the original by default. Override it with `.mockImplementation(...)`, and restore it with `spy.mockRestore()`. The `accessType` third argument is not supported.
- Assert on the spy that `spyOn` returns, not on `object.method`. With `oldFunctionSpying = false`, `object.method` becomes a plain function that is not equal to the spy. With `true`, it becomes the mock table itself.

### Module mocks

```lua
beforeEach(function()
	jest.resetModules()
	jest.mock("@game/ServerScriptService/Modules/Utilities/DataStoreWrapper", function()
		return {
			load = jest.fn(function()
				return { Coins = 10 }
			end),
		}
	end)
end)

it("reads saved coins", function()
	const PlayerData = require("@game/ServerScriptService/Modules/Utilities/PlayerData")
	expect(PlayerData.getCoins(123)).toBe(10)
end)
```

- `jest.mock(module, factory)`: the factory returns the mocked module's value, and `require` returns that value for the module. `module` is either a ModuleScript or a require-by-string path, written the same way as `require` in that spec. The mock applies only in the spec file that calls `jest.mock`. It returns `jest`.
- Nothing is hoisted. Call `jest.mock` before the `require` it should affect. The docs pair it with `jest.resetModules()` in `beforeEach` and require inside the test; in this project, install mocks before the first require of the code under test and reset only when module state must start fresh (see SKILL.md's edit-mode rules).
- `jest.unmock(module)` and `jest.requireActual(module)` accept the same two forms. `jest.isolateModules(fn)` gives the requires inside `fn` a separate registry. `jest.resetModules()` clears the registry, so the next `require` returns a new copy.
- Mocks are keyed by the ModuleScript the path resolves to (verified in Studio). A mock set by instance or by any string path catches every `require` of that module, including string requires written differently inside the code under test. `resetModules` first if the module was already required in this file.
- `jest.retryTimes(n, { logErrorsBeforeRetry, waitBeforeRetry, retryImmediately })` retries failed tests. Call it at the top level of the file or inside a `describe`.

## Global and DataModel mocks

`jest.globalEnv` is the current test's function environment. Spy on it the same way as on a table:

```lua
local printSpy = jest.spyOn(jest.globalEnv, "print")
printSpy.mockImplementation(function() end)

local randomSpy = jest.spyOn(jest.globalEnv.math, "random")
randomSpy.mockImplementation(function()
	return 5
end)

local realRoll = jest.globalEnv.math.random(1, 6)
```

- Indexing `jest.globalEnv` gives the original, unmocked function, for example `jest.globalEnv.print(...)`.
- Only whitelisted globals can be mocked; the docs show `print` and `math.random`, and `warn` works too (verified in Studio). `Random` cannot be mocked, so a module-local `Random.new()` is out of a spec's reach. Any other global errors with `Jest does not yet support mocking the <name> global.` These cannot be mocked through `globalEnv`: `require` (use `jest.mock`), task scheduling functions (use fake timers), and `game` or other Instance globals (use the DataModel spy below).

To spy on DataModel methods, set `mockDataModel = true` in `jest.config`. Only `game` is whitelisted. The mock implementation receives the instance as its first argument:

```lua
local getServiceSpy = jest.spyOn(game, "GetService")
getServiceSpy.mockImplementation(function(self, serviceName)
	return fakeServices[serviceName]
end)
```

Caveats: with this setting on, `game` is a table, not an `Instance`, so it can't be passed where an `Instance` is expected (`x:IsDescendantOf(game)` breaks). The hierarchy is not modeled either: `.Parent` and `FindFirstChild` return the real instances, so `workspace.Parent ~= game`. Enable the setting only in configs that need it.

## Fake timers

- `jest.useFakeTimers()` fakes exactly these: `delay`, `tick`, `time`, `DateTime`, `task.delay`, `task.wait`, `task.cancel`, `os.time` and `os.clock`. No other functions are listed. Verified in Studio: the fakes reach modules loaded through Jest's `require`; `DateTime.now` stays frozen (`setSystemTime` sets it, advancing does not move it); `task.defer`, `task.spawn`, `RunService` events and `workspace:GetServerTimeNow()` stay real; and a bare `task.wait()` in the test body under fake timers hangs until the test times out.
- The advance APIs take **milliseconds**, while Roblox timers take seconds. A `task.delay(1, cb)` needs `jest.advanceTimersByTime(1000)`.
- APIs: `runAllTimers()`, `runOnlyPendingTimers()` (use it for timers that reschedule themselves), `advanceTimersByTime(ms)`, `advanceTimersToNextTimer(steps?)`, `clearAllTimers()`, `getTimerCount()`, `setSystemTime(number | DateTime)` (moves the clock without firing timers), `getRealSystemTime()` and `useRealTimers()`.
- By default, timers run in continuous time. `jest.setEngineFrameTime(1000 / 60)` processes them once per 60 Hz frame, as the engine does, so `advanceTimersByTime(0)` fires a `task.delay(0.01, ...)` on the next frame. `jest.getEngineFrameTime()` returns the current value (default `0`).

```lua
beforeEach(function()
	jest.useFakeTimers()
end)

afterEach(function()
	jest.useRealTimers()
end)

it("fires after the cooldown", function()
	local mock, mockFn = jest.fn()
	Cooldown.start(2, mockFn)
	jest.advanceTimersByTime(1999)
	expect(mock).never.toHaveBeenCalled()
	jest.advanceTimersByTime(1)
	expect(mock).toHaveBeenCalled()
end)
```

## Async

- Return a Promise from a test or hook and Jest waits for it; a rejected Promise fails the test. The Promise must come from roblox-lua-promise (the separate `roblox/promise` package). A test may return **only** a Promise or `nil`.
- For `.resolves` and `.rejects`, return the assertion: `return expect(promise).resolves.toEqual(...)`. The docs' `.rejects` example rejects with a LuauPolyfill `Error`: `return expect(Promise.reject(Error.new("octopus"))).rejects.toThrow("octopus")`.
- `done` is the test function's **second** parameter. The first is the test context, usually `_`. Wrap the assertions in `xpcall` and pass the error to `done(err)`; otherwise a failed assertion shows up only as a timeout. Never mix `done` with a returned Promise.

```lua
it("calls back with the item", function(_, done)
	Shop.fetch("Sword", function(item)
		xpcall(function()
			expect(item.Name).toBe("Sword")
			done()
		end, function(err)
			done(err)
		end)
	end)
end)
```

- Hooks can return a Promise. The docs say hooks also accept `done` but don't show which parameter it is.
- `expect.assertions(n)` and `expect.hasAssertions()` work as in JS.
- Tests, `.each` rows and hooks time out after 5000 ms by default. Pass a timeout as the third argument or set `testTimeout`.
- A test body may yield directly (`task.wait` works, verified in Studio); the timeout still applies. Prefer fake timers over real waits so tests stay fast.
- The Promise library Jest accepts ships inside the Jest install at `Tests/Packages/_Index/roblox_promise@3.5.2/promise`. A place's own Promise or Future library is a different library, so turn it into a yield or `done` instead of returning it.

## Setup, teardown and filtering

- Hook semantics, execution order and `describe` scoping match JS Jest. Every `describe` body runs during collection, before any test runs.
- `.only` and `.skip` affect only their own file.
- `testNamePattern` (a `runCLI` option) is a regex matched against the full name: the describe chain and the test name joined by spaces, as in `"block A test one"`.
- `testPathPattern` (a string) and `testPathIgnorePatterns` (an array) are regex strings matched against test paths. In Studio a path is slash-separated from the specs folder, for example `Specs/DataCatalogs/FoodCatalog.spec`.
- A `testMatch` passed to `runCLI` overrides the `testMatch` in every config. Filters only narrow down the files `testMatch` already discovered.

## Configuration

`jest.config` is a ModuleScript that returns a table, or a Promise that resolves to one. Settings that take paths in JS take Instances here.

- `testMatch`: an array of globs. Default: `{ "**/__tests__/**/*", "**/?(*.)+(spec|test)?(.lua|.luau)" }`. Patterns apply in order, so a `!` negation must come after the pattern it excludes from. It can't be combined with `testRegex`, which matches against the absolute path.
- `testPathIgnorePatterns`: an array of regex strings.
- `rootDir` (an Instance; defaults to the root of the directory containing the config), `roots` (an array of Instances; defaults to `{ rootDir }`) and `projects` (an array of Instances, each holding a config).
- `setupFiles`: ModuleScripts that run once per test file, before the framework is installed. `setupFilesAfterEnv`: ModuleScripts that run once per test file after the framework is installed. That is the place for `expect.extend` and shared hooks such as `afterEach(function() jest.useRealTimers() end)`. There is no `setupFilesAfterEach`.
- `clearMocks` (default `false`) runs `jest.clearAllMocks()` before every test. `resetMocks` is documented only as a `runCLI` option. `restoreMocks` is not documented (its section is commented out), so call `jest.restoreAllMocks()` in `afterEach` instead.
- `testTimeout` in milliseconds (default `5000`). `slowTestThreshold` in seconds (default `5`).
- `mockDataModel` and `oldFunctionSpying`: see Mocking. `snapshotFormat` and `snapshotSerializers`: see Snapshots.
- `displayName`: a string or `{ name, color }`. Other keys: `verbose`, `stackDepth` (`0` prints the full trace) and `testFailureExitCode`.
- `reporters`: entries can be `"default"`, `"summary"`, `"github-actions"`, a ModuleScript, or `{ reporter = ModuleScript, options = {...} }`. Listing any reporter replaces the default one unless you also include `"default"`.

`runCLI` options (the second argument): `ci`, `clearMocks`, `resetMocks`, `debug`, `expand`, `json`, `listTests`, `noStackTrace`, `passWithNoTests`, `reporters`, `showConfig`, `stackDepth`, `testMatch`, `testNamePattern`, `testPathPattern`, `testPathIgnorePatterns`, `testTimeout`, `updateSnapshot` and `verbose`. `listTests` and `showConfig` print their output and exit without running tests.

## Snapshots

- Available APIs: `toMatchSnapshot(propertyMatchers?, hint?)`, `toThrowErrorMatchingSnapshot(hint?)` and `expect.addSnapshotSerializer(serializer)`.
- Unlike JS Jest, a new snapshot is **never written on the first run**. The test fails until a run with `updateSnapshot = true` **and** filesystem write access. `ci = true` fails new snapshots instead of storing them.
- Snapshots live in a file next to the test (the docs' example is `test.spec.snap.lua`), with entries like `exports[ [=[<full test name> 1]=] ] = [=[...]=]`.
- **Studio caveat:** the docs describe writing snapshot files only through the internal `roblox-cli` runner with elevated filesystem access (`--fs.readwrite`). They give no way to write them from Studio, and `rocale-cli` does not support snapshots at all. In a Studio-only workflow, use explicit matchers such as `toEqual` and `toMatchInstance`.
- Property matchers keep changing fields stable: `expect(user).toMatchSnapshot({ CreatedAt = expect.any("DateTime") })`.
- Roblox-specific `snapshotFormat` options: `printInstanceDefaults` (default `true`; `false` prints only properties changed from their defaults), `printInstanceTags` (default `false`), `useStyledProperties` (default `false`; reads computed values through `GetStyled`) and `redactStackTracesInStrings` (default `false`). `compareKeys` and `plugins` can't be overridden.

## Not in the Jest Roblox docs

Confirm these exist before relying on them: `test.concurrent`, `jest.doMock`, `jest.requireMock`, `jest.createMockFromModule`, `jest.setTimeout`, `jest.mocked`, `mockResolvedValue`, `mockRejectedValue`, inline snapshots, printf-style `.each` placeholders (`%s`, `%d`), the `restoreMocks` config, and arguments to `jest.useFakeTimers`. The `spyOn` `accessType` argument is explicitly unsupported.
