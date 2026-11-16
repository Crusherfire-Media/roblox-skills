I've added t and switched the `PlaceBlock` handler to it, but none of this has been run: no install, no lint/typecheck, no play test. Until you run `pesde install`, `BlockPlacement` will error when it tries to load t.

**Adding the package.** This repo pulls Wally packages through pesde, so I added t to `pesde.toml` as `t = { wally = "osyrisrblx/t", version = "=3.1.1" }`. That's an exact pin like the other packages, and 3.1.1 is the newest version on the Wally index. Code loads it with `require(ReplicatedStorage.Packages.t)`. I also added it to the package table in `README.md`.

**The handler** (`src/ServerScriptService/BlockPlacement.server.luau`). The hand-written checks are now one validator, `t.tuple(t.keyOf(BlockTypes.ByName), t.intersection(t.Vector3, notNaN))`. It covers all four old checks:
- **Not a string, or not a block type name:** `t.keyOf` only accepts the key names in `BlockTypes.ByName`. That table is frozen when it loads, so building the list once is safe.
- **Not a Vector3:** `t.Vector3`.
- **NaN in the position:** t's built-in NaN check only handles numbers, so a small `notNaN` function keeps the old `position ~= position` test.

The checks after that (rate limit, character, `Y < 0`, occupied cell, reach) are unchanged and run in the same order.

**What wasn't run:**
- **Install:** `pesde.lock` hasn't been regenerated and `roblox_packages/` doesn't have t yet.
- **Checks:** none of luau-lsp, selene or stylua were run. My one shell command was blocked because this session can't approve commands, so I made the changes with the file tools only. I also didn't commit anything.

`PR_DESCRIPTION.md` tells the reviewer to run `pesde install`, commit the updated `pesde.lock`, and run the README checks before testing. It also maps each old check to its replacement and lists Studio commands that should be rejected, such as a bad block name, a non-Vector3 position, a NaN position, or a missing argument.