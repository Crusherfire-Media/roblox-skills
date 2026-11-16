I fixed `default.project.json` so the place maps the way the README's Layout table says, and `rojo sourcemap default.project.json -o sourcemap.json --include-non-scripts` now succeeds. I also added `docs/rojo-workflow.md`. Nothing is committed.

**What the merge broke:**
1. **Invisible bad first character.** The file started with a byte-order mark (BOM), a hidden marker some Windows editors add. Rojo 7.7.1 rejects it with "Failed to parse JSONC", and that was why the sourcemap failed. You can't see it in an editor; it only shows up in `git diff`. I recreated the file without it.
2. **Jest packages in the wrong place.** They were mapped to `ReplicatedStorage.TestPackages`, but the README says `ServerScriptService.Tests.Packages`, which is why teammates couldn't find them. They're back under the `Tests` node.
3. **A missing setting.** `globIgnorePaths` for `src/ServerScriptService/Tests` had been dropped. Without it, the `src/ServerScriptService` folder and the project file's own `Tests` entry would both try to create a `Tests` folder. I restored it.
4. **Typo in a path.** `src/StarterPlayer/StarterPlayerScript` (missing the "s") is now `StarterPlayerScripts`.

I also removed `servePort: 34872`, which the merge added. 34872 is Rojo's default port anyway, so nothing changes.

**Check:** the generated sourcemap now has one `ServerScriptService.Tests` folder containing `Specs` (the spec file and `jest.config`) and `Packages` (`Jest` and `JestGlobals`). `ReplicatedStorage` has `Shared` and `Packages`, and there's no `TestPackages` left. I didn't run the other README checks (`luau-lsp`, `selene`, `stylua`), and I couldn't run the Jest specs because they only run in Studio.

**`docs/rojo-workflow.md`** covers:
- one-time setup;
- the daily loop of `rojo serve` plus your own dev place in Studio;
- where changes go: code in `src/` edited in your editor, packages through `pesde`, Baseplate and service settings in the project file;
- what to watch while serving: the serve terminal, the plugin status, the Explorer and the Output window;
- how to protect the project file: treat the README table as the spec, rebuild the file during conflicts instead of mixing both sides, save without a BOM, and run the sourcemap check before committing.

**Blocked or left over:** this session couldn't approve several commands, including deleting a file and some multi-step PowerShell. To get rid of the BOM I wrote a clean copy to a temporary `zz.project.json` and moved it over `default.project.json`. That temporary file is gone, and so is the scratch `zz.json`.