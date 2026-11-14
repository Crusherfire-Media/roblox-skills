The type checker's four errors are false matches: they come from a stale `sourcemap.json`, not from the picker code.

- **Why they happen:** `sourcemap.json` doesn't list `BlockTypes`, `BlockPicker` or `BlockPlacer` at all; a search of the file finds none of them. The checker uses that file to look up `require(...)` paths, so it can't find any of these modules. The fourth error, the unknown `BlockTypes.BlockType` type, follows from the first.
- **Not from this change:** all three of those `require` lines were already in the code, and I didn't change them. The same errors would show on the code from before my change.
- **Fix:** regenerate the sourcemap, for example with `rojo sourcemap default.project.json -o sourcemap.json`, or the project's `sourcemap_generator` script. Then re-run `luau-lsp analyze`. I didn't regenerate it, because it's a tracked file outside this task.

I couldn't confirm the errors were there before my change: running the checker on the old code needed approval, and this session can't grant it.

The picker change itself is as described above. StyLua and selene both pass with no errors, and it hasn't been playtested yet.