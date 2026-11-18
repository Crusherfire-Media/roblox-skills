# CLAUDE.md

A Roblox game kept in Git and synced into Studio by Rojo. Each place in the experience is a folder
under `places/`, holding its Rojo project (`default.project.json`) and its code (`src/`). A new
game has one, `places/main`. pesde installs packages from `pesde.toml` into `roblox_packages/`
(`ReplicatedStorage.Packages`) and Jest from `test_packages/pesde.toml` into
`ServerScriptService.Tests.Packages`. The Module Loader runs every system: the two `Start` scripts
turn on its tag discovery and start it, the `LOAD_MODULE` tag on `Modules/Systems` marks what it
loads, and `ExampleSystem` shows the layout a system follows.

The `roblox-dev` plugin's skills hold this project's conventions: Luau style, comments,
architecture, Rojo, testing, performance, and UI. Load the matching skill before the first edit.

## Commands

Run everything from the repo root.

- `rokit install` after `rokit.toml` changes, and `pesde install` after either `pesde.toml` changes.
- `rojo serve places/main/default.project.json` syncs a place into Studio. Connect from the Rojo
  plugin in your own dev place for it.
- Specs run in Studio against the dev place, once Rojo has synced the files.

A change is done when these all pass, for each place it touches (shown for `main`; use the place's
folder name instead):

```
rojo build places/main/default.project.json -o game.rbxl
rojo sourcemap places/main/default.project.json -o sourcemap.json --absolute
luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json --definitions:@roblox=globalTypes.None.d.luau --ignore="**/roblox_packages/**" places/main/src
selene places tools
stylua --check places tools
```

Run each one as its own command, with nothing chained before or after it (no `; echo $?`). The
project's settings let these five run without asking only in exactly this form. The sourcemap
needs `--absolute`: Rojo writes paths relative to the place folder, and luau-lsp reads them
relative to the repo root.

`luau-lsp analyze` reads Roblox's types from `globalTypes.None.d.luau`. Download it once, and again
to pick up new engine APIs:
`curl -L -o globalTypes.None.d.luau https://luau-lsp.pages.dev/type-definitions/globalTypes.None.d.luau`

## Places

`places.json` maps each place folder to its place in each experience: the CI, staging, and
production universe ids, and each place's id in each of them. CI tests and publishes every place
listed there, so the three experiences need the same places. `null` means not set up yet, and the
jobs for that experience skip. Staging publishes only after the specs pass, so it also waits for
the CI experience. A place has a different id in each experience; ids are in the Creator
Dashboard URL, `.../experiences/<universe id>/places/<place id>/...`.

To add a place:

1. The person creates the place in each experience (Creator Dashboard, the experience's
   **Places** tab) and gives you its three place ids. Don't guess them.
2. Copy `places/main` to `places/<name>`, using a lowercase name with letters, digits, `_`, or
   `-`. Change the project's `name`, then remove the code and specs that belong only to `main`.
   Keep the `Start` scripts, the `Tests/Packages` project, and `Tests/Specs/jest.config.luau`.
   Keep or write at least one spec: CI fails a place whose `Tests/Specs` is missing or empty.
3. Add `"<name>": { "ci": <id>, "staging": <id>, "production": <id> }` under `places` in
   `places.json`.
4. Run the checks above for the new place. `lune run tools/ci/build` builds every place and fails
   when `places.json` and the folders disagree, or a set-up experience lacks a place's id.

Code two places share goes in a folder outside `places/` (for example `shared/`), mounted into
each place's project with a relative `$path` (`"../../shared/..."`). Add that folder to the
`selene` and `stylua --check` commands.

VS Code's luau-lsp types one place at a time, set by `luau-lsp.sourcemap.generatorCommand` in
`.vscode/settings.json`. Change its place folder to work on another place.

## CI

`.github/workflows` runs the checks above for every place and every place's specs (through Open
Cloud, in the CI experience) on each pull request. **Merging to `main` publishes every place to
the staging experience**, and publishing a GitHub release publishes them to production.
`tools/ci/README.md` covers the setup and what each failure means.

## Project specifics

- Rojo is pinned in `rokit.toml` (7.7.1) and in the `rojo` dev dependency in `pesde.toml` (7.7.0,
  the newest on pesde's registry). Change both together.
- Rojo 7.7.x can crash `rojo serve` when a folder is deleted or a folder module becomes a file
  module. Check that `rojo serve` is still running after those changes, and restart it if not.
- Write `IconTint` in a `.meta.json` with its type, `"IconTint": { "Color3": [1, 0, 0] }`. Every
  Rojo version accepts that form; 7.6.1 rejects the short one.
- `Workspace` sets `$ignoreUnknownInstances`, so Rojo syncs `src/Workspace` but leaves anything
  else in the place's Workspace alone. Things built in Studio stay out of Git until they're saved
  as files.
- Each place's `src/ServerScriptService/Tests/Packages/default.project.json` mounts
  `test_packages/roblox_packages` at `Tests.Packages`. Keep it in place.
