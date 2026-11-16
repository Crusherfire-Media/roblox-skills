I've refactored `src/ReplicatedStorage/Shared/PlotStats.luau`, and no other file changed. It now has `--!strict` and passes all the README checks: `luau-lsp analyze` reports no errors, and `selene` and `stylua --check` are clean. I couldn't run the code: the session blocked the commands for a test comparing the old and new versions with Lune. So "behaves the same" rests on reading the code side by side, not on test runs.

**What changed**
- **Types:** `Block` and `Summary` are exported types, and all four public functions are typed.
- **Block types:** the old `T` table mixed an ordered list of names with costs. It's now one list, `BLOCK_TYPES`, with `{ name, cost }` entries, and the cost lookup is built from it. Adding a block type is one line. The "all types used" bonus now checks against the length of that list instead of a hard-coded `5`.
- **Named numbers:** the half block height (2), the bulk-discount threshold (more than 50 blocks) and rate (0.9), and the score weights are now named constants.
- **Number formatting:** `fmt(n, c, d)` was split into `formatWholeNumber` and `formatOneDecimal`, plus `addThousandsSeparators` and `pluralize`. `fmt` was also an accidental global; that's gone.
- **Shared rules:** `summarize` and `getTallest` now use one check for which blocks count (`isCountable`), so their rules can't drift apart. Score is calculated in its own small function.

**Edge cases I kept on purpose**
- **Number `Type` values:** because names and costs shared one table, a block whose `Type` is a number from 1 to 5 counted as a known type. `getTallest` will still return such a block. `summarize` still throws an error on it, as it did before, because there's no cost for it. This is documented in `isKnownBlockType`. It's almost certainly a bug, but removing it would change what `getTallest` returns, so that's your call.
- **No countable blocks:** `getTallest` still returns no values at all, not an explicit `nil`, so `select("#", ...)` gives the same result.
- **Unchanged behaviour:**
  - The `summarize` error message for non-table input is identical.
  - Ties in `getTallest` still go to the earliest block.
  - Height never goes below 0.
  - Thousands separators work as before, including negatives and outputs like `1e+20`.
  - A truthy `short` still gives the short text.
  - `compare` is unchanged.

**Typing caveat:** the `Block` type says `Position` is always set, but the code still checks for a missing one at runtime, because callers may pass half-built blocks. Strict mode rejects comparing a `Vector3` with `nil`, so that check reads the position into a `Vector3?` local first.

**Changes only on input that already errored:** an `inf` or `nan` total or score now hits an `assert` with a clearer message, where before it failed inside `string.gsub`. Both still error.