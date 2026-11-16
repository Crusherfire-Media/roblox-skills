I've moved the module. `src/ReplicatedStorage/Rules/BlockRules.luau` is now the ModuleScript `ReplicatedStorage.Rules.BlockRules`, in a new `Rules` folder next to `Shared` and `Packages`. Everything that pointed at the old location has been updated. Type-checking, linting and the formatting check all came back clean, but I haven't run the specs: this project can't reach Studio.

**What changed**
- **Moves (done with `git mv`):**
  - `PlacementRules.luau` and `PlacementRules.meta.json` are now `src/ReplicatedStorage/Rules/BlockRules.luau` and `BlockRules.meta.json`. The old `Placement` folder is gone.
  - The spec is now `Tests/Specs/Rules/BlockRules.spec.luau`.
- **`default.project.json`:** added a `Rules` entry under `ReplicatedStorage`. It needs its own entry because `ReplicatedStorage` has no `$path`.
- **Requires:**
  - `BlockPlacement.server.luau` now requires `ReplicatedStorage.Rules.BlockRules`.
  - `ClearBlocks.server.luau` uses the string require `@game/ReplicatedStorage/Rules/BlockRules`. It also reads the `MaxReach` attribute from the new location, which would otherwise have errored at runtime.
- **Renames:** the table and local names went from `PlacementRules` to `BlockRules`, matching the new module name. The two assert messages now say "BlockRules needs a … attribute". The spec's `describe` is now "BlockRules"; the test cases themselves are unchanged.
- **Docs:** `docs/placement.md` has the new path, spec name and where to tune values. I added a `Rules` row to the layout table in `README.md`.

**Behavior:** the validation logic is unchanged. `MaxReach` (24) and `MaxHeight` (200) are still attributes on the ModuleScript, kept in the renamed `.meta.json`, so designers tune them in the same way.

**Checks:** I regenerated `sourcemap.json`, and it shows the new path. `luau-lsp analyze`, `selene` (0 errors, 0 warnings) and `stylua --check` all passed on `src`. A search finds no remaining references to `PlacementRules` or the old `Placement` paths.

**Blocked:** the port check to see whether `rojo serve` is still running was denied, because commands needing approval can't be approved in this session. Rojo 7.7.x can crash when folders are moved under it. If you have it running, make sure it's still up, or restart it and reconnect, before trusting what's in Studio. Once you're connected, run the `BlockRules.spec`.

I haven't committed anything.