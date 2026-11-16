The checker's one error isn't caused by my edit, so I've left it alone. I didn't commit anything.

**What it flagged:** `luau-lsp` reported "Unknown require" for `ReplicatedStorage.Shared.BlockTypes` at `BlockPlacement.server.luau:10`.

**Why it's not from my change:**
- **That line is unchanged.** `git show HEAD` has the same `require` there before my edit. My change only touched the `VALID_NAMES` lines further down.
- **The project's `sourcemap.json` is out of date.** That's the file the checker uses to resolve requires. It lists `ReplicatedStorage.Shared` as an empty folder with no `BlockTypes` inside it, and `ServerScriptService` contains only `Main`. It was generated before these files existed. `BlockPlacer.luau`, which I didn't change, has the same `require`.

**The fix is to regenerate the sourcemap**, for example with `rojo sourcemap default.project.json --output sourcemap.json`. That's outside this task, and when I tried to check whether the file is gitignored and whether `rojo` is installed, the command needed approval and was blocked. You can regenerate it yourself and run `luau-lsp` again.

The verdicts are unchanged. The only code change is the `ByName` lookup in `BlockPlacement.server.luau`, and the reasoning for all six items is in `docs/perf/placement-review.md`.