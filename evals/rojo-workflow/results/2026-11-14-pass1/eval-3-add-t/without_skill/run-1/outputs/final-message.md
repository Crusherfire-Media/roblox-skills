I've added t to the project and switched the `PlaceBlock` handler to it. Nothing has been installed, built or play-tested, and I haven't committed anything.

**This repo uses pesde, not Wally's own tool.** There's no `wally.toml`; Wally packages go in `pesde.toml` and pesde fetches them. So I added this line to `[dependencies]`, pinned exactly like the other packages:
```toml
t = { wally = "osyrisrblx/t", version = "=3.1.1" }
```
3.1.1 is the newest version on the Wally index. After you install, it will be at `ReplicatedStorage.Packages.t`.

**Handler** (`src/ServerScriptService/BlockPlacement.server.luau`): the hand-written checks are now one checker, `t.tuple(t.string, finiteVector3)`, built once when the script loads.
- **NaN check:** `t.Vector3` lets NaN positions through on its own. To keep the existing NaN check, `finiteVector3` adds a small extra rule on top of `t.Vector3` that rejects any position with a NaN component.
- **Everything else is unchanged:** the block-type lookup, rate limit, character check, below-ground check, occupied cell and reach limit. Bad requests are still dropped silently, and extra arguments are still ignored.

**Before testing** (also in `PR_DESCRIPTION.md`):
1. Run `pesde install` (`rokit install` first if you don't have pesde). Until then the script errors when it tries to load `t`.
2. Commit the updated `pesde.lock`. This change edits `pesde.toml` but not the lockfile, so the install will change `pesde.lock`.
3. If you use luau-lsp, rebuild the sourcemap so the editor sees `Packages.t`.

`PR_DESCRIPTION.md` also has a test checklist covering bad types, NaN positions, unknown block types and each of the remaining limits.

One command was blocked: a shell command to list the repo files. The session can't approve commands, so I used the read-only file tools instead and didn't need it.