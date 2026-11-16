I've refactored `src/ReplicatedStorage/Shared/PlotStats.luau` and it now starts with `--!strict`. I haven't run anything on it: the command to look for `luau-lsp`, StyLua and selene was blocked by permissions, so it has not been type-checked, formatted or tested. Before merging, run `luau-lsp analyze` and `stylua` on it.

**What changed**
- **Types:** the module now exports `Block`, `BlockType` and `Summary`, and all four public functions have typed arguments and return values.
- **Named numbers:** the old mixed table `T` is now two tables, `BLOCK_TYPES` (the display order) and `BLOCK_COST`, both frozen. The other unexplained numbers have names too: half-block height, bulk-discount threshold and multiplier, the score weights, and the "every type" bonus.
- **Helpers:** the old `fmt(n, c, d)` was a global with flag arguments. It's replaced by local `formatWholeNumber`, `formatOneDecimal`, `addThousandsSeparators` and `pluralize`. A shared `isCountedBlock` replaces the three levels of nested `if` that `summarize` and `getTallest` each repeated.
- **Adding a block type** now means adding it to `BLOCK_TYPES` and giving it a cost in `BLOCK_COST`. Nothing else needs to change.

**Output that stays exactly the same (worked out by reading the code, not tested)**
- **Numeric block types:** because `T` held both the type list and the costs, a block with `Type = 1` to `5` counted as a known type. `getTallest` still accepts those blocks, and `summarize` still errors on them, though the error message is different. There's a comment explaining this.
- **Empty `getTallest`:** with no matching block it returns no values at all, not an explicit `nil`. That's still the case.
- **Height:** I kept the `top > height` check instead of switching to `math.max`, so `Height` stays exactly `0`, never `-0` or NaN. A `-0` would show up on the sign as "-0.0 studs tall".
- **Everything else** is unchanged: which fields `summarize` reads and in what order, the assert message, the rounding, how numbers are formatted (including very large ones like `"1e+20"`), plurals, how `short` is treated, and the tie-breaking in `compare`.

**Changes in behaviour**
1. `format` used to crash when given an infinite score (a block with `Position.Y = math.huge`). It now shows `"inf"` instead. That input used to error, so it wasn't something the functions handled before.
2. The +100 bonus used to require exactly 5 types; now it requires `#BLOCK_TYPES`. That's identical today, but if you add a sixth type, plots will need all six to get the bonus. Change it back to a fixed number if you'd rather keep it at 5.