PlacementRules is now the ModuleScript `ReplicatedStorage.Rules.BlockRules`, and every reference to it is updated. Analysis, selene and StyLua all pass on `src`. I haven't run the specs, because they only run in Studio and I don't have it here. I haven't checked a live `rojo serve` either, and nothing is committed.

**The move** (with `git mv`, so file history follows):
- `src/ServerScriptService/Placement/PlacementRules.luau` → `src/ReplicatedStorage/Rules/BlockRules.luau`
- `PlacementRules.meta.json` → `src/ReplicatedStorage/Rules/BlockRules.meta.json`. The attributes moved unchanged (`MaxReach` 24, `MaxHeight` 200), so behavior and the designer-tuned values stay the same.
- The old `Placement` folder is gone, since nothing else was in it.

**References updated:**
- **`default.project.json`:** added a `Rules` mount under `ReplicatedStorage`, between `Shared` and `Packages`.
- **`BlockRules.luau`:** renamed the module's own table and changed its `assert` messages to say BlockRules.
- **`BlockPlacement.server.luau`:** now requires `ReplicatedStorage.Rules.BlockRules`.
- **`ClearBlocks.server.luau`:** the require changed to `@game/ReplicatedStorage/Rules/BlockRules`. Its `MaxReach` lookup used to go through `script.Parent.Placement` and now reads `ReplicatedStorage.Rules.BlockRules`. Missing that lookup would have broken `/clearblocks`.
- **The spec:** moved to `Tests/Specs/Rules/BlockRules.spec.luau` so it mirrors the new location. It now requires the module from `ReplicatedStorage`, and its `describe` is renamed. The test cases are unchanged.
- **`docs/placement.md` and `README.md`:** new paths, where to tune the attributes, and a row for the new `Rules` folder in the README layout table.

A search for `PlacementRules` and the old `Placement/` paths outside the installed packages finds nothing left.

**If `rojo serve` is running into your dev place:** this change deleted and renamed watched folders, which can crash Rojo 7.7.x without any message in Studio. Check that it's still running, and reconnect it if it stopped. Also, Rojo picks up a new `$path` mount in `default.project.json` only after a restart, so restart it anyway so the `Rules` folder appears in Studio. Then run `Tests.Specs.Rules.BlockRules.spec` in Studio to confirm the move.