I didn't change any code for these errors. All five are "Unknown require" on requires that were already in the files before my edit, and the cause is a stale `sourcemap.json`, not the code:

- In the sourcemap, `ReplicatedStorage.Shared` is an empty folder with no `BlockTypes` inside it.
- `StarterPlayerScripts` lists only `Main`. `BlockPicker`, `BlockPlacer` and `PlacementPreview` are missing.

So luau-lsp can't resolve `ReplicatedStorage.Shared.BlockTypes` or the `script.Parent.*` siblings. The two requires I added, `Packages.Charm` and `Packages.VideCharm`, are in the sourcemap and weren't flagged.

To fix it, rebuild the sourcemap with `rojo sourcemap default.project.json -o sourcemap.json` (or the project's pesde `sourcemap_generator` script) and run `luau-lsp analyze` again. I didn't run that myself because shell commands that need approval are blocked in this session. That same block is why StyLua, selene and a full type check of my changes still haven't run.