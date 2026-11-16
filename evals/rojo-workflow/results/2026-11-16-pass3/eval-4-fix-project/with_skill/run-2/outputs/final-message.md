I've fixed the mapping in `default.project.json`, but **the file still won't parse until one more step is done**. It starts with a UTF-8 byte order mark (BOM), and Rojo fails on it with `Failed to parse JSONC`. My edit tools keep the existing BOM, and every command that could remove it (sed, a .NET rewrite, Move-Item, git checkout) was denied because this session can't approve permission prompts.

**What the merge broke**, compared against README.md's Layout table and the pre-merge commit `4b6fdf2`:
1. **The BOM**, which on its own makes `rojo sourcemap` fail.
2. **A path typo:** `src/StarterPlayer/StarterPlayerScript` was missing its final `s`. That folder doesn't exist, so the sourcemap would still fail once the BOM is gone.
3. **Jest packages in the wrong place:** they had moved to `ReplicatedStorage.TestPackages`, but the specs require `ServerScriptService.Tests.Packages.Jest`. That's why teammates' Jest couldn't find its packages. They're back under `ServerScriptService.Tests.Packages`.
4. **Missing `globIgnorePaths`:** the merge dropped this setting, so `Tests` would have shown up twice in `ServerScriptService`. I restored it.

**Verification:** I wrote the same content, without a BOM, to a temporary `verify.project.json` and ran `rojo sourcemap` on it. It succeeded, and the result matches the Layout table: one `Tests` folder holding `Specs` (the spec and `jest.config`) and `Packages` (`Jest`, `JestGlobals`), plus `StarterPlayerScripts/Main`, `Shared/BlockTypes` and `ReplicatedStorage.Packages`. That run also overwrote the ignored `sourcemap.json` with the correct mapping.

**To finish**, run this from the repo root to replace the BOM file with the verified copy:
```powershell
Move-Item verify.project.json default.project.json -Force
```
Then confirm with `rojo sourcemap default.project.json -o sourcemap.json --include-non-scripts`. I also kept `"servePort": 34872`, which the merge added; it's the default port and does no harm.

**The guide is in `docs/rojo-workflow.md`.** It covers:
- **Setup:** making your own dev place and adding its id to `servePlaceIds`.
- **Where changes go:** files under `src/` only, never Studio and never the installed package folders.
- **While serving:** confirming a change reached Studio, watching for Rojo 7.7.x crashing after deletes or renames, and stopping `rojo serve` before git checkouts, pulls or `pesde install`.
- **Protecting the project file:** keeping it in sync with the Layout table, saving without a BOM, how to resolve merge conflicts in it, and validating with `rojo sourcemap` before committing.

Nothing is committed.