`PlacementRules` is now the ModuleScript `ReplicatedStorage.Rules.BlockRules`, and every reference, the spec and the docs point to the new location. The regenerated sourcemap places `ReplicatedStorage.Rules` (a Folder) with `BlockRules` (a ModuleScript) inside it, carrying its `.meta.json`. The luau-lsp type check, selene and stylua all pass. The specs only run in Studio, so I haven't run them. I also couldn't do a `rojo build`, because the session blocked that command.

**What moved**
- **The module:** `src/ServerScriptService/Placement/PlacementRules.luau` is now `src/ReplicatedStorage/Rules/BlockRules.luau`. The logic is unchanged; only the local table name and the two assert messages now say `BlockRules`.
- **Designer values:** `BlockRules.meta.json` sits next to the module with the same attributes, `MaxReach = 24` and `MaxHeight = 200`.
- **Project file:** `default.project.json` has a new `Rules` entry under ReplicatedStorage, next to `Shared` and `Packages`.
- **Old folder:** the now-empty `Placement` folder is gone, so `ServerScriptService.Placement` no longer exists in the place.

**Updated references**
- `BlockPlacement.server.luau` now requires `ReplicatedStorage.Rules.BlockRules`.
- `ClearBlocks.server.luau` had two references: the string require is now `@game/ReplicatedStorage/Rules/BlockRules`, and the `MaxReach` attribute read now points to `ReplicatedStorage.Rules.BlockRules`.
- The spec moved to `Tests/Specs/Rules/BlockRules.spec.luau` and requires the new path.
- `docs/placement.md` and the README layout table describe the new location.

The session blocked `git mv`, so I created the new files and deleted the old ones. Git therefore shows deletions plus new untracked files rather than renames. Running `git add -A` should let Git detect them as renames. I haven't committed anything.