I added t to the project and switched the PlaceBlock handler to it, keeping every check it did before. Nothing has been run: I didn't install anything, and the session also blocked my shell commands, so the type checker, selene and stylua haven't checked this either.

This repo manages packages with **pesde**, not Wally directly. pesde pulls Wally packages through its `[wally_indices]` entry, so I added t the same way as Vide, Charm and the rest.

**Changes**
- **`pesde.toml`**: added `t = { wally = "osyrisrblx/t", version = "=3.1.1" }`. 3.1.1 is the latest version in the Wally index, and it's pinned exactly like the other dependencies.
- **`src/ServerScriptService/BlockPlacement.server.luau`**: the arguments are now checked with `t.tuple(t.string, isPlainVector3)`, using `require(ReplicatedStorage.Packages.t)`. `t.Vector3` only checks the type and would let a position with a NaN component through. So `isPlainVector3` runs `t.Vector3` and then keeps the existing `value ~= value` NaN check. The block-type lookup, rate limit, character check, below-ground check, occupied-cell check and reach check are unchanged. Bad calls are still dropped without a message.
- **`README.md`**: added t to the package table.
- **`PR_DESCRIPTION.md`**: has a table matching each old check to its new form, the steps to do before testing, and a Studio test plan.

**Before testing** (also in the PR description): `pesde.lock` and `roblox_packages/` haven't been updated yet, so the `require` will fail until you install. Run `pesde install`, commit the updated `pesde.lock`, then rebuild the sourcemap and run the README checks (luau-lsp, selene, stylua).

I haven't committed anything.