PlacementRules is now the ModuleScript `ReplicatedStorage.Rules.BlockRules`. Type checking, linting and formatting checks all pass, but I couldn't run the specs or check the move in Studio. Nothing is committed.

**What changed**
- **Project file:** `default.project.json` adds a `Rules` folder under ReplicatedStorage, between `Shared` and `Packages`, mapped to `src/ReplicatedStorage/Rules`.
- **The module:** `src/ServerScriptService/Placement/PlacementRules.luau` moved to `src/ReplicatedStorage/Rules/BlockRules.luau`. Inside it, only the name changed: the local table and the two error messages now say `BlockRules`.
- **Tuning values:** the attributes file moved with it, unchanged, to `BlockRules.meta.json`. `MaxReach` is still 24 and `MaxHeight` is still 200.
- **Scripts that use it:**
  - `BlockPlacement.server.luau` now requires `ReplicatedStorage.Rules.BlockRules`.
  - `ClearBlocks.server.luau` now requires `@game/ReplicatedStorage/Rules/BlockRules`. It also reads `MaxReach` from the module's new location, so it gained a `ReplicatedStorage` service line.
- **Spec:** it moved to `Tests/Specs/Rules/BlockRules.spec.luau`, next to where the module now lives, and requires the new path. The three tests themselves are the same.
- **Empty folders:** the old `Placement` folders under ServerScriptService and under the specs no longer exist.
- **Docs:** `docs/placement.md` points to the new instance, file and spec path, and says where to tune the values. I also added a `Rules` row to the folder table in `README.md`.

**Checks**
- No reference to `PlacementRules` or the old `Placement` path is left in the project.
- I rebuilt `sourcemap.json` with the new folder in it (Git doesn't track that file). `luau-lsp analyze`, `selene src` (0 errors, 0 warnings) and `stylua --check src` then all passed.

**Blocked or not checked**
- This session can't run anything that needs approval, which ruled out:
  - **Running the specs:** Studio isn't connected, so they haven't run.
  - **Bulk renames with `sed`:** I made those edits one at a time instead.
  - **Checking `rojo serve` with `netstat`:** if `rojo serve` was running, it may have crashed when the old files were deleted, because Rojo 7.7.x does that. Check it's still up (port 34872), and restart it if not. Then confirm `ReplicatedStorage.Rules.BlockRules` shows up in Studio with both attributes.
  - **Staging with `git add`:** the two moved Luau files and the spec are staged as renames, but their later edits and the other changed files aren't staged yet.
- **Server-side checks:** the server still runs the same checks as before. The client preview will be able to read the same rules, but the server stays the final check.