I've added t and switched the PlaceBlock handler to it, but nothing can actually load it until you run `pesde install`. StyLua and selene pass; I couldn't run the type checker (`luau-lsp`) or test in Studio, since both need the package installed first.

**Adding the package:** this repo has no `wally.toml`. pesde installs everything, pulling Wally packages through the `wally_indices` entry in `pesde.toml`. So I added this line there, pinned exactly like the other packages:
```toml
t = { wally = "osyrisrblx/t", version = "=3.1.1" }
```
3.1.1 is the newest version on the Wally index. It shows up as `ReplicatedStorage.Packages.t`, and I added it to the package table in `README.md`.

**The handler** (`src/ServerScriptService/BlockPlacement.server.luau`): the hand-written type and NaN checks are now a single t check, `t.tuple(t.string, t.intersection(t.Vector3, notNaN))`. Every check the handler did before is still there:
- **Name and position types:** handled by `t.string` and `t.Vector3`.
- **NaN:** `t.Vector3` only checks the type, so a position like `Vector3.new(0/0, 4, 0)` would get through. I kept the old NaN check as a small `notNaN` function and combined it with `t.Vector3`. If you copy this pattern for future remotes, remember that NaN positions need that extra check.
- **Everything else is unchanged:** the block-type lookup, rate limit, character check, Y ≥ 0, occupied cell and reach limit. Extra arguments are still ignored, as before.

**Before testing** (also in `PR_DESCRIPTION.md`): I didn't touch `pesde.lock`. Until you install, the script fails to load at startup because the `require` can't find t. Run `pesde install`, regenerate the sourcemap with the `rojo sourcemap` command from the README, then commit the updated `pesde.lock`. The PR description also lists some bad `FireServer` calls to try in Studio, and none of them should place a block.

I haven't committed anything.