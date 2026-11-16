The mapping in `default.project.json` is fixed and `docs/rojo-workflow.md` is written, but `rojo sourcemap default.project.json` still fails with `Failed to parse JSONC`. The file starts with a UTF-8 BOM (bytes `EF BB BF`), and rojo can't parse a file that starts with one. I couldn't remove it: my file tools keep the existing encoding, and the shell command to replace the file needed approval this session can't give. You need to do this one step.

**To finish the fix**, save the file as UTF-8 without a BOM. In VS Code, click "UTF-8 with BOM" in the status bar → Save with Encoding → UTF-8. Or copy over it with the clean copy I left:
```powershell
Copy-Item build\default.project.json default.project.json -Force
```
Then run `rojo sourcemap default.project.json -o sourcemap.json --include-non-scripts`.

**What the merge broke** (the BOM was already in the committed file, so it came in with the merge too):
1. **Typo:** StarterPlayerScripts pointed at `src/StarterPlayer/StarterPlayerScript`, which doesn't exist. Fixed.
2. **Jest packages in the wrong service:** `test_packages/roblox_packages` was mapped to `ReplicatedStorage.TestPackages` instead of `ServerScriptService.Tests.Packages`. Fixed.
3. **Two `Tests` folders:** `ServerScriptService` maps the whole `src/ServerScriptService` folder, which already contains `Tests`, and the project also defined its own `Tests` node. So Studio got two `Tests` folders, and only one of them would hold the packages. That's likely the main reason Jest can't find its packages.
   - **Fix:** a `globIgnorePaths` entry now skips `src/ServerScriptService/Tests` on disk.
   - `Tests` is now a plain folder in the project with `Specs` (from `Tests/Specs`) and `Packages` (from the test packages) inside it, which is what the README table describes.
   - New files in `src/ServerScriptService` still sync automatically.

**How I checked it:** I made a copy of the fixed file in `build/`, identical except the paths are adjusted for that folder, and ran rojo sourcemap on it against the real files. The result matches the README Layout table: one `ServerScriptService.Tests` with `Specs` and `Packages` (`Jest`, `JestGlobals`), plus `ReplicatedStorage.Shared` and `ReplicatedStorage.Packages`, `StarterPlayer.StarterPlayerScripts`, and `StarterGui`. I couldn't run `rojo serve` with Studio here.

**The guide, `docs/rojo-workflow.md`, covers:**
- one-time setup and why each person serves into their own dev place
- the daily loop
- where changes go: code in `src/`, never edit synced scripts in Studio, packages through `pesde.toml`
- what to watch while serving: the serve terminal, the plugin connection, the Explorer against the Layout table (exactly one `Tests`), and the Output window
- how to handle project-file merges, with these four mistakes as examples, the "save as UTF-8 without BOM" rule, and a check to run before pushing

My test files are still in `build/` (`build/t/` and the `.project.json`/`.sourcemap.json` files). The folder is gitignored, but deleting needed approval too, so remove them when convenient. Nothing is committed.