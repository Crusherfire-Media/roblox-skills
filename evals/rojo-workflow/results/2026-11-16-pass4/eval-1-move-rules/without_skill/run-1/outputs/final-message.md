`PlacementRules` is now the ModuleScript `ReplicatedStorage.Rules.BlockRules`, and every reference to it is updated. I haven't built or tested it: running Rojo or the specs needs approval this session can't give.

**What changed**
- **`default.project.json`**: added a `Rules` folder under `ReplicatedStorage`, next to `Shared` and `Packages`, mapped to `src/ReplicatedStorage/Rules`.
- **`src/ReplicatedStorage/Rules/BlockRules.luau`**: the moved module. The logic is the same. The only edits are the local name and the assert messages (`PlacementRules` → `BlockRules`), plus a note that it lives in ReplicatedStorage so the client can use it.
- **`src/ReplicatedStorage/Rules/BlockRules.meta.json`**: the attributes moved over unchanged, so `MaxReach` is still 24 and `MaxHeight` is still 200.
- **`BlockPlacement.server.luau`**: now loads it with `require(ReplicatedStorage.Rules.BlockRules)`.
- **`ClearBlocks.server.luau`**: the string require now points to `@game/ReplicatedStorage/Rules/BlockRules`. It reads the `MaxReach` attribute from `ReplicatedStorage.Rules.BlockRules`, which needed a `ReplicatedStorage` service lookup added to the file.
- **Spec**: moved to `Tests/Specs/Rules/BlockRules.spec.luau` and now requires the module from ReplicatedStorage. The test cases are the same.
- **`docs/placement.md`**: updated the module path and spec path, and said where to tune the attributes.

The old files are gone and nothing in the repo refers to `PlacementRules` or the `Placement` folder any more. `sourcemap.json` never listed this module, so it didn't need changing.

**Two things to know**
- **Git won't track this as a rename.** The shell commands to create the new folders and move the files were blocked, so I wrote the new files directly. The old files are deleted and staged, but the new files are untracked and the edits to existing files aren't staged. Running `git add -A` should let Git detect the renames and keep the history.
- **Please check it builds.** Run `rojo build` (or serve it) and the Jest specs.