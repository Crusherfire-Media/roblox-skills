Neither finding needs a code change; both come from an out-of-date `sourcemap.json`.

- **`BlockTypes` (line 12):** this require was already in the file before my edit. `sourcemap.json` doesn't list `BlockTypes` or `BlockPlacement` at all, so it was generated before either file existed. It's a generated, gitignored file, so the analyzer is reading a stale map, not finding a bug.
- **`t` (line 10):** t isn't installed yet, so it can't be in the map. This goes away once you run `pesde install` and regenerate the map.

Both should clear once you run `pesde install` and then `rojo sourcemap default.project.json -o sourcemap.json --include-non-scripts` (steps 2 and 4 in `PR_DESCRIPTION.md`). My shell commands were blocked, so I couldn't regenerate it here. If anything still fails after that, it's a real problem worth looking at.