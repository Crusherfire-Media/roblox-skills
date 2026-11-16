I didn't change anything for these. The errors come from an out-of-date `sourcemap.json`, not from the code.

- **The sourcemap was built before these modules were added.** In it, `ReplicatedStorage.Shared` is an empty folder with no `BlockTypes`, and `StarterPlayerScripts` contains only `Main`. It has no `BlockPicker`, `BlockPlacer` or `PlacementPreview`, so luau-lsp can't resolve any require that points at them.
- **None of the flagged lines are ones I wrote.** They're the existing `BlockTypes` and sibling-module requires. The unchanged `BlockPicker.luau` reports the same error.
- **The changes themselves type-check.** The Charm signal in BlockPlacer, the `useSignalState` bridge in Main and the `Charm.listen` call in PlacementPreview produced no errors. StyLua and selene both pass.

**To fix it:** run `rojo sourcemap default.project.json -o sourcemap.json` and then `luau-lsp analyze` again. I didn't run it because it rewrites a tracked file outside this task, and commands that need approval can't run in this session.