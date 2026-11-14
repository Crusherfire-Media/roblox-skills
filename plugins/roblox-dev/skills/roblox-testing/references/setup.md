# Setting up Jest Roblox in a place

A place is ready when `game.ServerScriptService.Tests.Packages.Jest` and
`game.ServerScriptService.Tests.Specs["jest.config"]` both exist. List the children of
`game.ServerScriptService.Tests` before changing anything, and ask the user before installing
into a place that has no `Tests` folder.

In a Rojo repo, every step below lands in files instead: the built packages under
`src/ServerScriptService/Tests/Packages/` (or a pesde dev dependency, as the Rojo reference
says), and `jest.config.luau`, `StopVideDrivers.luau`, and `StatusReporter.luau` under
`src/ServerScriptService/Tests/Specs/`. Skip the import steps and let Rojo sync them.

## 1. Build the Jest packages

Install from Wally, pinned to one version, on the machine running Studio. Use the official
`roblox/jest` packages from Wally; a Creator Store copy of Jest may be stale or altered.

In a scratch folder, write `wally.toml`:

```toml
[package]
name = "local/jest-install"
version = "0.0.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"
private = true

[dependencies]
Jest = "roblox/jest@=3.20.1"
JestGlobals = "roblox/jest-globals@=3.20.1"
```

and `default.project.json`:

```json
{
	"name": "Packages",
	"tree": {
		"$path": "Packages"
	}
}
```

Then run `wally install` and `rojo build default.project.json -o JestPackages.rbxm`. The result
is one `Packages` folder holding `Jest`, `JestGlobals`, and `_Index` (about 650 ModuleScripts).

If `wally` or `rojo` are Rokit or Aftman shims that refuse to run outside a project, add a
`rokit.toml` beside `wally.toml` that lists the installed versions (see `~/.rokit/tool-storage`):

```toml
[tools]
wally = "UpliftGames/wally@0.3.2"
rojo = "rojo-rbx/rojo@7.7.1"
```

## 2. Load it into the place

1. Create a Folder `Tests` in `ServerScriptService`. Give it no `LOAD_MODULE` tag and no loader
   or relocation attributes: the module loader must never see it.
2. Import the built `JestPackages.rbxm` into `game.ServerScriptService.Tests` (the MCP's
   import-a-model action, or Studio's **Insert from File**). It lands as `Tests.Packages`.
3. Create a Folder `Specs` in `Tests`, and in it a ModuleScript named `jest.config` with the
   this source:

   ```lua
   --!strict
   return {
   	testMatch = { "**/*.spec" },
   }
   ```

4. If the place uses Vide, add a ModuleScript `StopVideDrivers` beside `jest.config` and list it
   in the config as `setupFilesAfterEnv = { script.Parent.StopVideDrivers }`. Jest loads a fresh
   Vide copy for every spec file and again after every `jest.resetModules()`, and each copy
   connects to `RunService.Heartbeat` when required. Without this file those connections keep
   running in Studio after every run, until it closes. Its source:

   ```lua
   --!strict
   const JestGlobals = require("@game/ServerScriptService/Tests/Packages/JestGlobals")
   const afterEach = JestGlobals.afterEach

   --[[
   	Requires Vide here rather than at the top so each call gets the copy in the current module
   	registry, which is a new one after jest.resetModules().
   ]]
   local function stopVideDriver()
   	require("@game/<path to the place's Vide ModuleScript>").step(0)
   end

   stopVideDriver()
   afterEach(stopVideDriver)

   return nil
   ```

   Require the Vide ModuleScript itself, not a library module that returns it, so spec files
   that never use Vide load nothing more than Vide. Specs then move springs and exit delays by
   calling `step` themselves. Jest reads `jest.config` once per Studio session, so restart Studio
   after changing it.
5. Add a ModuleScript `StatusReporter` beside `jest.config` with the source in
   [StatusReporter.luau](StatusReporter.luau), and list it in the
   config as `reporters = { script.Parent.StatusReporter }`. It replaces Jest's PASS and FAIL lines
   in the Output window with a green or red circle per spec file, each failing test and its
   failure details under a red file, and a summary line. Restart Studio after adding or changing it.
6. Run the specs ([running-in-studio.md](running-in-studio.md)) with no filters. With no specs
   yet it reports that no test ran; a `setupError` or `runnerError` means a piece is missing or
   the config is invalid.

Specs must live in `Specs`, not beside `Packages`: the Jest packages ship their own spec files,
which `testMatch` would otherwise pick up.

## Upgrading

Rebuild with the new pinned version, delete `Tests.Packages`, and import the new model in its
place. Run the whole suite afterward.
