These five errors come from an out-of-date `sourcemap.json`, not from my edits. They aren't type errors in the code.

- `sourcemap.json` has no entries for `BlockTypes`, `BlockPlacer` or `BuildMenu`, so `luau-lsp` can't resolve any require that points to them.
- Every line it flags was already there before my change: the `BlockTypes` require and `BlockTypes.BlockType` type in `BuildMenu.luau`, and the `BlockPlacer`/`BuildMenu` requires and `BuildMenu.Tab` in `Main.client.luau`. The same errors would appear on the original files.

I haven't touched `sourcemap.json`, because it's a tracked generated file outside this task. To clear the errors, run `rojo sourcemap default.project.json -o sourcemap.json` and re-run `luau-lsp analyze`. Even then, a full type-check needs Roblox definitions: without them, `luau-lsp` also reports errors inside the Vide package itself.

My earlier summary still applies: StyLua and selene pass on both edited files, and the changes haven't been measured in Studio yet. `docs/perf/build-menu.md` explains how to check them.