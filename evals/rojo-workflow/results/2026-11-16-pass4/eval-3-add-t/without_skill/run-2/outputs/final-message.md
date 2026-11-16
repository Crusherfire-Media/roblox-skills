I've added t and switched the `PlaceBlock` handler to it, keeping every check it does today. Nothing has been installed or run: `pesde.lock` isn't updated yet, and I didn't run rojo, luau-lsp, selene or stylua, so the changes haven't been tested.

**This repo uses pesde, not a `wally.toml`.** It already pulls its Wally packages through pesde, so I added t to `pesde.toml` the same way the others are listed:
```toml
t = { wally = "osyrisrblx/t", version = "=3.1.1" }
```
3.1.1 is the newest version on the Wally index, and I pinned it with `=` like the other packages. It loads as `ReplicatedStorage.Packages.t`, and I added it to the package table in `README.md`.

**Handler changes** (`src/ServerScriptService/BlockPlacement.server.luau`):
- The argument checks are now one checker: `t.tuple(t.string, t.intersection(t.Vector3, isNotNaN))`.
- t has no check that rejects NaN, so the old `position ~= position` check is now a small `isNotNaN` function inside that checker. It runs only once the value is known to be a Vector3, as before.
- Luau can't narrow types through a t checker, so after the check the two arguments are cast to `string` and `Vector3`.
- The other checks (block type, rate limit, character, cell, reach) are unchanged, and bad requests are still dropped silently.

**Before testing:** run `pesde install` from the repo root and commit the updated `pesde.lock`. Until then, `require(ReplicatedStorage.Packages.t)` fails and the whole placement script errors when it loads. After installing, regenerate the sourcemap and run the README checks.

`PR_DESCRIPTION.md` covers all of this: the old-to-new mapping of each check, these setup steps, and manual tests for valid and invalid arguments. It also says the checks haven't been run.

One more limit: when I tried to read several files in one shell command, it was blocked because it needed approval and nobody could approve it here. I read the same files one at a time with the file tool instead. I haven't committed anything.