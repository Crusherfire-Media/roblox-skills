I fixed `default.project.json` and wrote `docs/rojo-workflow.md`. `rojo sourcemap` now runs cleanly, and the result matches every row of the README's Layout table. `luau-lsp analyze` from the README also passes with no errors. I didn't run `selene` or `stylua`, or test anything in Studio. Nothing is committed.

**What the merge broke:**

1. **Hidden encoding mark.** The file started with an invisible UTF-8 BOM (byte order mark), which Rojo can't read. That's the actual cause of `rojo sourcemap` failing with `Failed to parse JSONC`. It's gone now.
2. **Jest packages in the wrong place.** They were mapped to `ReplicatedStorage.TestPackages`, but the specs require `ServerScriptService.Tests.Packages`. That's why teammates' Jest couldn't find them. I moved them back.
3. **Two `Tests` folders.** `ServerScriptService` and its `Tests` child both pointed at the same folder on disk, and Rojo doesn't merge them; it creates two `Tests` folders (I confirmed this with a test project). Now `Tests` is a plain Folder holding `Specs` and `Packages`, and a `globIgnorePaths` entry stops Rojo from adding `src/ServerScriptService/Tests` a second time.
4. **Typo in a path.** `src/StarterPlayer/StarterPlayerScript` (missing the final "s") left StarterPlayerScripts empty, so the client `Main` script never loaded.

One side effect of fix 3: only the `Specs` folder inside `src/ServerScriptService/Tests` is synced. Anything placed directly in `Tests/` won't show up. That fits the README layout, and the guide says so.

**The guide** covers:
- **Setup:** installing packages in both the project root and `test_packages/`, and using your own dev place.
- **Where to make changes:** edit in `src/`, never in synced scripts in Studio.
- **What to check while serving:** the terminal, the plugin status, and quick checks in Explorer.
- **Keeping the project file healthy:** save it as UTF-8 without a BOM, don't nest `$path` over the same folder, check paths for typos, and run `rojo sourcemap` after resolving any merge conflict.

I also regenerated `sourcemap.json` from the fixed file. It's gitignored, so it isn't part of the change.