I'm leaving these errors as they are: `sourcemap.json` is out of date, and the code isn't wrong.

**Why the errors appear.** luau-lsp uses `sourcemap.json` to resolve requires. That file lists `Vide` and the `Shared` folder, but not `BlockTypes.luau` or `BlockPlacer.luau`. Both of those were already in the repo before I started, so the map predates them. My new files aren't in it either. Every flagged require points at a file missing from the map, while the requires of `Vide`, which is in the map, resolve without errors. The two `Unknown type 'BlockTypes.BlockType'` errors come from the same unresolved require.

**The fix** is to rebuild the map. It's the first command in the README, and I couldn't run it because commands need approval this session:

```sh
rojo sourcemap default.project.json -o sourcemap.json --include-non-scripts
```

Then run `luau-lsp analyze` again. I didn't hand-edit `sourcemap.json` because Rojo generates it. If real errors show up after the rebuild, I'll fix them.

The other caveats from my last message still apply: I haven't confirmed the tools accept `const`, nothing has been playtested yet, and nothing is committed.