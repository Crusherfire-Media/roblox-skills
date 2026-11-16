I fixed the mapping in `default.project.json` and wrote `docs/rojo-workflow.md`, but `rojo sourcemap` still fails. The file still starts with a UTF-8 byte-order mark (BOM), and every way I tried to remove it was blocked by this session's permissions. You'll need to remove it yourself.

**What the merge broke**

1. **The BOM at the start of the file.** This is why `rojo sourcemap` fails with "Failed to parse JSONC". The file editing tools I have keep a BOM that's already there. The shell commands that could strip it (sed, PowerShell, `git checkout HEAD~1`, cp) were denied, and so was writing a test copy outside the repo.
2. **Jest packages in the wrong place.** They had been moved to `ReplicatedStorage.TestPackages`. I moved them back to `ServerScriptService.Tests.Packages`, which is where specs and `jest.config` look for them.
3. **A dropped `globIgnorePaths` entry.** I restored `"src/ServerScriptService/Tests"`. Without it, the whole `src/ServerScriptService` folder and the separate `Tests` mapping both create a `Tests` folder, so you get two.
4. **A typo in a path.** `src/StarterPlayer/StarterPlayerScript` pointed at a folder that doesn't exist; it's `StarterPlayerScripts` again.

I kept `"servePort": 34872`, the one new line from the merge. It only sets the port for `rojo serve` and doesn't change the mapping. Apart from the BOM, the file now matches the version from before the merge, plus that line.

**To finish the fix:**
- In VS Code, click the "UTF-8 with BOM" label in the status bar, choose "Save with Encoding", then "UTF-8". (Or run `sed -i '1s/^\xEF\xBB\xBF//' default.project.json`.)
- Then run `rojo sourcemap default.project.json -o sourcemap.json --include-non-scripts`. Since that never ran, nothing has checked the new mapping yet. In the output, look for a single `ServerScriptService.Tests` containing both `Specs` and `Packages`.

**`docs/rojo-workflow.md`** covers:
- setup with rokit and pesde, and having your own dev place
- the daily `rojo serve` routine
- where each kind of change belongs (files, not Studio; never edit `roblox_packages`)
- what to watch while serving: the serve terminal, the plugin, the Explorer tree and the Output window
- rules for the project file: keep it matching the README table, check that every `$path` exists, keep `globIgnorePaths`, save without a BOM, and how to resolve merge conflicts in it

Nothing is committed.