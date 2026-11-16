I'm leaving these five type-check errors unfixed. My change doesn't cause them, and nothing in the edited files is wrong.

- **Stale sourcemap:** the project's `sourcemap.json` doesn't list `BlockTypes`, `BuildMenu` or `BlockPlacer` at all, so the type checker can't find those modules even though all three files exist.
- **Not my lines:** all five errors point at the original `require` lines and the two types that depend on them (`BlockTypes.BlockType` and `BuildMenu.Tab`). I didn't change any of those lines.

Regenerating the sourcemap with `rojo sourcemap default.project.json -o sourcemap.json` should clear them. I didn't run it because it rewrites a project file, and that's outside what you asked for.

The rest of the earlier summary still holds: the Studio measurement still needs to be done using the steps in `docs/perf/build-menu.md`.