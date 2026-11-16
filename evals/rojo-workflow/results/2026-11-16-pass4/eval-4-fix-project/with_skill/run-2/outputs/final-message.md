I've fixed the mappings in `default.project.json` and written `docs/rojo-workflow.md`, but the project file still has a byte order mark at its start, and that alone may keep `rojo sourcemap` failing. You'll need to remove it before Rojo works again. I also couldn't run `rojo` here, so nothing has been checked against the real tool.

**What the bad merge broke** (I compared the file with the commit before the merge):

| Problem | Effect | Fix |
|---|---|---|
| Jest packages were mounted at `ReplicatedStorage.TestPackages` | Specs require `ServerScriptService.Tests.Packages.Jest`, so Jest couldn't find its packages | Moved back to `ServerScriptService.Tests.Packages` |
| The `globIgnorePaths` entry for `src/ServerScriptService/Tests` was dropped | That folder was then mounted twice: by the `ServerScriptService` path and by the `Tests` node | Restored |
| `src/StarterPlayer/StarterPlayerScript` (missing the final "s") | Points at a folder that doesn't exist, so the client scripts were never mounted | Corrected to `StarterPlayerScripts` |
| The file started with a byte order mark | Rojo can't read a project file that starts with one, so it fails at line 1 | **Not fixed** (see below) |

Every row in the README's Layout table now matches the tree. I kept `servePort: 34872`, which is Rojo's default port anyway.

**Removing the byte order mark:** my file tools kept the existing mark when they rewrote the file, and the commands that would strip it were blocked because they needed approval. Either of these will remove it:
- Run `git checkout 4b6fdf2 -- default.project.json`, then add back the line `"servePort": 34872,`. That older copy has no mark and already has the other three fixes.
- Or open the file in your editor and re-save it as "UTF-8" rather than "UTF-8 with BOM".

After that, run `rojo sourcemap default.project.json -o sourcemap.json --include-non-scripts` and check that `ServerScriptService.Tests.Packages` and `StarterPlayer.StarterPlayerScripts` appear with children.

**The guide** (`docs/rojo-workflow.md`) covers:
- **Setup:** Rokit, `pesde install` (also in `test_packages/`), a personal dev place, and adding its id to `servePlaceIds`.
- **Daily loop:** stop `rojo serve` before pulling, switching branches, or installing.
- **Where changes go:** always in files, never in Studio. Attributes and tags go in `.meta.json`, Studio-built models are exported as `.rbxm`, and package folders are never edited.
- **What to check while serving:** whether Rojo 7.7.x has crashed after a delete or rename, whether the edit actually reached Studio, and which branch the place is running.
- **Keeping the project file healthy:** the Layout table is the spec, conflicts are rebuilt against it rather than taking both sides, no byte order mark, and run the sourcemap check before pushing.

Nothing is committed yet.