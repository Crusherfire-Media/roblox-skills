I've added `t` and switched the `PlaceBlock` handler to it, but I couldn't run anything here, so none of it has been run or type-checked yet.

**This repo uses pesde, not Wally.** There's no `wally.toml`. Wally packages come in through pesde's `[wally_indices]`, so I added `t` to `pesde.toml` the same way as the other dependencies:
```toml
t = { wally = "osyrisrblx/t", version = "=3.1.1" }
```
3.1.1 is the latest version on the Wally index, and it's pinned exactly like the others. Rojo already maps `roblox_packages` to `ReplicatedStorage.Packages`, so the handler loads it with `require(ReplicatedStorage.Packages.t)` and `default.project.json` doesn't need to change.

**Handler (`src/ServerScriptService/BlockPlacement.server.luau`):**
- The string and `Vector3` type checks are now one `t.tuple(t.string, t.intersection(t.Vector3, notNaN))` check.
- `t.Vector3` doesn't reject NaN, so the old `value ~= value` check is kept as a small custom check (`notNaN`) combined with it.
- `t` doesn't tell the Luau type checker what the arguments are, so the handler casts them to `string` and `Vector3` once the check passes.
- Everything else is unchanged: the block-type lookup, rate limit, root-part check, below-ground and occupied-cell checks, and reach check. Bad calls still return without doing anything, and extra arguments are still ignored.

**Before you test** (these steps are also in `PR_DESCRIPTION.md`, with a table of the checks and a test plan):
1. Run `pesde install`. Until you do, `roblox_packages/t.luau` doesn't exist and the script will error at startup.
2. Commit the updated `pesde.lock`. Git tracks it, and I couldn't regenerate it.
3. If you use luau-lsp, regenerate `sourcemap.json` so the editor can find `t`.

My first shell command to look at the repo was blocked by the permission check, so I read the files with the file tools instead. Nothing is committed.