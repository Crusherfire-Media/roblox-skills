I've moved PlacementRules out of ServerScriptService. In the place it is now the ModuleScript `ReplicatedStorage.Rules.BlockRules`, in a new `Rules` folder next to `Shared` and `Packages`. All checks pass, but I couldn't run the specs, and nothing is committed.

**What changed**
- **Project file:** `default.project.json` now mounts `src/ReplicatedStorage/Rules` as `ReplicatedStorage.Rules`.
- **The module:** `src/ReplicatedStorage/Rules/BlockRules.luau` has the same code as before. Only the module's own name changed, in its table and in its two error messages.
- **Designer values:** `BlockRules.meta.json` keeps `MaxReach = 24` and `MaxHeight = 200`.
- **`BlockPlacement.server.luau`:** now requires `ReplicatedStorage.Rules.BlockRules`.
- **`ClearBlocks.server.luau`:** both references are updated. That's the require, and the line that reads `MaxReach` straight off the module instance, which would otherwise have broken with no error until someone ran `/clearblocks`.
- **Spec:** moved to `Tests/Specs/Rules/BlockRules.spec.luau`, with the same three tests pointed at the new path.
- **Docs:** `docs/placement.md` points to the new module and spec paths, and the README's layout table lists the new `Rules` folder.
- **Old files:** I deleted the three old files with `git rm`. The `Placement` folders no longer exist, and a search finds no `PlacementRules` left anywhere except installed packages.

**Checks:** the sourcemap regenerated cleanly. `luau-lsp analyze` and `selene` reported 0 errors and 0 warnings, and `stylua --check` passed. The meta file has no byte order mark.

**Not done**
- **Specs not run:** no Studio connection was available, so the moved spec still needs a run in Studio or CI.
- **Blocked command:** some shell commands were refused because this session can't ask you for permission. I made the moves by writing the new files and running `git rm` on the old ones, so Git sees deletions plus new untracked files rather than renames. The new files under `src/ReplicatedStorage/Rules/` and `Tests/Specs/Rules/` still need a `git add`. I haven't committed.
- **`rojo serve`:** if it was running, check that it still is. Rojo 7.7.0 can crash when files are deleted. If it stopped, restart it and reconnect in Studio.

**What this means for the client:** the module now reaches clients, so its code and tuning values are visible to players. The server still runs `validate` itself before placing a block, so a client can only use these rules for the preview. It can't skip them.