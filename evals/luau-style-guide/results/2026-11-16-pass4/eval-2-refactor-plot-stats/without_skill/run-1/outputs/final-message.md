I've refactored `src/ReplicatedStorage/Shared/PlotStats.luau` and it now starts with `--!strict`, but I couldn't type-check or run it. Every command I tried (`luau-lsp`, `selene`, `stylua`) was blocked because this session can't approve commands. The behavior claims below come from reading the old and new code side by side, not from tests. Please run `luau-lsp analyze` and selene on the file before merging.

**What changed**
- **Typed API:** `Block`, `Summary` and `Rankable` are exported types, and all four public functions have type annotations. `compare` only needs `{ Score, Total }`, so the leaderboard can pass it anything with those two fields.
- **One table for block types:** `BLOCK_TYPES` lists `{ Name, Cost }` for each type. Before, the names and costs were in one mixed table, so a new type had to be added in two places. Now it's one row.
- **Named constants:** the magic numbers now have names (`BLOCK_HALF_HEIGHT`, the bulk discount values, the score weights).
- **Smaller pieces:** the old `fmt(n, c, d)` with its flag arguments is now `formatWholeNumber`, `formatOneDecimal`, `addThousandsSeparators` and `pluralize`. The deep nested `if`s are replaced with early `continue`s, and `fmt` is no longer an accidental global.

**What stays the same, edge cases included**
- The `assert` message is unchanged, and the loops still use `ipairs`, so they stop at the first gap in the list.
- The height still starts at 0 and blocks with a NaN position are still ignored. I compare explicitly instead of using `math.max` so this doesn't depend on how `math.max` handles NaN.
- `getTallest` still gives ties to the earliest block, and still returns *no values* (not an explicit `nil`) when nothing counts.
- Number formatting still rounds down before adding commas, and the full and short `format` strings are unchanged.

**Things to look at**
1. **Numeric `Type` values in `getTallest`:** because of the old mixed table, a block with `Type = 1` through `5` counted as a known type. `getTallest` could return such a block, so I kept that with a `LEGACY QUIRK` comment. In `summarize` those blocks used to crash it, so it now just skips them. If nothing actually sends numeric types, delete `isLegacyTypeIndex` to make the rules match.
2. **Inputs that used to crash:** `format` on infinite or NaN numbers used to throw. It now returns the plain text (e.g. "inf").
3. **The all-types bonus:** it now applies when the variety equals `#BLOCK_TYPES` instead of a hard-coded 5. That's identical today, but adding a type will raise the bar for the bonus, which I assumed is what you'd want.
4. **The one strict-mode line I'm least sure of** is the empty `return` in a function declared to return `Block?`. I believe strict mode accepts it. If the checker objects, changing it to `return nil` is safe for ordinary callers, but it changes what `select("#", ...)` reports.