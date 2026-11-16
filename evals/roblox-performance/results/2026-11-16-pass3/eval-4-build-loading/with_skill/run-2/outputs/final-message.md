The type checker's three errors come from the project's out-of-date `sourcemap.json`, not from my change, so I left the code as it is.

- **Why it fails:** the checker uses `sourcemap.json` to find modules that are required by their place in the game tree. That file lists the `Shared` folder but not `BlockTypes`, `Builds` or `SavedBuilds`. So it can't resolve `require(ReplicatedStorage.Shared.BlockTypes)`, and it then reports `BlockTypes.BlockType` as unknown.
- **Why it isn't from my change:** that `require` line and the `BlockTypes.BlockType` type were already in the original file. The checker would have flagged the original code the same way.
- **The fix:** rebuild the sourcemap with `rojo sourcemap default.project.json -o sourcemap.json`, then run `luau-lsp analyze` again. I couldn't do either myself because shell commands are blocked in this session.

My earlier summary of the loading and unloading changes still stands. They also still need a playtest.