The project file's mapping now matches the README's Layout table, but **`rojo sourcemap` still fails.** The file still starts with a byte order mark (BOM), and every way I had to remove it was blocked by permissions. One command fixes it (below).

**What the merge broke, and what I changed in `default.project.json`:**
- **Jest packages in the wrong place:** `test_packages/roblox_packages` had been moved to `ReplicatedStorage.TestPackages`. It's back at `ServerScriptService.Tests.Packages`, which is where the specs require Jest from. This is why teammates couldn't find the Jest packages.
- **Typo in a path:** `src/StarterPlayer/StarterPlayerScript` → `src/StarterPlayer/StarterPlayerScripts`. Rojo doesn't warn about a path that doesn't exist, so the client scripts would have quietly not mapped.
- **A dropped setting:** the merge removed `globIgnorePaths: ["src/ServerScriptService/Tests"]`. I put it back so the `Tests` folder isn't mounted twice.
- **The BOM, still there:** this is what makes `rojo sourcemap` fail with "Failed to parse JSONC". My file tools kept it when they rewrote the file. The shell commands that could strip it (`sed`, a PowerShell rewrite, `git checkout` of the version before the merge) all need approval, which this session can't give.
- I kept `servePort: 34872` from the other side of the merge. It doesn't change the layout.

To finish, run this from the repo root, then the check:
```sh
sed -i '1s/^\xEF\xBB\xBF//' default.project.json
rojo sourcemap default.project.json -o sourcemap.json --include-non-scripts
```
Once the BOM is gone, the file content should match the README's table. I haven't confirmed that, because `rojo sourcemap` can't get past the BOM. In `sourcemap.json`, check that `ServerScriptService.Tests.Packages.Jest` and `StarterPlayer.StarterPlayerScripts.Main` are there.

**`docs/rojo-workflow.md`** is a short guide for new teammates in four parts:
- **Setup:** installing the tools, `pesde install` in the root and in `test_packages`, adding your own dev place to `servePlaceIds`, and connecting with `rojo serve`.
- **Where to make changes:** all changes go in files, never as script edits in Studio; installed packages are read-only; anything built in Studio gets exported back to its file.
- **What to check while serving:** that `rojo serve` is still running after deletes and renames, that an edit actually reached Studio before trusting a test, which checkout the server is serving, and when to stop it.
- **Keeping the project file healthy:** the README table is the contract, resolve conflicts by keeping both sides, no BOM, and run `rojo sourcemap` after every edit or merge. It names each of the mistakes from this merge.

`default.project.json` doesn't have a `servePlaceIds` list yet, so each teammate adds their own dev place id as the guide says. Nothing is committed.