# Shared packages

How a game gets its dependencies through pesde, how Module Loader is installed, and how to lay
out your own shared package repo so several games can use it. Read it before adding a dependency,
a package, or a module to a package.

## Dependencies in a game

`pesde.toml` lists each dependency under the alias game code requires it by. The forms
([pesde docs](https://docs.pesde.dev/guides/dependencies/)):

```toml
[indices]
default = "https://github.com/pesde-pkg/index"

[wally_indices]
default = "https://github.com/UpliftGames/wally-index"

[dependencies]
# From the pesde registry
Signal = { name = "acme/signal", version = "^1.0.0" }
# From Wally, through pesde (no Wally install needed)
Charm = { wally = "littensy/charm", version = "=0.11.0" }
# From a Git repo, at a commit; `path` points at a package inside the repo
Inventory = { repo = "https://github.com/<you>/<shared-repo>.git", rev = "<full commit hash>", path = "packages/inventory" }
```

- `pesde add wally#scope/name`, `pesde add gh#owner/repo#rev`, or a registry name adds a line for
  you; check the alias it picked.
- Wally packages need a `sourcemap_generator` script in `pesde.toml` for luau-lsp to type them.
  `pesde init` with the `pesde/scripts_rojo` scripts package writes it, along with
  `roblox_sync_config_generator`.
- Pin exact versions (`=1.2.3`) for packages your code reaches into, and a full commit hash for
  Git dependencies, so an install months later gets the same code.
- Prefer few registries: every registry is a service that can be down when CI or a developer
  installs.

## Installing Module Loader

[Module Loader](https://github.com/ActualFire-Games/module-loader) (MIT) is published on Wally
as `crusherfire/module-loader`; it has no native pesde package, so pesde installs it through the
Wally index:

```toml
[wally_indices]
default = "https://github.com/UpliftGames/wally-index"

[dependencies]
ModuleLoader = { wally = "crusherfire/module-loader", version = "=4.0.1" }
```

Check the [releases](https://github.com/ActualFire-Games/module-loader/releases) for a newer
version before pinning. 4.0.1 is the minimum with pesde: it fixed relocation of modules under
folders with dots in their names, such as `.pesde` and version folders.

**Where it mounts.** Both `Start` scripts require the loader before anything else runs, so it has
to sit where the client can reach it at once: under ReplicatedStorage.

- When `roblox_packages` mounts under ReplicatedStorage, the loader comes with it. Require it
  through its link: `require("@game/ReplicatedStorage/Packages/ModuleLoader")`.
- When `roblox_packages` mounts under ServerScriptService (so the loader relocates only what
  clients need), install the loader in its own pesde workspace member (for example
  `boot_packages/pesde.toml`, listed in the root's `workspace_members`) and mount that member's
  installed folder under ReplicatedStorage. A `$path` that names the installed folder carries the
  version (read the link in `boot_packages/roblox_packages/ModuleLoader.luau` for it), so change it
  together with the pin.

**Settings.** The loader reads its settings from attributes on the ModuleLoader script. Set them
with `$attributes` on the node that mounts the loader's own folder, or call
`ModuleLoader.ChangeSettings({ ... })` in each `Start` script before `Start()`. The
`game-architecture` skill's Module Loader reference lists every setting.

## A shared package repo

To share systems and libraries between your games, keep them in one repo as a pesde workspace,
and have each game depend on it by Git `rev`.

- The root `pesde.toml` sets `private = true` and `workspace_members = ["packages/*"]`. Each
  package is `packages/<snake_name>/` with its own `pesde.toml` (`name = "<scope>/<snake_name>"`).
- Set `private = true` in every package that is only installed from Git, so a stray
  `pesde publish` can't push it to the public registry.
- After adding a package, run `pesde install` at the repo root and commit the updated root
  `pesde.lock`.
- pesde ignores a `default.project.json` inside a Git dependency and writes each package's Rojo
  config itself from `build_files`, so a package never ships one.
- A package depends on another workspace package by alias:

  ```toml
  [dependencies]
  Signal = { workspace = "<scope>/signal", version = "^" }
  ```

- No two packages may depend on each other, directly or through others. Code both sides need goes
  into its own small package.
- Specs of a package's behavior live in the repo's own `tests/` tree, outside every package
  folder, so they never ship with an installed package. The `roblox-testing` skill's package-repo
  reference covers writing and running them.

## Two layouts

Every package keeps its code in `src/` with `build_files = ["src"]`.

- **Library** (no lifecycle): `lib = "src/init.luau"`, so `src` is the library module and its other
  files are its children. Games require it as the package, which keeps its exported types.
- **System** (has `Init`/`Start`, run by Module Loader): `src` has no `init.luau`, so it stays a
  Folder and the loader finds the services in it. When the game's `Packages` folder carries
  `IgnoreLoader: true`, `src/init.meta.json` sets `IgnoreLoader: false` to override it. `lib`
  points at an index, `src/<Name>System.luau`, marked `IgnoreLoader: true` in its `.meta.json`.
  The index requires a service only when a caller first reads it, so a client never touches a
  server-only module, and it re-exports the types of the modules both realms load.

**A library's entry module loads on both realms**, since shared code on either can require it.
Keep require time free of side effects: no instances, engine connections, or client-only setup.
Connect engine signals on first use, and put client-only setup behind
`RunService:IsRunning() and RunService:IsClient()` or in its own package. When server code needs
one piece of a client library, move that piece into its own package so the server never loads the
rest.

A module whose returned table errors on unknown keys needs `IgnoreLoader: true`: the loader reads
`Init` and `Start` off every module it requires.

## Requires inside a package

- Within the package: relative paths, the same as anywhere (`./Sibling`, `@self/Child`).
- Another package: through pesde's link beside `src`. From a library's `src/init.luau`, that is
  `require("./roblox_packages/<Alias>")`; from a module in a system's `src` folder,
  `require("../roblox_packages/<Alias>")`. The alias must be in the package's `pesde.toml`.
- Game code: only through a **slot**, a game module at a fixed path that every game using the
  package provides because the package needs its types or data (a profile template, say).
  Document each slot's path and shape in the package's README, and keep the list short.

## Settings a game changes

A package reads per-game settings from a registration API a game's setup module calls, or from
attributes on its own root with defaults in code. An install replaces the package's files, so a
game never edits an installed package to change a setting.

## Moving game code into a package

1. Copy the system or library into `packages/<snake_name>/src/`, resolve every require against the
   package's own tree, and add each dependency it needs to its `pesde.toml`.
2. Move the specs of the code's own behavior to the package repo's `tests/`. Specs of the game's
   setups, mediators, and catalogs stay in the game.
3. Push, add the dependency to the game's `pesde.toml` at that commit, install, delete the game's
   copy, and rewrite the game's requires to the package alias.
4. Run the game's specs and a playtest.
