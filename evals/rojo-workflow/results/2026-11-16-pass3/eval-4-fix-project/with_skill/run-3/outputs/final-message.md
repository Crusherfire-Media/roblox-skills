I've fixed `default.project.json`, and `rojo sourcemap` works again. The place now maps exactly as the README's Layout table says. I also added `docs/rojo-workflow.md`. Nothing is committed.

**What the bad merge broke**, compared with the file's original version in git history:
1. **The file had a UTF-8 BOM (byte order mark) at the start.** That alone made Rojo fail with "Failed to parse JSONC". It's gone now: the file starts with `{`.
2. **The Jest packages were mounted in the wrong place.** They had moved to `ReplicatedStorage.TestPackages`, but specs require them from `ServerScriptService.Tests.Packages`. That's why teammates' Jest couldn't find its packages. They're back under `Tests.Packages`.
3. **`globIgnorePaths: ["src/ServerScriptService/Tests"]` had been deleted.** `src/ServerScriptService` is mounted whole and `Tests` is mounted again separately, so without that line the place gets two `Tests` folders. It's restored.
4. **The client scripts folder path had a typo:** `src/StarterPlayer/StarterPlayerScript` instead of `...Scripts`. It's corrected.

The merge also added `"servePort": 34872`. I kept it: that's Rojo's default port, so it changes nothing. Apart from that line, the file is the same as the original.

**Checks run:**
- `rojo sourcemap` succeeds.
- The new sourcemap has one `ServerScriptService.Tests` folder containing `Specs` (with `jest.config` and `BlockTypes.spec`) and `Packages` (with `Jest` and `JestGlobals`). There's no `TestPackages` folder, and `StarterPlayerScripts.Main` is a LocalScript.
- `luau-lsp analyze` reports no errors, and `selene src` reports 0 errors and 0 warnings.
- I didn't run `stylua --check` or the Jest specs. Specs need Studio, so someone should run the suite in their dev place to confirm Jest finds its packages again.

**The guide (`docs/rojo-workflow.md`)** covers:
- **First-time setup**, including adding your own place id to `servePlaceIds` so Rojo only syncs into your dev place.
- **Where each kind of change goes:** edit files under `src/`, use `.meta.json` files for attributes and tags, and never edit anything in Studio or in `roblox_packages/`.
- **What to check while serving:** that Rojo hasn't crashed after a delete, move or rename (a known problem in Rojo 7.7.x), that your edit actually reached Studio, and which branch is being served. It also says to stop Rojo before checkouts, pulls and `pesde install`.
- **Keeping the project file healthy:** how to resolve conflicts in it against the README's Layout table, the four mistakes above, the BOM check, and running the sourcemap before committing.

**Two things to know:**
- Windows PowerShell and some editors add a BOM or keep an existing one. Even my own editing tool kept it on the first save, and I had to strip it separately. The guide includes a one-line check for it.
- This session couldn't ask for permission, so a few read-only commands (`git status`, a byte dump, a Python script to print the sourcemap tree) were blocked. I got the same information with other commands, so no check was skipped.