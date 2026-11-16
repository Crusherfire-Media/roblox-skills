I've fixed `default.project.json`, and `rojo sourcemap` runs cleanly again. The place maps exactly as the README's Layout table says. I also wrote the guide at `docs/rojo-workflow.md`.

## What the merge broke

1. **The file started with a hidden byte-order mark (BOM).** Rojo can't parse a file that begins with one, so it failed with "Failed to parse JSONC" before reading any mapping. This is why `rojo sourcemap` failed.
2. **The Jest packages were in the wrong place.** They were mapped to `ReplicatedStorage.TestPackages` instead of `ServerScriptService.Tests.Packages`, which is why teammates couldn't find Jest. I moved them back.
3. **A setting that prevents a duplicate folder was deleted.** Without the `globIgnorePaths` entry for `src/ServerScriptService/Tests`, the place would get two `Tests` folders. I restored it.
4. **One path had a typo:** `src/StarterPlayer/StarterPlayerScript`, missing the final `s`, which doesn't exist. I corrected it to `StarterPlayerScripts`.

The rest of the file now matches the commit before the merge. The one exception is `servePort: 34872`, which the merge added. It only sets which port `rojo serve` uses and doesn't change the mapping, so I kept it.

## Checking it

After the fix, `rojo sourcemap default.project.json -o sourcemap.json --include-non-scripts` succeeded. The sourcemap matches every row of the Layout table: there is one `Tests` folder, `Jest` and `JestGlobals` are inside `Tests.Packages`, the client `Main` is in StarterPlayerScripts, and there's no `TestPackages` left. A build to a `.rbxl` file and the other README checks (luau-lsp, selene, stylua) didn't run because the session couldn't approve them.

## The guide

`docs/rojo-workflow.md` covers:
- **Setup:** rokit, pesde, the Studio plugin, and each person making their own dev place.
- **Daily loop:** pull, `rojo serve`, connect from Studio, edit files, run the checks before committing.
- **Where changes go:** code lives in files under `src/` and never in Studio, which file suffix makes which script type, and adding packages through `pesde.toml`.
- **What to check while serving:** errors in the serve terminal, the plugin's connection status, and the Explorer compared against the Layout table.
- **Not breaking the project file:** a checklist to run after any edit or merge-conflict fix, including the sourcemap command, the two parts that must stay, and saving without a BOM. That last one matters because PowerShell and some Windows editors add a BOM silently.

I haven't committed anything. My sourcemap run also rewrote `sourcemap.json`, which is gitignored.