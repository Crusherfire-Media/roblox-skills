---
name: game-architecture
description: Architecture rules for Roblox game code run by Module Loader (crusherfire/module-loader) - single-script layout, system categories, <Name>System folders split into SystemPackage and Implementation, realm and relocation attributes, the Init/Start lifecycle, and which modules may require which. Load it before creating, moving, or renaming any system, module, Script, or LocalScript in a Rojo repo or a connected Studio place; before adding a require between modules, or when Script Analysis reports a cyclic module dependency; before a system starts playing a sound; and when debugging load order, Init/Start, relocation, or anything else the ModuleLoader does. Load it even for one small helper module or a single new require.
---

# Game architecture

Game code runs from two scripts. Everything else is a ModuleScript that the Module Loader
finds, requires, and then runs `Init` and `Start` on. This skill sets where modules live, which
attributes they carry, what their lifecycle methods may do, and which modules may require which.

The loader's exact behavior (discovery, relocation, error handling, API, the relocation check)
is in [references/module-loader.md](references/module-loader.md). Read it before relying on any
loader detail this file does not state, and whenever you debug the loader itself.

**In a Rojo repo** (a `default.project.json` at its root), read
[references/rojo-mode.md](references/rojo-mode.md) first. Code is files there, and it overrides
the rules below that assume Studio: attribute references in Requires, setting attributes, and
where shared systems (pesde packages) live.

Where a system's assets live, and how a system keeps the sounds it plays cached, are in
[references/assets-and-sounds.md](references/assets-and-sounds.md). Read it before adding an
asset to a system and before a system plays a sound.

## Steps for adding or moving code

1. Read the place's two `Start` scripts and list what carries the `LOAD_MODULE` tag, so you know
   which folders load and relocate.
2. Pick the system the code belongs to, or create `<Name>System` in the right category (see
   Categories). Decide SystemPackage or Implementation (see Systems).
3. Name the module and set its realm attributes (see Naming and Realms).
4. Write its requires by the rules in Requires and Dependencies.
5. Keep its top-level code, `Init`, and `Start` free of yields (see Lifecycle).
6. Verify (see Verifying).

Done when every new or moved module sits in its system folder with the right realm attributes,
the relocation check lists no server module, and a playtest logs no `>> Failed` or
`Skipping :Start()` line for your modules.

## Scripts

- Exactly two scripts run game code: `ServerScriptService.Start` (Script) and
  `StarterPlayer.StarterPlayerScripts.Start` (LocalScript). Each requires the loader, turns on
  `USE_COLLECTION_SERVICE` (off by default), and calls `Start()`. Everything else is a ModuleScript.
- Allowed exceptions: the loader's own internals; a `ReplicatedFirst` loading screen (it must run
  before the loader); scripts Roblox looks for by name (`Animate`, `RbxCharacterSounds`); and
  templates a system clones at runtime, kept inside that system.
- If a task seems to need any other Script or LocalScript, ask the user first.
- Scripts outside these rules are legacy. Leave them alone unless the user asks for a migration,
  and never use them as a pattern.

## Layout

- Game code lives in `ServerScriptService.Modules`. Its root folders are `Systems` plus library
  and data folders (for example `Utilities`, `Components`, and catalogs not tied to one system).
- Every root folder carries the `LOAD_MODULE` tag and `RelocateToReplicatedStorage = true`. Code
  stays in ServerScriptService, and at runtime the loader copies only what clients need to
  ReplicatedStorage, so server code never reaches clients.
- Library and data root folders also carry `IgnoreLoader = true`. They have no lifecycle, so the
  loader has no reason to require them at boot. They still relocate.
- There are no top-level `Services` or `Setup` folders. Anything with a lifecycle belongs to a
  system.
- UI Labs stories and their storybook live in `ServerScriptService.Stories`, outside `Modules`.
  The folder is Studio-only: no `LOAD_MODULE` tag, no loader or relocation attributes, and no game
  module requires it. The `vide-ui-labs` skill covers what goes in it.
- Jest specs and the Jest packages live in `ServerScriptService.Tests`, Studio-only in the same
  way as `Stories`. The `roblox-testing` skill covers what goes in it.
- An older place may list folders in `Start(...)` or keep code in ReplicatedStorage. There, new
  modules follow the place's existing layout, and migration happens only when the user asks.

## Categories

Every system sits in a category folder directly under `Systems`, even in a small game, so paths
stay the same as the game grows. Create a category folder only when a system needs it, and leave
category folders untinted.

| Category | Holds |
|---|---|
| `Core` | Infrastructure many systems build on that does not depend on this game: data, notifications, sound, analytics, anti-cheat, teleporting, streaming |
| `Gameplay` | The game's own mechanics and core loop |
| `Economy` | Currencies, shops, selling, Robux purchases |
| `Progression` | Rebirths, levels, quests, achievements, leaderboards, tutorials |
| `Social` | Chat, friends, parties, trading, groups |
| `Presentation` | What players see that holds no game rules: HUD shells, camera, environment and cosmetic visuals |
| `Tooling` | Admin commands, debug and Studio-only tools |

- Place a system by its main job, not by who uses it. When unsure, use `Gameplay`.
- A project may add one level of subfolder inside a category (`Gameplay/Combat`,
  `Economy/Trading`). Nothing nests deeper, so a system is always at
  `Systems/<Category>/<Name>System` or `Systems/<Category>/<Subfolder>/<Name>System`.
- Moving a system to another category changes its absolute path, so update every absolute
  require that names it.

## Systems

A system is a folder `<Name>System` in its category, holding exactly two folders. Use both for every
system, even a game-only one, so the core is ready to become a reusable package later. All of a
system's code stays inside its folder: a system's setup lives in its own Implementation, never in
a shared setup folder.

Tint every `SystemPackage` folder red (`IconTint = Color3.fromRGB(255, 0, 0)`) and every
`Implementation` folder light blue (`IconTint = Color3.fromRGB(0, 170, 255)`), so the two halves
of a system are easy to tell apart in the Explorer.

**SystemPackage** is the system's core, written to be generic and game-agnostic wherever possible.
Create only the modules the system needs:

- `<Name>SharedService`: state and logic both realms need. Its `Init` and `Start` hold setup both
  realms need.
- `<Name>ServerService` and `<Name>ClientService`: inherit from the Shared service with
  `setmetatable({}, <Name>SharedService)` and hold realm-specific setup and logic.
- `<Name>Network` for the system's remotes, and `<Name>Types` for its shared types.
- Catalogs the system needs to work at all.
- Helpers used across the package, marked `IgnoreLoader = true`.

**Implementation** holds game-specific code and every connection to other systems:

- Setups (`_<Name>Setup`, `_<Name>ClientSetup`, ...) inject game config, tags, and callbacks into
  the SystemPackage.
- Mediators (`_<Name><Other>Mediator`) connect this system to another, so systems never require
  each other.
- Game-specific catalogs.

A catalog goes in the SystemPackage when the system needs it to work generically, in the related
system's Implementation when it is game-specific, and in a data root folder when no single
system owns it.

**Assets** that belong to a system (models and templates it clones, sounds, animations, UI
templates) live with that system, never in a shared assets folder, so a packaged system carries
everything it needs. Where each one goes, and how other modules reach it, is in
`references/assets-and-sounds.md`.

## Naming

- System folders end in `System`. Modules follow the names in Systems. Nothing uses a
  `Controller` suffix.
- A leading `_` means nothing outside the module's owner requires it: private children, setups,
  and mediators. The loader ignores names, so `_` never stops a module from loading.
- A helper or class used by one module is that module's child (`require("@self/_Helper")`). The
  loader never loads a module nested under another module; it moves with its parent.
- A class module's returned table holds only `.new` and static functions, and object methods live
  on a separate metatable table. The loader calls `Init` or `Start` on any table it loads that has
  them, so the class table must not have methods with those names.

## Realms

| Module | Attribute on the module | If it is missing |
|---|---|---|
| `<Name>ServerService`, server-only setups and mediators | `RelocateToServerScriptService = true` | The module is copied to ReplicatedStorage and its source reaches every client |
| `<Name>ClientService`, client-only setups and mediators | `ClientOnly = true` | The server requires and runs client code |
| Shared service, Network, Types, catalogs both sides read | none | |

`RelocateToServerScriptService` only works set on the module itself; it does not cascade from a
folder. The loader adds `ServerOnly` on its own. Loader attributes are booleans (`LoaderPriority`
is a number), so set real booleans: a string `"true"` looks right in the Properties panel, but it
is a mistake the loader has to guess around, differently by version (Attributes in the
reference). After adding or moving any module, run the relocation check in the reference.

## Lifecycle

- The loader requires every module, then runs every `Init`, then every `Start`, in
  `LoaderPriority` order (higher first; equal priorities have no fixed order).
- `Init` sets up the module's own state and connections, and registers or injects into other
  modules. Most modules need only `Init`.
- `Start` holds work that calls into other modules and needs their `Init` finished.
- Order work with `Start`, not `LoaderPriority`. Set a priority only when one `Init` must run
  before another `Init`, and comment what it has to run before.
- `Init`, `Start`, and module top-level code return without yielding. The loader waits on each
  call with no timeout, so a yield holds up every module after it and the `ServerLoaded` flag. Put
  loops and waits in `task.spawn` or `task.defer`. Never wait for `ServerLoaded` inside `Init` or
  `Start`: it is set only after every `Start` returns, so the wait never ends.
- A Shared service's `Init` and `Start` run once per realm, called on the Shared service itself.
  The loader does not call them again for the Server or Client service that inherits them.
- Require-time setup that creates instances (folders, sounds, pools) is gated behind
  `RunService:IsRunning()`, because modules also get required from the command bar, plugins, and
  UI Labs stories in edit mode, where that setup would litter the edit DataModel. UI Labs requires
  modules again on every story reload, and Jest specs load them the same way.
- The same holds for require-time connections to engine signals (`RunService`,
  `UserInputService`, `GuiService`, `Players`, a camera) and for threads that never finish. In
  edit mode each fresh copy's connection keeps that copy, and every module loaded with it, in
  memory until Studio closes. Gate it behind `RunService:IsRunning()`, or connect on first use
  when the connection only matters once something calls the module.
- A system that plays sounds keeps them cached for as long as it can play them, so each play
  starts at once from the cache. How to hold them, and where each hold lives, is in
  `references/assets-and-sounds.md`. Sounds that UI plays follow the `vide-performance` skill.
- Parallel Luau: a system that needs parallelism manages its own Actors. Use the loader's
  `Parallel` attribute only when the user asks for one module to run in parallel.

## Dependencies

Dependencies flow one way: libraries and data, then SystemPackages, then Implementation.

- A SystemPackage requires its own modules, library modules, and the SystemPackage of another
  generic system that never depends back on it, directly or transitively. A `Core` system is the
  usual case: many systems need it, and it needs none of them. Every require from a SystemPackage
  to anything outside it goes through an attribute reference (see Requires).
- A `Core` SystemPackage requires only other `Core` systems and libraries. That keeps `Core` safe
  to depend on from anywhere, with no risk of a cycle.
- A SystemPackage never requires an Implementation module, with one exception: a data-only
  **slot** its own Implementation must provide, such as a profile template that defines the game's
  data shape. Reach it through an attribute reference like any other outside dependency, and
  document the slot's name and expected shape in the SystemPackage so every game knows to provide
  it. Game-specific wiring between systems belongs in a mediator in Implementation, not in either
  SystemPackage.
- Implementation modules may require any system's SystemPackage.
- Nothing requires an Implementation lifecycle module (a setup or mediator). A data-only module in
  an Implementation, such as a game-specific catalog, may be required by other Implementation
  modules.
- **Leaves**: `<Name>Types` modules and catalogs require only libraries and other leaves, and any
  module may require them, libraries included. A helper that follows the same rule is a leaf too.
  Leaves carry no behavior, so requiring one can never create a cycle. A catalog that needs
  another system's data is not a leaf: move that lookup into a service or a mediator.
- A Shared service never requires its Server or Client service.
- A child module never requires its parent or ancestor: the parent passes what the child needs
  into its constructor.
- Before adding a `require`, check that the target does not already depend, directly or
  transitively, on the requiring module.

**No cycles.** A "Cyclic module dependency" warning means a responsibility sits in the wrong
place, so restructure instead of silencing it. A lazy require (moving `require` into a function)
is not a fix: it hides the cycle from the runtime, the analyzer still reports it, and the coupling
remains. Break a cycle with the first of these that fits:

1. Move the function to the module that owns the data it touches.
2. Give the lower module a registration or injection API that a setup feeds at load.
3. Fire a signal from the lower module that the higher module listens to.
4. Extract the shared piece into a small module both sides depend on.

**Injection for generic modules.** A generic module, which includes everything in a SystemPackage
and anything package-managed, never requires game-specific modules or hard-codes game tags,
names, or instances. It exposes a registration API instead (`DoorSharedService:RegisterDoorTag(tag)`),
and a setup in Implementation feeds it at load. Make registration call-order independent, so a
late registration wires up live and loader order never matters.

**Loose coupling.** Find instances by tag, attribute, or name, and derive values from geometry
and state instead of hard-coding instances, axes, or signs. Keep responsibilities separate so each
piece can change without the others.

## Requires

| From | To | Write |
|---|---|---|
| Any module | its own child | `require("@self/_Child")` |
| Inside a system | a module in the same system | relative: `require("./DoorNetwork")`, `require("../SystemPackage/DoorSharedService")` |
| SystemPackage | anything outside its package | an object attribute on the `SystemPackage` folder, named after the module (see below) |
| Implementation | another system or a library | absolute: `require("@game/ServerScriptService/Modules/Systems/Gameplay/DoorSystem/SystemPackage/DoorSharedService")` |

A SystemPackage module requires an outside dependency in two lines, keeping `const` or `local`
as usual:

```lua
const TableUtilsHandle = script.Parent:GetAttribute("TableUtils")
const TableUtils = require(TableUtilsHandle:Wait() :: typeof(TableUtilsHandle))
```

- Set the attribute on the `SystemPackage` folder to the target module, named after it. A module
  nested inside the SystemPackage reaches the folder with a plain parent chain
  (`script.Parent.Parent` for a child of a module), so Studio can resolve it.
- The `:: typeof(Handle)` cast is what lets Studio type the module, exported types included. It
  stays until `:Wait()` returns a typed result on its own.
- Call `:Wait()` with no timeout: the dependency is expected to exist, and the loader warns when a
  require takes too long.
- Relocation never changes how a require is written: every form above resolves on both realms
  after relocation. The one gap is a module nested inside a relocated module, which code outside
  its parent can only reach through the parent's return table.
- Never require through `ReplicatedStorage.RELOCATED_MODULES` paths.

## Verifying

On top of the checks in CLAUDE.md:

- Run the relocation check in the reference after adding or moving modules.
- Start a playtest and read the output log, filtered by `>> Failed`, `Skipping :Start()`,
  `taking a while`, and `Loader attribute`. None should mention your modules. `[S]` lines come
  from the server and `[C]` lines from the client.
- The loader never runs in edit mode, so inspect its state during a playtest by running Luau in
  the server or client runtime. Check its version before requiring it outside a playtest (Luau run
  in edit mode, specs, stories): versions before v4.0.0 wait forever there (Side effects of
  requiring the loader, in the reference).
