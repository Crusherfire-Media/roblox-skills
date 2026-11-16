I've refactored `src/ReplicatedStorage/Shared/PlotStats.luau` and it now starts with `--!strict`, but I couldn't run anything to confirm it. The sandbox blocked access to the Rokit tools, so luau-lsp, StyLua and lune never ran. The strict check and the "same output as before" claim come from reading the code and tracing each edge case through the old version.

**What changed**
- **Types:** the file exports `BlockType` (a union of the five names), `Block` and `Summary`. All four public functions have typed parameters and return types, and the module table is named `Module`.
- **Block table split in two:** the old `T` table held both the list of block types and their costs. It's now a list of types and a separate cost table, so adding a block type means one entry in each.
- **Named constants:** the bare numbers are now named (`HALF_BLOCK_HEIGHT`, `BULK_DISCOUNT_MIN_BLOCKS`, `POINTS_PER_TYPE`, `ALL_TYPES_BONUS`, …). The all-types bonus checks against the length of the type list, so it keeps working when a type is added.
- **Number formatting:** the old `fmt(n, commas, decimal)` was a global and was only ever called two ways. It's replaced by local helpers: `formatWholeNumber` for counts with commas and `formatOneDecimal` for height.
- **Loops:** the nested `if` blocks are now early `continue` checks, and `x and y or z` is now `if ... then ... else`.

**Behavior I kept on purpose**
- `ipairs` is still used, so counting still stops at the first `nil` in the array.
- `summarize` given something that isn't a table raises the same error message, with no script position added, as the old `assert` did.
- `getTallest` with no qualifying block still returns no values at all, not `nil`. That matters because `tostring(PlotStats.getTallest({}))` errors today.
- Ties still go to the first block. Height comparisons are written the old way, so a NaN position behaves as before.
- `format` still joins `Variety` with `..` rather than `tostring` or string interpolation, so the output is the same character for character.

**Things to decide**
- **Number types in `getTallest`:** because names and costs shared one table, the old code treated a block whose `Type` was the number 1 to 5 as valid. `getTallest` still returns those blocks, in a small helper with a comment explaining why. If nothing creates blocks like that, you can delete the helper and use the cost lookup instead.
- **Inputs that used to crash:** `summarize` crashed on those number types and now skips them. Formatting an infinite or NaN total or score still errors, but with a clearer message. Neither was a working input before.
- **Kept as-is:** `format(summary, short)` still takes a true/false `short` argument. The style guide would replace it, but you asked to keep the signatures.

To finish the check, run `luau-lsp analyze` and `stylua src/ReplicatedStorage/Shared/PlotStats.luau`. If you want proof the output hasn't changed, a short lune script comparing the old and new versions over these edge cases would give it.