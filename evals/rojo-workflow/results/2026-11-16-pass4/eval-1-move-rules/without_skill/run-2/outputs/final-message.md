`PlacementRules` is now the ModuleScript `ReplicatedStorage.Rules.BlockRules`, and all the code and docs that referred to it now point there. The project's checks pass (selene, stylua and luau-lsp: 0 errors, 0 warnings), and the sourcemap shows `Rules` under `ReplicatedStorage` with `BlockRules` inside it. I couldn't run the Jest specs, because they only run in Studio.

**What moved**
- **The module:** it's now `src/ReplicatedStorage/Rules/BlockRules.luau`. The logic is unchanged; I only renamed the local table to `BlockRules`, which also changes the wording of its two "needs a … attribute" error messages.
- **Designer values:** the settings file moved too, as `BlockRules.meta.json`. Its name has to match the module's for the values to load, and `MaxReach` (24) and `MaxHeight` (200) are unchanged.
- **The spec:** it's now `Tests/Specs/Rules/BlockRules.spec.luau` and loads `ReplicatedStorage.Rules.BlockRules`.
- **The empty folder:** the old `ServerScriptService.Placement` folder had nothing else in it, so it's gone.

**References updated**
- `default.project.json`: added the `Rules` folder under `ReplicatedStorage`, next to `Shared` and `Packages`.
- `BlockPlacement.server.luau`: now requires `ReplicatedStorage.Rules.BlockRules`, and its header comment is updated.
- `ClearBlocks.server.luau`: this one referred to the old location in two ways. Its require now uses `@game/ReplicatedStorage/Rules/BlockRules`, and it reads `MaxReach` from `ReplicatedStorage.Rules.BlockRules`, which needed a `ReplicatedStorage` lookup added.
- `docs/placement.md` and the README layout table describe the new location.

A search finds no remaining mentions of `PlacementRules` or the old paths.

**About the git history:** the permission settings blocked the shell commands for moving files, so I wrote the new files fresh and removed the old ones with `git rm`. The old files are staged as deleted, but the new ones aren't staged yet. Once you run `git add` on them, git should recognise these as renames. I haven't committed anything.