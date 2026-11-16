I fixed `default.project.json` and added `docs/rojo-workflow.md`. I couldn't verify the fix: running `rojo sourcemap` needed approval, and this session can't grant it. Please run the README's Checks commands before you merge.

**What the merge broke:**
1. **`$path` typo:** `src/StarterPlayer/StarterPlayerScript` was missing the final "s", so it pointed at a folder that doesn't exist. That's almost certainly why `rojo sourcemap` fails.
2. **Jest packages in the wrong place:** `test_packages/roblox_packages` had been moved to `ReplicatedStorage.TestPackages`. The README puts them at `ServerScriptService.Tests.Packages`, and that's where `require(ServerScriptService.Tests.Packages.Jest)` looks. That's why Jest couldn't find its packages.
3. **Duplicate `Tests` folder:** the `globIgnorePaths` entry for `src/ServerScriptService/Tests` was dropped. Without it, `ServerScriptService` picks up `Tests` from disk and the project adds a second `Tests` node.
4. **Byte-order mark:** the merged file started with an invisible marker that some editors add. JSON parsers can reject it, so the rewritten file is plain UTF-8 without one.

**How `Tests` maps now:** I put the ignore entry back. `Tests` is now built in the project file as a Folder with `Specs` (from `src/ServerScriptService/Tests/Specs`) and `Packages` (from `test_packages/roblox_packages`). That matches the README table row for row. It's slightly different from the original layout, which pointed `Tests` at the same folder it also ignored; this version can't be broken by that ignore rule.

I left `servePort: 34872` from the merge in place. It's Rojo's default port and doesn't change the mapping.

**The guide** (`docs/rojo-workflow.md`) covers:
- **Setup:** Rokit, pesde (including `test_packages/`), each teammate's own dev place, and the Studio plugin.
- **The daily loop** with `rojo serve`.
- **Where changes go:** code in `src/`, never edits to synced scripts in Studio, and how Studio-built content gets into the repo.
- **What to check while serving:** errors in the serve terminal, the plugin connected to the right project and port, and the Explorer matching the Layout table.
- **Keeping the project file healthy:** update it together with the README, run `rojo sourcemap` before pushing, and how to resolve merge conflicts. It lists the mistakes from this merge as things to watch for.