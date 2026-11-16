No code changes this time. These five errors come from an out-of-date `sourcemap.json`, not from the Charm change, so they're outside this task.

- **Why they happen:** the sourcemap is the file that tells luau-lsp where each script sits in the game. It has no entry for `BlockTypes`, `BlockPicker`, `BlockPlacer` or `PlacementPreview`, so the type-checker can't resolve requires that point at them.
- **They aren't from this change:** every flagged line is a require that was there before I started, not one I added. The new Charm and VideCharm requires resolve fine.
- **How to clear them:** regenerate the sourcemap with `rojo sourcemap default.project.json --output sourcemap.json`, then run `luau-lsp analyze` again. I didn't do this myself. I tried to check whether `sourcemap.json` is tracked in git, but that command needed approval and this session can't grant it. I didn't want to overwrite a possibly tracked file without that check.

StyLua and Selene still pass on the changed files, and I still haven't playtested the change.