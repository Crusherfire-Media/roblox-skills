I made the move, but two shell steps were blocked, so the old files are still in the repo and you'll need to delete them yourself. The permission check turned down my attempts to create folders with `New-Item` and to run `git mv` / `git rm`. Instead, I wrote the new files directly and updated everything that pointed at the old ones.

**What changed**
- **`src/ReplicatedStorage/Rules/BlockRules.luau`** (new): the same code as before. Only the module's local name and its two `assert` messages now say `BlockRules`.
- **`src/ReplicatedStorage/Rules/BlockRules.meta.json`** (new): `MaxReach = 24` and `MaxHeight = 200`, unchanged.
- **`default.project.json`**: added a `Rules` folder under `ReplicatedStorage`, next to `Shared` and `Packages`. This was required because the project maps each `ReplicatedStorage` child separately, so Rojo wouldn't have picked up the new folder on its own.
- **`BlockPlacement.server.luau`**: now requires `ReplicatedStorage.Rules.BlockRules`.
- **`ClearBlocks.server.luau`**: updated the string require, and also the second reference that reads `MaxReach` straight from the module instance, which used the old `script.Parent.Placement...` path.
- **Spec**: moved to `Tests/Specs/Rules/BlockRules.spec.luau` so it sits at the same path as the module, and points at the new location. The test cases are unchanged.
- **Docs**: `docs/placement.md` has the new path, where to tune `MaxReach`/`MaxHeight`, and why the module lives in `ReplicatedStorage`. `README.md` lists the new `Rules` folder in its layout table.

**Please delete these old files:**
```
git rm -r src/ServerScriptService/Placement src/ServerScriptService/Tests/Specs/Placement
```
Until you do, Rojo still syncs a second copy of the module at `ServerScriptService.Placement.PlacementRules`, plus its old spec. Nothing else requires that copy, but Jest will run the old spec as well. If `rojo serve` is running, check it's still up after the delete: Rojo 7.7.x can crash when files are removed.

**Checks:** `stylua --check` passes, `selene src` reports 0 errors or warnings, and `luau-lsp analyze` reports no problems. The generated sourcemap shows `ReplicatedStorage.Rules.BlockRules` and `Tests.Specs.Rules.BlockRules.spec` where they should be. I couldn't reach Studio, so the spec hasn't been run and nothing has been playtested.

Making `BlockRules` reachable from the client doesn't add any client code that uses it; the preview script will need to require it.