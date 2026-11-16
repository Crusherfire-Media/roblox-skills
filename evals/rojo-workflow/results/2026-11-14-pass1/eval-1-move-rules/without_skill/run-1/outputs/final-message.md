I moved PlacementRules out of ServerScriptService. In the place it is now the ModuleScript `ReplicatedStorage.Rules.BlockRules`, in a new `Rules` folder next to `Shared` and `Packages`. I couldn't run any of the project's checks, so none of this is verified yet.

**What changed**
- **`default.project.json`**: added `ReplicatedStorage.Rules` pointing at `src/ReplicatedStorage/Rules`.
- **`src/ReplicatedStorage/Rules/BlockRules.luau`**: the module, with the same logic as before. Only the internal name changed (the local table and the two `assert` messages now say `BlockRules`).
- **`src/ReplicatedStorage/Rules/BlockRules.meta.json`**: carries the attributes over unchanged, `MaxReach = 24` and `MaxHeight = 200`.
- **`BlockPlacement.server.luau`**: now requires `ReplicatedStorage.Rules.BlockRules`.
- **`ClearBlocks.server.luau`**: the string require is now `@game/ReplicatedStorage/Rules/BlockRules`. It also read `MaxReach` straight off the old instance path, and that now points to `ReplicatedStorage.Rules.BlockRules` too. If I'd missed this one, `/clearblocks` would have broken when it ran.
- **Spec**: moved to `Tests/Specs/Rules/BlockRules.spec.luau` and requires the new path. The tests themselves are unchanged.
- **Docs**: updated `docs/placement.md` (module path, why it lives in ReplicatedStorage, spec path) and added a `Rules` row to the README layout table.
- **Cleanup**: deleted the old files and the now-empty `Placement` folders. A search finds no remaining references to `PlacementRules` or the old paths.

**What was blocked**
- **`git mv`** wasn't allowed in this session. I wrote the new files and deleted the old ones instead, so git will show deletes and adds rather than renames. Git usually matches renames by content when you commit or diff, so the history should still follow the files.
- **The README checks** were blocked too: `rojo sourcemap`, `luau-lsp analyze`, `selene` and `stylua --check`. I checked line lengths against the 100-column stylua limit by hand. Please run the four commands from the README before you merge, and run the Jest specs in Studio to be sure.

Nothing is committed.