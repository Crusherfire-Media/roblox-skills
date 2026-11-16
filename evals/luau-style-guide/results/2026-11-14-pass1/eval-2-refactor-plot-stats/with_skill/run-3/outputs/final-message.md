I've refactored `src/ReplicatedStorage/Shared/PlotStats.luau` and it now starts with `--!strict`, but **I haven't run anything on it**. Shell commands needed approval this session, so I couldn't run `luau-analyze`, StyLua, selene or any tests. I formatted it by hand to `stylua.toml` and checked behavior by reading the old and new code side by side.

**What changed**
- **Names:** the cryptic names (`T`, `blks`, `cnts`, `h`, `v`) are spelled out. The magic numbers are now named constants: costs, the bulk discount (more than 50 blocks, ×0.9), the half-block height of 2, and the score weights and bonus.
- **Types:** there are exported `BlockType`, `Block` and `Summary` types, and all four public functions are fully typed. The signatures are unchanged, including `format(summary, short)`.
- **Structure:** nested `if`s are now early `continue`s. Discount and score math each live in their own small helper.
- **`fmt`:** the old helper took two boolean flags. It's now `formatWholeNumber` and `formatOneDecimal`, with the comma grouping algorithm kept exactly as it was. `fmt` was also an accidental global, which strict mode rejects, so it's now local.
- **Adding a block type:** one comment at the top says what to touch: `BlockType`, `BLOCK_TYPES` and `BLOCK_COSTS`. The "all types used" bonus now checks `#BLOCK_TYPES` rather than a hard-coded 5. That's the same today and stays correct when you add a type.

**Edge cases I kept on purpose**
- **`ipairs`:** I kept it rather than switching to plain `for ... in` loops, so reading still stops at the first `nil` in the array.
- **`getTallest` returning nothing:** with no qualifying block it still returns *no values*, not `nil`.
- **Ties and `NaN` in `getTallest`:** the first block wins a tie, and `NaN` heights behave the same as before.
- **Height floor:** it still never drops below 0, and `NaN` tops are still ignored.
- **The `summarize` error:** it raises the same message as before, with no file position added.
- **Large numbers:** formatting still gives `"1e+15"`, because Luau's `tostring` switches to that form for very large numbers.
- **Numeric block types:** the old lookup table held the type names both as keys and as a list. That meant `Type = 1` through `5` counted as a known type in `getTallest`. I kept that through `isKnownType`, with a comment explaining why.

**Inputs that used to crash and now return a value**
- **`summarize` with `Type = 1` to `5`:** this used to error (it added a string to a number). It now skips the block.
- **`format` with `NaN` or infinite numbers:** this used to error inside `gsub`. It now returns `"nan"` or `"inf"`.
- **`format` with a nonsense `Variety`:** a table or `nil` used to error on concatenation. It now gets turned into text.

For every input the old code handled, the result should be the same.

**Before merging, run `luau-analyze` and StyLua.** There are two things I couldn't confirm:
- I followed your style guide's use of `const`, which needs a Luau version that supports it.
- `getTallest` is typed `Block?` but ends with a bare `return`. I expect strict mode to accept that, but haven't checked.