I fixed `default.project.json` and the place now maps exactly as the README's Layout table says. `rojo sourcemap` succeeds and `luau-lsp analyze` reports no errors.

**What the merge broke:**
1. **A hidden mark at the start of the file.** The file began with a byte order mark (BOM), which Rojo can't read. That's why `rojo sourcemap` failed with `Failed to parse JSONC`. My file tools kept the mark when I rewrote the file, so I stripped those three bytes with `tail` and checked that the file now starts with `{`.
2. **Jest packages in the wrong place.** They were mounted at `ReplicatedStorage.TestPackages` instead of `ServerScriptService.Tests.Packages`, which is why Jest couldn't find them.
3. **`Tests` mounted twice.** `ServerScriptService` already maps `src/ServerScriptService`, and `Tests` mapped `src/ServerScriptService/Tests` again, but the setting that kept the two apart (`globIgnorePaths`) had been lost. I put it back. The `Tests` folder is now built from two parts: `Specs`, from `src/ServerScriptService/Tests/Specs`, and `Packages`, from `test_packages/roblox_packages`.
4. **A typo in a path.** `src/StarterPlayer/StarterPlayerScript` was missing its final "s", so `StarterPlayerScripts` came up empty in the place.

In the new sourcemap there is exactly one `ServerScriptService.Tests`, holding `Specs` (`BlockTypes.spec` and `jest.config`) and `Packages` (`Jest` and `JestGlobals`). `StarterPlayerScripts.Main` is a LocalScript, and `ReplicatedStorage` holds only `Shared` and `Packages`. I didn't run the Jest specs, because that needs Studio.

**New guide:** `docs/rojo-workflow.md` covers:
- **Setup:** the steps to get started, including adding your own place id to `servePlaceIds` so Rojo can't sync into anyone else's place.
- **Daily routine:** pulling, installing packages, serving and checking.
- **Where changes go:** always in files, never in Studio, and never in the installed package folders.
- **While serving:** confirm Rojo 7.7.x hasn't crashed after deleting, moving or renaming files, confirm your edit actually reached Studio, and stop `rojo serve` before git commands that rewrite many files.
- **Protecting the project file:** the README table is the spec, the merge mistakes above, the BOM check, and the commands to run after any change to it.

Two things to check:
- **Package install step:** the guide tells people to run `pesde install` in the repo root and again in `test_packages/`. I took that from how the README describes the two `pesde.toml` files and didn't test it, so confirm it matches what your team does.
- **Blocked tool calls:** some calls were blocked because this session can't show permission prompts, including a dump of the full sourcemap tree. I checked the layout by searching `sourcemap.json` instead.

Nothing is committed yet: `default.project.json` is modified and `docs/` is new.