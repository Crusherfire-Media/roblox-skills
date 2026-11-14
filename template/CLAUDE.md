# CLAUDE.md

A Roblox game kept in Git and synced into Studio by Rojo. Game code is the files under `src/`.
pesde installs packages from `pesde.toml` into `roblox_packages/` (`ReplicatedStorage.Packages`)
and Jest from `test_packages/pesde.toml` into `ServerScriptService.Tests.Packages`. The Module
Loader runs every system: the two `Start` scripts start it, and `ExampleSystem` shows the layout a
system follows.

The `roblox-dev` plugin's skills hold this project's conventions: Luau style, comments,
architecture, Rojo, testing, performance, and UI. Load the matching skill before the first edit.

## Commands

Run everything from the repo root.

- `rokit install` after `rokit.toml` changes, and `pesde install` after either `pesde.toml` changes.
- `rojo serve` syncs `src/` into Studio. Connect from the Rojo plugin in your own dev place.
- Specs run in Studio against the dev place, once Rojo has synced the files.

A change is done when these all pass:

```
rojo build default.project.json -o build/game.rbxl
rojo sourcemap default.project.json -o sourcemap.json
luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json --definitions:@roblox=globalTypes.None.d.luau --ignore="**/roblox_packages/**" src
selene src tools
stylua --check src tools
```

`luau-lsp analyze` reads Roblox's types from `globalTypes.None.d.luau`. Download it once, and again
to pick up new engine APIs:
`curl -L -o globalTypes.None.d.luau https://luau-lsp.pages.dev/type-definitions/globalTypes.None.d.luau`

## CI

`.github/workflows` runs the checks above and every spec (through Open Cloud, in a CI place) on each
pull request. **Merging to `main` publishes to the staging place**, and publishing a GitHub release
publishes to production. `tools/ci/README.md` covers the setup and what each failure means.

## Project specifics

- Rojo is pinned to 7.6.1, in `rokit.toml` and in the `rojo` dev dependency in `pesde.toml`.
  Change both together, then run `rojo plugin install` so the Studio plugin matches.
- Write `IconTint` in a `.meta.json` with its type, `"IconTint": { "Color3": [1, 0, 0] }`, since
  Rojo 7.6.1 rejects the short form.
- `src/ServerScriptService/Tests/Packages/default.project.json` mounts
  `test_packages/roblox_packages` at `Tests.Packages`. Keep it in place.
