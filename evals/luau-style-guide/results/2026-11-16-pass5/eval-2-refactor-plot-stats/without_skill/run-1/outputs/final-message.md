I've refactored `src/ReplicatedStorage/Shared/PlotStats.luau`, but I couldn't run my test comparing the old and new versions: running `lune` needed approval and this session can't grant it. The claim that the four functions behave the same rests on a line-by-line review against the original, not on a test run.

**What did pass:** `--!strict` type checking with `luau-lsp`, plus `selene` (no errors or warnings) and `stylua --check`. One caveat: no Roblox type definitions are installed, so I type-checked against a small stand-in definition of `Vector3`. A Studio or luau-lsp setup with the full Roblox types should give the same result, but I haven't confirmed that.

**What changed:**
- **Types:** `Block` and `Summary` are now exported types, and all four public functions have typed signatures.
- **Config split:** the old `T` table, which mixed the list of block names with their costs, is now two tables: `BLOCK_TYPES` (display order) and `BLOCK_COSTS`. To add a block type you add it to both.
- **Named numbers:** the unexplained numbers are now constants: block half-height `2`, discount threshold `50` and multiplier `0.9`, and the score weights `10` / `2` / `25` / `+100`.
- **Small helpers:** the old `fmt(n, c, d)` with three flags is now `formatWholeNumber`, `formatOneDecimal` and `addThousandsSeparators`. The scoring is split into `applyBulkDiscount`, `countVariety`, `calculateScore` and `pluralize`.
- **Global removed:** `fmt` used to be a global that leaked into the environment; it's now a local.

**Edge cases kept on purpose:**
- **Same arithmetic:** cost is still `math.floor(cost * 0.9)`, the height comparison is the same, and score terms add up in the same order, so rounding is identical.
- **Ties and empty results:** `getTallest` still keeps the first block on a tie. With no valid block it still returns no value at all rather than a single `nil`, so `print(getTallest({}))` prints the same as before.
- **Bad blocks:** blocks missing `Position`, with an unknown `Type`, or that are plain strings are skipped as before. `summarize` raises the same error message for non-table input.
- **A bug I kept:** because of the mixed `T` table, the old `getTallest` treated a block with a numeric `Type` from 1 to 5 as valid. I kept that so its output doesn't change, but it's isolated in one function with a comment. It's almost certainly a bug, so you may want to remove it once you've checked nothing relies on it.

**Inputs that used to crash and now don't:**
- `summarize` now skips blocks with a numeric `Type` instead of failing partway through.
- `format` now shows a total or score of infinity or NaN as `"inf"` / `"nan"` instead of crashing while adding commas.

**Leftover files:** I couldn't delete my scratch folder `.tmpcheck/` in the project root (deleting needed approval too). It holds a copy of the original module, the test script and the stand-in definitions. Please delete it, or run `lune run .tmpcheck/diff.luau` first to do the comparison I couldn't. It prints the number of mismatches between old and new.