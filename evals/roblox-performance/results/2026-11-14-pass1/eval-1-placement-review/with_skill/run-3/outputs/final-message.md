I'm leaving the `luau-lsp` finding alone. It isn't caused by my change and falls outside this task.

- **Where it is:** line 10, `require(ReplicatedStorage.Shared.BlockTypes)`. The diff shows I didn't touch that line. My only edits were removing `VALID_NAMES` and changing the block-type check in `onPlaceBlock`.
- **Likely cause:** `luau-lsp` resolves `game/...` instance paths through a Rojo sourcemap. This repo doesn't appear to have one generated, so the analyzer can't link `ReplicatedStorage.Shared.BlockTypes` to `src/ReplicatedStorage/Shared/BlockTypes.luau`. `BlockPlacer.luau` uses the same require pattern and would get the same error if it were checked. I'm inferring this from how the tool works; I didn't confirm it.
- **Fix if you want it:** run `rojo sourcemap default.project.json -o sourcemap.json` and point `luau-lsp analyze` at it with `--sourcemap=sourcemap.json`. You could also switch to require-by-string paths, which the style guide prefers, but that's a separate refactor.

Everything else from my previous message still stands. The only code change is the `BlockTypes.ByName` simplification, the verdicts are in `docs/perf/placement-review.md`, and nothing is committed.