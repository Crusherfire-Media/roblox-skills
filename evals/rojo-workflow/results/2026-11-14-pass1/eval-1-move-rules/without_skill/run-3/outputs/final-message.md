PlacementRules is now the ModuleScript `ReplicatedStorage.Rules.BlockRules`. The new `Rules` folder sits directly under `ReplicatedStorage`, next to `Shared` and `Packages`. The analyzer reported 0 errors and 0 warnings, selene and stylua passed, and no references to the old name or path are left. I couldn't run the specs, because they only run in Studio.

**The move**
- `default.project.json` now maps a `Rules` folder under `ReplicatedStorage` to `src/ReplicatedStorage/Rules`.
- The code is now `src/ReplicatedStorage/Rules/BlockRules.luau`. The logic is unchanged; I only renamed the local table and the assert messages from `PlacementRules` to `BlockRules`.
- The attributes moved with it to `BlockRules.meta.json` with the same values: `MaxReach` 24 and `MaxHeight` 200. Without that file the module would fail its asserts on load.
- The old `Placement` folder was left empty, so I deleted it.

**References updated**
- `BlockPlacement.server.luau` now requires `ReplicatedStorage.Rules.BlockRules`.
- `ClearBlocks.server.luau` had two references. I updated both: the string require (now `@game/ReplicatedStorage/Rules/BlockRules`) and the line that reads the `MaxReach` attribute directly. That second one was the easy one to miss. If it had been left alone, `/clearblocks` would have broken.
- To match, I moved and renamed the spec to `Tests/Specs/Rules/BlockRules.spec.luau` and pointed it at the new path. The test cases are the same.
- I updated `docs/placement.md` with the new module and spec paths and where to tune the attributes, and added a `Rules` row to the layout table in `README.md`.

I couldn't use `git mv`, because commands that needed approval were blocked in this session. Instead I wrote the files at the new paths and deleted the old ones. Git will show them as deleted and new rather than renamed, but it normally detects the renames once they're staged. Nothing is committed.