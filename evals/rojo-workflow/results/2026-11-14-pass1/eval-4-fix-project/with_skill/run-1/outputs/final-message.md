I've fixed the project file so the place maps the way the README's Layout table says, and added the guide. `rojo sourcemap` now succeeds and `luau-lsp analyze` passes with no errors. I haven't committed anything.

**What was broken in `default.project.json`.** There were four problems:
1. **A byte order mark (BOM) at the start of the file.** This is what made `rojo sourcemap` fail with "Failed to parse JSONC". It was hard to find: the grep for a BOM missed it, and my file-writing tool kept the BOM when it rewrote the file. I only found it when identical text parsed fine under a different filename. I deleted the file and recreated it as plain UTF-8, and `git diff` confirms the BOM is gone from line 1.
2. **Jest packages in the wrong place.** `test_packages/roblox_packages` was mounted as `ReplicatedStorage.TestPackages`. The README puts it at `ServerScriptService.Tests.Packages`, which is where `require(ServerScriptService.Tests.Packages.Jest)` looks. That's why Jest couldn't find its packages.
3. **Misspelled path.** `src/StarterPlayer/StarterPlayerScript` was missing its final `s`, so the client scripts didn't map.
4. **A dropped setting.** The merge lost `globIgnorePaths: ["src/ServerScriptService/Tests"]`. Without it, the `Tests` folder gets picked up twice: once through the `ServerScriptService` mount and once through its own mount.

I put back the version from before the conflict and kept the `servePort: 34872` that the merge added. In the new sourcemap there is now exactly one `ServerScriptService.Tests`, holding `Specs` (with `BlockTypes.spec` and `jest.config`) and `Packages` (with `Jest` and `JestGlobals`). `ReplicatedStorage` has `Shared` and `Packages`, and `StarterPlayerScripts` has its `Main` LocalScript.

**`docs/rojo-workflow.md`** covers:
- **Setup:** installing tools and packages, making your own dev place, and matching the Rojo plugin to the CLI version.
- **Daily loop:** pull, serve, edit files, commit on your own branch.
- **Where changes go:** always in files under `src/`, `.meta.json` files or the project file, never in Studio and never in the installed package folders.
- **What to check while serving:**
  - that Rojo 7.7.x hasn't crashed after a delete or rename;
  - that your change actually reached Studio;
  - that you're serving the right checkout;
  - that you stop the server before git commands that change the files under `src` and before installing packages.
- **Keeping the project file healthy:** check a merge against the README table row by row, watch the mounts that are easy to break, save without a BOM, and run the sourcemap check before committing.

I didn't run `selene` or `stylua --check`. My Luau check was `luau-lsp analyze` against the new sourcemap.