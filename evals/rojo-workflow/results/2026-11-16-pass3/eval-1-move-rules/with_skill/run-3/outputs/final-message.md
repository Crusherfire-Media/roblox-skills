I moved `PlacementRules` to `ReplicatedStorage.Rules.BlockRules` and updated everything that pointed at it. Behavior is unchanged: the logic and the `MaxReach` (24) and `MaxHeight` (200) values are exactly as they were. I haven't run the specs, because they only run in Studio and I can't reach it. luau-lsp, selene and StyLua all pass, and a regenerated sourcemap shows `ReplicatedStorage.Rules.BlockRules`.

**What changed**
- **Project file:** `default.project.json` now mounts a new `Rules` folder (`src/ReplicatedStorage/Rules`) under ReplicatedStorage, next to `Shared` and `Packages`.
- **The module:**
  - `src/ReplicatedStorage/Rules/BlockRules.luau` holds the same code, with the module table and assert messages renamed to `BlockRules`.
  - `BlockRules.meta.json` sits beside it with the attribute values.
- **`BlockPlacement.server.luau`:** now requires `ReplicatedStorage.Rules.BlockRules`, and its header comment says `BlockRules`.
- **`ClearBlocks.server.luau`:** the string require now points to `@game/ReplicatedStorage/Rules/BlockRules`. It also read `MaxReach` from the old instance path, which would have broken after the move, so it now reads it from `ReplicatedStorage.Rules.BlockRules`.
- **Spec:** it moved to `Tests/Specs/Rules/BlockRules.spec.luau`, matching the new location. The test cases are the same.
- **Docs:** `docs/placement.md` gives the new path, where to tune the attributes, and the spec path. I also added a `Rules` row to the layout table in `README.md`.
- **Leftovers:** the old files are deleted, so the empty `ServerScriptService.Placement` folder is gone. Nothing in the repo refers to `PlacementRules` any more.

**Things to know**
- **Git state:** several shell commands were denied because this session can't approve them: `New-Item`, `git mv`, and `git add -A`. So I created the new files directly and deleted the old ones with `git rm`. The deletions are staged, but the new `src/ReplicatedStorage/Rules/` and `src/ServerScriptService/Tests/Specs/Rules/` folders are still untracked. Run `git add -A` before committing; git will then record these as renames. I haven't committed anything.
- **Rojo:** if `rojo serve` was running, check it's still up. Rojo 7.7.x can crash when files are deleted or moved, and Studio then quietly stops receiving changes.
- **Client visibility:** the module's code and its attributes now replicate to every client. That's what the preview needs and the rules hold nothing secret. The server still makes the final placement decision in `BlockPlacement`.