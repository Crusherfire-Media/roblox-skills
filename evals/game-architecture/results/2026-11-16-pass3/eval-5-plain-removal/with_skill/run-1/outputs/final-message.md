I didn't change anything for these two errors. They come from an out-of-date `sourcemap.json`, not from the code I edited.

- **What's wrong:** the type checker uses `sourcemap.json` to find modules. In that file, `ReplicatedStorage.Shared` is an empty folder with no `BlockTypes` inside it, so the map was made before `BlockTypes.luau` existed.
- **Not from this change:** both errors are on the `require` lines at `BlockPlacement.server.luau:11` and `BlockPlacer.luau:12`, which I didn't touch.

I left `sourcemap.json` alone. I couldn't check whether it's committed to git (that command was blocked because this session can't approve prompts), and rebuilding a committed generated file would add a large unrelated change. Running `rojo sourcemap default.project.json -o sourcemap.json` should rebuild it and clear both errors.