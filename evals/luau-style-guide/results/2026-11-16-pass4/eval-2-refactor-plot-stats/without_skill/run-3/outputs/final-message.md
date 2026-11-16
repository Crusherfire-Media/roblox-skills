I've refactored `src/ReplicatedStorage/Shared/PlotStats.luau` and marked it `--!strict`, but none of it has been run or type-checked. My calls to `luau-lsp`, `lune`, `stylua` and `selene` were blocked because they needed approval and this session can't ask for it. I checked the behaviour by reading the code against the original line by line. Please run `luau-lsp analyze`, `selene` and `stylua --check` on the file before merging.

**What changed**
- **Types:** the file now exports `Block` and `Summary` types, and all four public functions have typed arguments and returns.
- **Block types:** the old `T` table mixed a list of names with a name-to-cost lookup. It's now one `BLOCK_TYPES` list of `{ Name, Cost }`, and the cost lookup is built from it. To add a block type you add one line.
- **Named constants:** the bare numbers in the code are now named: block height, bulk-discount threshold and multiplier, and the score weights and bonus.
- **Formatting helper:** `fmt(n, c, d)` was accidentally a global with three unclear flags. It's now three local helpers: `addThousandsSeparators`, `formatWholeNumber` and `formatOneDecimal`, plus a small `pluralize`.
- **Readability:** the deeply nested `if` blocks are now early `continue`s, variables have real names, and there's a header describing the public API.

**Edge cases I kept on purpose**
- **No result from `getTallest`:** when no block qualifies it still returns no value at all rather than `nil`. This matters for anything that counts return values, such as `select("#", ...)` or `table.pack`.
- **Numeric block types:** because of the old mixed table, `getTallest` accepted a block whose `Type` is a number from 1 to 5. That still works, but only in `getTallest`, and the comment says why.
- **Block iteration:** blocks are still read with `ipairs`, so the list still stops at the first `nil`. Ties in `getTallest` still go to the earliest block, and heights below zero still give `Height = 0`.
- **Number formatting:** the variety count is still joined into the text without formatting, rounding down and comma placement work the same way, and `"%.1f"` is still used for height.

**Behaviour that changed, only for inputs that used to crash**
- **Numeric block types in `summarize`:** a block whose `Type` is a number from 1 to 5 used to crash `summarize`; now it's skipped.
- **Infinite or NaN numbers:** `format` still errors on these, but the message is now clearer.

**One decision for you:** the all-types score bonus now applies when variety equals the number of entries in `BLOCK_TYPES`, instead of a hardcoded 5. Scores are identical today. If someone adds a sixth block type, though, players will need all six to get the bonus. If you'd rather keep it fixed at 5, change one line.

**One thing I couldn't confirm:** whether a bare `return` in a function declared to return `Block?` passes strict mode. I believe Luau allows it for optional return types, but if the analyzer complains, that's the line to look at.