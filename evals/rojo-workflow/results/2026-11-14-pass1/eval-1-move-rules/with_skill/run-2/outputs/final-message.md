The move is done except for one step: deleting the old files was blocked. This session can't approve `git rm` or `New-Item`, so I couldn't delete anything or use `git mv`. Until you remove them, the old copies stay in the repo and still sync into Studio. Run this from the project root:

```sh
git rm src/ServerScriptService/Placement/PlacementRules.luau src/ServerScriptService/Placement/PlacementRules.meta.json src/ServerScriptService/Tests/Specs/Placement/PlacementRules.spec.luau
```

While they're there, there are two copies of the module and two specs, and a designer could tune the attributes on the old `PlacementRules` without changing anything. Nothing requires the old module any more.

**What changed:**
- **The module:** it's now `src/ReplicatedStorage/Rules/BlockRules.luau`, with the same logic. Only the name changed: the local table and the two assert messages now say `BlockRules`.
- **The tuning values:** `BlockRules.meta.json` sits next to it with the same values, `MaxReach` 24 and `MaxHeight` 200. The module still reads them from its own attributes, so designers tune it the same way.
- **`default.project.json`:** adds the `ReplicatedStorage.Rules` folder next to `Shared` and `Packages`.
- **`BlockPlacement.server.luau`:** now requires `ReplicatedStorage.Rules.BlockRules`.
- **`ClearBlocks.server.luau`:** the require now points to `@game/ReplicatedStorage/Rules/BlockRules`. It also read `MaxReach` straight off the old instance path (`script.Parent.Placement.PlacementRules`), which would have broken after the move; it now reads `ReplicatedStorage.Rules.BlockRules`.
- **The spec:** it's now `Tests/Specs/Rules/BlockRules.spec.luau`, with the same three tests pointed at the new path.
- **Docs:** `docs/placement.md` has the new path, where the tuning values live, and the new spec path. The README layout table lists `src/ReplicatedStorage/Rules`.

**Checks:** `stylua --check`, `selene` (0 errors, 0 warnings) and `luau-lsp analyze` against a fresh sourcemap all came back clean. I couldn't run the spec, because specs only run in Studio and this project has no Studio connection.

**Two things to know:**
- **The source is now public.** The client can read these rules, but every client can now also see the module's code and the reach and height limits. The server still checks every placement, so behavior is the same.
- **Rojo:** if you're running `rojo serve`, check it's still up after deleting the old files. Rojo 7.7.x can crash on deletes and silently stop syncing. You'll also need to restart it so it picks up the new `Rules` folder in `default.project.json`.

Nothing is committed.