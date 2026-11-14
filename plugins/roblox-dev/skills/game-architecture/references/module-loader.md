# Module Loader reference

Verified against module-loader **v4.0.0** on GitHub
([`ActualFire-Games/module-loader`](https://github.com/ActualFire-Games/module-loader), MIT) and
Wally (`crusherfire/module-loader`); v4.0.1 only fixed relocation under folders with dots in their
names (pesde's `.pesde` and version folders) and switched the relocation path attributes to `/`
separators. Read the installed version from the pin in `pesde.toml` or `pesde.lock`; a place that
installed the loader as a Roblox package shows it as the `VersionNumber` of the `PackageLink` under
the `ModuleLoader` ModuleScript. If the version differs, re-read the parts of the loader you are
about to rely on before trusting this file. The loader's own header comment is the next best
summary, and the [release notes](https://github.com/ActualFire-Games/module-loader/releases) list
what changed between versions.

## Contents

- Bootstrap and settings
- Discovery
- Attributes
- Lifecycle
- Errors and warnings
- Relocation
- Requires after relocation
- Client start and completion signals
- Public API
- Parallel modules
- Side effects of requiring the loader
- Debugging
- Relocation check

## Bootstrap and settings

Each `Start` script requires the loader, optionally calls `ChangeSettings`, then calls `Start`:

```lua
const ModuleLoader = require("@game/ReplicatedStorage/ModuleLoading/ModuleLoader")
ModuleLoader.ChangeSettings({ VERBOSE_LOADING = script:GetAttribute("VERBOSE_LOADING") })
ModuleLoader.Start()
```

`Start()` with no arguments discovers modules only by tag. `Start(folderA, folderB, ...)` also
searches those folders. `Start` may be called once per realm; a second call errors.

Settings are attributes on the ModuleLoader script. `ChangeSettings` overrides them at runtime,
merging its keys into the live settings; keys left out keep their value. A setting attribute of
the wrong type logs `ModuleLoader setting ... ignoring it.` and counts as unset.

| Attribute | `ChangeSettings` key | Meaning |
|---|---|---|
| `VerboseLoading` (default `true`) | `VERBOSE_LOADING` | Log every step and the load timings; only an explicit `false` turns it off |
| `YieldThreshold` (default 10) | `YIELD_THRESHOLD` | Seconds before a slow-call warning |
| `UseCollectionService` | `USE_COLLECTION_SERVICE` | Discover by tag |
| `LoaderTag` (default `LOAD_MODULE`) | none | The discovery tag, fixed at require time |
| `ClientWaitForServer` | `WAIT_FOR_SERVER` | Client waits for the server to finish loading |
| `ClientWaitForPersistentLoaded` | `WAIT_FOR_PERSISTENT` | Client waits for persistent models to stream in |

## Discovery

- A folder passed to `Start`: every ModuleScript inside it, at any depth, whose path back to that
  folder is made only of Folders.
- A tagged Folder: the same, measured back to the tagged folder.
- A tagged ModuleScript: the module itself, with its parent as its folder.
- A module nested under another module (or under a Model, Part, and so on) is never discovered.
  It belongs to its parent and moves with it.
- The loader never looks at names. Only the class (ModuleScript), the path, and the attributes
  decide what loads.
- The same module found twice (overlapping folders passed to `Start`, a folder and a tag, or a
  relocation pointer and its real module) loads once and runs `Init` and `Start` once.

## Attributes

Set on a ModuleScript. The four listed under the cascade rules below may also be set on a Folder
to cascade to every module below it; the others are read from the module only.

| Attribute | Effect |
|---|---|
| `LoaderPriority` (number, default 0) | Higher loads first. Equal priorities have no fixed order. Module only. |
| `ClientOnly` / `ServerOnly` | Load on one realm only. |
| `IgnoreLoader` | Never require the module, so no `Init` or `Start`. Relocation still applies. |
| `RelocateToReplicatedStorage` | Copy the module to clients (see Relocation). |
| `RelocateToServerScriptService` | Keep the module on the server (see Relocation). Module only, never cascades. |
| `Parallel` | Require the module inside its own Actor (see Parallel modules). Module only. |

All of these except `LoaderPriority` must be booleans. A flag of any other type (a string
`"true"` typed into the Properties panel) logs `Loader attribute <Name> on '<path>' is a string,
not a boolean` once and counts as `true`, except `RelocateToReplicatedStorage`, which counts as
`false`, so a mistyped flag never sends a module to clients. A `LoaderPriority` that is not a
number logs `LoaderPriority on '<path>' is not a number` and counts as 0. That is the behavior
from v4.0.0. Older versions ignore a string
`RelocateToServerScriptService` and ship the module to clients.

Cascade rules for `ClientOnly`, `ServerOnly`, `IgnoreLoader`, and `RelocateToReplicatedStorage`:

- A value set on the module itself wins, even `false`.
- Otherwise the closest Folder above it with a value wins.
- The walk stops at the folder the module was discovered through. A tagged ModuleScript only
  inherits from its direct parent Folder.
- Attributes on a module nested under another module do nothing, since that module is never
  discovered.

## Lifecycle

1. **Load**: require every discovered module, in priority order.
2. **Init**: call `:Init()` on each loaded table that has one, in the same order.
3. **Start**: call `:Start()` on each loaded table that has one, in the same order.

- Each phase finishes for every module before the next phase begins.
- Each call runs in its own thread, but the loader waits for it to finish before calling the next
  module. There is no timeout.
- Methods are called with the module table as `self` and no other arguments.
- A module that returns a function or a constant is loaded but has no lifecycle.
- Two modules that return the same table (a relocation pointer and its real module) get one `Init`
  and one `Start`.
- **Inherited methods:** after the load phase, the loader records every `Init` and `Start` that a
  loaded table defines itself (`rawget`). A method a table only inherits through its metatable is
  skipped when another loaded table owns it; the owner runs it, once, as `self`. A method inherited
  from a table the loader never loads still runs. This does not depend on load order.
- Each call is tagged for memory and profiler tools as `Module::<Name>`, `Module::<Name>::Init`,
  or `Module::<Name>::Start`.

## Errors and warnings

| What happens | Result | Log line |
|---|---|---|
| Require errors | No `Init` or `Start` for that module. Loading continues. | `>> Failed to load module <Name>` with traceback |
| `Init` errors | That module's `Start` is skipped. Loading continues. | `>> Failed to init module <Name>`, then `>> Skipping :Start() for module <Name> because its :Init() failed` |
| `Start` errors | Loading continues. | `>> Failed to start module <Name>` |
| A call runs longer than `YieldThreshold` | The loader keeps waiting and warns every 5 seconds. Parallel modules too. | `>> Loading Module '<Name>' is taking a while!` (or `:Init() for Module`, `:Start() for Module`, or the same with `PARALLEL Module`) |
| A loader attribute or setting has the wrong type | Warning; the value counts as described in Attributes and Bootstrap and settings. | `Loader attribute ...`, `LoaderPriority on ...`, or `ModuleLoader setting ...` |
| A `RelocateToServerScriptService` module yields during require | Warning only. | `[SECURITY] Module '<Name>' yielded during require()!` |

Failure lines always print. With `VerboseLoading` on, every step also prints, between phase
banners (`=== LOADING MODULES ===`, `=== INITIALIZING MODULES ===`, `=== STARTING MODULES ===`,
`=== LOADING FINISHED ===`). The line after `=== LOADING FINISHED ===` gives the phase timings,
for example `Took 0.411 seconds total (require 0.363, init 0.046, start 0.002)`; "require"
includes discovery, and the total leaves out the client's waits before loading. Lines start with
`[S]` on the server and `[C]` on the client.

## Relocation

**`RelocateToReplicatedStorage`** (usually set on a root folder and cascaded):

- A server pre-pass runs before any module is required. It moves each marked module to
  `ReplicatedStorage.RELOCATED_MODULES`, copying the chain of folders between the tagged folder's
  parent and the module, and leaves a pointer ModuleScript at the original spot.
- Only modules whose path back is all Folders relocate. A module's children move with it.
- Each copied folder gets a one-time snapshot of the original folder's attributes (object
  attributes included), so `script.Parent:GetAttribute(...)` still works after the move. The
  loader tag is copied too, so clients discover relocated modules by tag.
- The server publishes a manifest of every relocated module. The client uses it to rebuild the
  original `ServerScriptService` paths locally, with a pointer at each module, so the same
  `ServerScriptService` path works on both realms.
- Searches any depth. `IgnoreLoader` does not stop relocation. A module already in
  ReplicatedStorage is skipped with a warning.

**`RelocateToServerScriptService`**:

- Under a folder marked `RelocateToReplicatedStorage`, it opts the module out: the module stays
  where it is in ServerScriptService and never reaches clients. The pre-pass also sets `ServerOnly`
  on it unless `ServerOnly` or `ClientOnly` is already set.
- Anywhere else (an older layout that keeps code in ReplicatedStorage), the module moves into
  `ServerScriptService.RELOCATED_MODULES` right after it is required and leaves a server-only
  pointer. Until that move, clients can see it, which is why top-level yields trigger the
  `[SECURITY]` warning.
- Setting both relocate attributes on one module warns and skips the move to ReplicatedStorage.

Name collisions (two modules with the same name at the same mirrored path, or in the flat server
folder) are warned about, because pointers resolve by name.

## Requires after relocation

| Require | Server | Client |
|---|---|---|
| Relative, both ends relocated (`./Sibling`, `../SystemPackage/X`) | Works | Works (the folder chain is copied) |
| Relative, from a module that stayed in ServerScriptService to a relocated one | Works (pointer at the original spot) | Not applicable |
| Relative, from a relocated module to a server-only module | Fails | Fails (the server module is not in the copy) |
| Absolute `@game/ServerScriptService/...` to a relocated module | Works (pointer) | Works (rebuilt pointer) |
| Absolute path to a module nested inside a relocated module | Fails | Fails (only the parent has a pointer; use the parent's return table, or `@self/...` from the parent) |
| Object attribute handle, `:Wait()` | Works (the handle follows the module when it moves) | Works once the module replicates; a server-only target resolves to `nil` |
| Anything in edit mode | Works: nothing has moved yet | |

A pointer resolves its target with `WaitForChild`, 10 seconds per path segment, and errors if a
client requires a pointer to a server-side module.

## Client start and completion signals

Client `Start` waits, in order, for:

1. The relocation manifest to be applied. Capped at 15 seconds, then it warns and continues.
2. `ServerLoaded`, if `ClientWaitForServer` is on. No cap, on purpose: a server that never
   finishes loading is a bug to fix, not something to play through.
3. `workspace.IsPersistentLoaded`, if `ClientWaitForPersistentLoaded` is on. A helper script sets
   it, with a 20 second fail-safe.
4. Every relocated module in the manifest to replicate, right before discovery. Capped at 15
   seconds, then it warns and continues. It ends with a check that does not yield, so discovery
   sees exactly the tree it verified. A relocated folder can occasionally fail to reach a joining
   client and never arrive on its own, so after 5 seconds the client sends the paths still missing
   through `RelocationRepairEvent`, and the server detaches and re-attaches each one so it
   replicates again (clients that already have it keep the same instance). The server only acts
   on paths from its own manifest, takes 1 request of up to 10 paths per player and only before
   that player has loaded, skips subtrees over 1000 descendants (and warns), resends one instance
   at a time after its own load, at most once every 10 seconds per instance and 20 times a minute
   in total. During the 0.25 second detach, a relative require that crosses the resent folder's
   boundary fails on every realm; pointers wait it out. Look for `asking the server to resend`
   (`[C]`) and `Resending relocated` (`[S]`) in the logs.

When a realm finishes, the loader sets `ServerLoaded` / `ClientLoaded` (and a matching
`...LoadedTimestamp`) on the ModuleLoader script. A finished client tells the server, which sets
`_ModulesLoaded = true` on that Player.

## Public API

| Function | Notes |
|---|---|
| `Start(...: Instance)` | Default discovery. Call once per realm. |
| `StartCustom(shouldKeep: (container, module) -> boolean, ...: Instance)` | Replaces the default filter for loading. Relocation is unaffected. |
| `ChangeSettings(settings)` | Keys listed in Bootstrap and settings. |
| `IsServerLoaded(): boolean` | |
| `IsClientLoaded(player): boolean` | Server-side check of `_ModulesLoaded`. |
| `WaitForLoadedClient(player): boolean` | Yields. Returns `false` if the player leaves first, and at once if they already left. |
| `IsPersistentLoaded(): boolean` | Client only. |
| `GetServerLoadedTimestamp(): number` | `workspace:GetServerTimeNow()` when the server finished. Errors if it has not finished loading. |

There is no module registry, no "get module" function, and no "server loaded" signal. Modules
require each other directly. A server system that must wait for a client uses
`WaitForLoadedClient` in a spawned thread, never inside `Init` or `Start`.

## Parallel modules

- Opt in with `Parallel = true` on the module.
- The loader clones an Actor with a script and a copy of `ParallelModuleLoader`, parents it to
  ServerScriptService (server) or the player's `PlayerScripts` (client), and requires the module
  inside it. `Init` and `Start` are sent as Actor messages and still run in the global order.
- The Actor has its own require cache, so any other module that requires a Parallel module gets a
  separate copy of it.
- The module's code starts in the serial phase and must call `task.desynchronize()` itself to run
  in parallel.
- If its require errors it gets no `Init` or `Start`. If its `Init` errors, `Start` is skipped with
  the usual `Skipping :Start()` line. Slow calls warn like any other module's (`PARALLEL Module`).
- A pointer and its real module, both discovered, load once: Actors keep separate require caches,
  so the loader deduplicates by the module a pointer resolves to.
- The ownership rule for inherited methods does not reach into Actors.

## Side effects of requiring the loader

In a running game:

- **Server:** creates the `LoadedEvent` and `RelocationRepairEvent` RemoteEvents under the loader,
  enables a copy of `PersistentLoadedCheck` in ReplicatedFirst, connects its remote and
  `PlayerRemoving` handlers, and clears stale relocation attributes on the loader. The
  `RELOCATED_MODULES` folders in ReplicatedStorage and ServerScriptService are created the first
  time a module moves into them.
- **Client:** waits for `LoadedEvent` and `RelocationRepairEvent` with no timeout, and starts
  rebuilding relocated paths right away, before `Start` is called.

Outside a running game (`RunService:IsRunning()` is false: Luau run in the edit session, the
command bar, plugins, Jest specs, UI Labs stories), requiring the loader creates nothing in the place, connects nothing,
and waits on nothing, so modules that require it load there. Its remotes exist only as
unparented placeholders, and nothing runs until `Start`, which is never called in edit mode.
Before v4.0.0 the loader took the client path in edit mode and waited forever for
`LoadedEvent`, so check the version before requiring an older loader outside a playtest.

A fresh require during a running playtest (a second copy loaded by a separate script context,
say) still runs the server setup again, so inspect a live loader by running Luau in the
playtest's server runtime in a way that shares the game's require cache (Studio MCPs that run
code in a live server or client usually do).

## Debugging

In Studio only, the loader exposes `_internalsForTest`. During a playtest, run this as Luau in
the server or client runtime:

```lua
local loader = require(game.ReplicatedStorage.ModuleLoading.ModuleLoader) -- adjust to the place's path
local tracker = loader._internalsForTest.getTracker()
-- tracker.Load[module] = the value it returned (true for a Parallel module, whose value lives in
-- its Actor); no entry when the require failed or the module duplicates one already loaded
-- tracker.Init[module] / tracker.Start[module] = true when the call succeeded, false when it
-- failed (or is still running), nil when there was nothing to call
```

`getRelocationManifest()` returns the client's manifest and `getSettings()` the live settings.

## Relocation check

Run this as Luau in the edit session after adding or moving modules. In a Rojo repo, run it once
Rojo has synced the change. It reports two kinds of
problem:

- A loader attribute holding the wrong type. The boolean attributes must be real booleans. A
  string `"true"` looks right in the Properties panel, but it is a mistake: from v4.0.0 the
  loader warns and guesses (see Attributes), and older versions handle it inconsistently, honoring
  it in some checks and ignoring it in the relocation pre-pass.
- A module that looks server-only (its name contains `Server`, or it has `ServerOnly`) but will be
  copied to clients.

"No problems found." means no server code will reach clients. A module nested under another
module follows its parent, so check parents rather than children.

```lua
local ServerScriptService = game:GetService("ServerScriptService")

local LOADER_BOOLEANS = { "ClientOnly", "ServerOnly", "IgnoreLoader", "Parallel", "RelocateToReplicatedStorage", "RelocateToServerScriptService" }

-- Mirrors the pre-4.0.0 relocation pre-pass, which honors only boolean true. 4.0.0 keeps a
-- mistyped RelocateToServerScriptService module on the server, so this errs toward reporting it.
local function relocatesToClients(module: ModuleScript): boolean
	if module:GetAttribute("RelocateToServerScriptService") == true then
		return false
	end
	local own = module:GetAttribute("RelocateToReplicatedStorage")
	if own ~= nil then
		return own == true
	end
	local ancestor = module.Parent
	while ancestor and ancestor:IsA("Folder") do
		local value = ancestor:GetAttribute("RelocateToReplicatedStorage")
		if value ~= nil then
			return value == true
		end
		ancestor = ancestor.Parent
	end
	return false
end

local problems = {}
for _, instance in ServerScriptService:GetDescendants() do
	if not instance:IsA("ModuleScript") and not instance:IsA("Folder") then
		continue
	end
	for _, name in LOADER_BOOLEANS do
		local value = instance:GetAttribute(name)
		if value ~= nil and typeof(value) ~= "boolean" then
			table.insert(problems, `{instance:GetFullName()}.{name} is a {typeof(value)}, not a boolean`)
		end
	end
	local priority = instance:GetAttribute("LoaderPriority")
	if priority ~= nil and typeof(priority) ~= "number" then
		table.insert(problems, `{instance:GetFullName()}.LoaderPriority is a {typeof(priority)}, not a number`)
	end
	if not instance:IsA("ModuleScript") or not instance.Parent:IsA("Folder") then
		continue
	end
	local serverOnly = instance:GetAttribute("ServerOnly")
	local looksServerOnly = (serverOnly ~= nil and serverOnly ~= false) or string.find(instance.Name, "Server") ~= nil
	if looksServerOnly and relocatesToClients(instance) then
		table.insert(problems, `{instance:GetFullName()} will be copied to clients`)
	end
end
return if #problems == 0 then "No problems found." else problems
```
