# game-architecture evals (M12)

Five tasks and a trigger set for the `game-architecture` skill. How to run them is in
`../README.md`.

## Fixtures

Four tasks start from a Module Loader project laid out the way the skill describes, added with
`setup_files` (whole `src` trees copied over the sandbox):

- `tasks/fixtures/base/`: the two bootstrap scripts (`Main.server.luau`, `Main.client.luau`) that
  require `ReplicatedStorage.Packages.ModuleLoader`, call `ChangeSettings({ USE_COLLECTION_SERVICE
  = true })`, and `Start()`; `Modules/Systems` (tagged `LOAD_MODULE`, `RelocateToReplicatedStorage`),
  `Modules/Catalogs/BlockTypes` and `Modules/Utilities/Grid` (also `IgnoreLoader`); and
  `Systems/Core/NotificationSystem` with SystemPackage and Implementation folders, tints, a network
  module whose remote is a child instance, and realm attributes in `.meta.json` files.
- `tasks/fixtures/placement/`: a finished `Systems/Gameplay/PlacementSystem` (server service,
  client service, network module, notification mediator). It is also the hand-made answer the
  `placement-system` checks were verified against.
- `block-cost/`, `startup/`, `admin/`: the extra systems for those tasks.
- `plain/`: no Module Loader. The vide pilot's placement files (`BlockTypes` in
  `ReplicatedStorage/Shared`, `BlockPlacement.server.luau`, the `BlockPlacer` module started from
  `Main.client.luau`).

The bootstrap scripts are named `Main`, not `Start` as the skill names them, because the sandbox
already has `Main.server.luau` and `Main.client.luau` and `setup_files` can only add or overwrite
files. The fixtures pass luau-lsp, selene, and StyLua in the sandbox apart from the planted bugs.

## Tasks

| Task | What it tests |
|---|---|
| `placement-system` | The demo's main task: build block placement as a new system in the Module Loader project. A `<Name>System` folder with SystemPackage and Implementation, no new Script or LocalScript, the server module kept off clients (`RelocateToServerScriptService`), the client module `ClientOnly`, no yields on the loader's thread, requires that work after relocation, and the too-far notification through NotificationSystem. |
| `block-cost` | Adding a require without a cycle. `CurrencyServerService` already requires `PlacementServerService` for passive income, so the obvious change (placement requiring currency to charge for blocks) is a cycle, lazy or not. Rewards a mediator, a hook on placement, or removing the old edge, plus charging only after every other check passes. |
| `startup-order` | Fixing two load-order bugs from pasted loader output: a mediator whose `Init` reads plots that another module creates in its own `Init` (equal priorities, so it fails in some playtests), and a `Start` that waits for `IsServerLoaded()` and runs the round loop inline, so the server never finishes and clients with `WAIT_FOR_SERVER` never load. |
| `admin-realm` | Moving a module to the right realm. The admin ID list relocates to clients; marking it `RelocateToServerScriptService` alone breaks `AdminSharedService`, which is copied to clients and requires it relatively, so the client has to learn admin status another way. Also a client setup module missing `ClientOnly` (fails on the server) and a `ClientOnly` attribute stored as the string `"true"`. |
| `plain-removal` | The plain sandbox with no Module Loader: add block removal (right-click, long press, owner only, server checks). Rewards fitting the existing script-and-module project; checks fail an attempt that adds a module loader, `LOAD_MODULE` tags, or a `ServerScriptService/Modules` tree. |

## Checks

- `placement-system`: a new module sits in a `<Name>System/SystemPackage` or `Implementation`
  folder; no Script or LocalScript besides the two `Main` scripts; every new module that handles a
  remote on the server is kept off clients; every new client module is `ClientOnly`. The realm
  checks are a static model of Module Loader 4.0.1's rules over the `.meta.json` files (Folder
  cascade, module-only `RelocateToServerScriptService`, nested modules follow their parent), and
  they find new modules through `git status`.
- `block-cost`: runs `rojo sourcemap` and `luau-lsp analyze src` and fails on any cyclic
  dependency. luau-lsp 1.70.1 reports a cycle even when one require is inside a function.
- `startup-order`: `RoundServerService`'s `Init` and `Start` no longer wait or loop before
  handing off to `task.spawn`, `task.defer`, or a coroutine. The plot fix has no check, because
  several fixes are valid (Start, lazy plot creation, LoaderPriority).
- `admin-realm`: every module holding the admin IDs stays on the server; no module copied to
  clients requires `AdminList`; `_HudClientSetup` is `ClientOnly` (itself or its folder);
  HudClientService's `ClientOnly` is no longer a string.
- `plain-removal`: no module loader setup or `Modules` tree, the two placement files still exist,
  and some client code handles `MouseButton2`.

Every check was run on the untouched starting point (it fails where the task needs work) and on a
hand-made answer (it passes), plus a wrong answer where one was easy to build: placement without
realm attributes, a lazy cyclic require, a `Start` that still waits for a player, the meta-only
admin fix, and a plain project given a `LOAD_MODULE` folder.

## Notes

- The Module Loader `judge_facts` are verified against
  `roblox_packages/.pesde/crusherfire_module-loader@4.0.1/module-loader/src/init.luau`. The cycle
  fact was verified by running luau-lsp 1.70.1 on a two-module cycle in the sandbox.
- `triggers.json` holds 10 queries the description says should load the skill and 10 near misses
  (Vide, Jest, profiling, Rojo setup, pesde, comments, plain Luau, a one-constant edit, Knit).
  Labels follow the description as written, so "add a small helper module" and "add a LocalScript"
  are `true` even in a project that doesn't use Module Loader.
