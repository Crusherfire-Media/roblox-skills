I refactored `src/ReplicatedStorage/Shared/PlotStats.luau`, and it's the only file that changed. It passes StyLua and has no errors under `--!strict` in luau-lsp. I didn't run any tests, so the claim that the four functions return the same results is based on reading the code carefully against the original, not on a test run.

**What changed**
- **Constants:** the magic numbers are now named constants (block costs, block half-height, bulk discount, score points, all-types bonus). Block costs live in one table, `BLOCK_COSTS`, and the number of block types is counted from it. To add a block type you add one line there, and variety, the all-types bonus and the numeric-Type check all adjust.
- **Types:** there are exported `Block` and `Summary` types, and all four public functions have typed parameters and return values. `Block.Type` is `unknown` because the code checks it while running.
- **The old `fmt` helper:** it took two true/false switches and was accidentally a global. It's now two local functions: `formatWholeNumber` (rounds down, adds commas) and `formatOneDecimal`.
- **Structure:** guard clauses with `continue` replace the deep nested `if`s. Both list loops now share one check, `isKnownType`, for which blocks count. The returned table is named `Module`, per the style guide.

**Odd behaviors I kept on purpose, so the results don't change**
- **Numeric `Type`:** the old lookup table mixed type names with list positions, so a block with `Type = 1` through `5` counted as known. `getTallest` returns such blocks today, so it still does. `summarize` always crashed on them (it tried to add a string to a number), and it still raises an error, now with a clear message. Do you know whether any real data has numeric types? If not, this rule can be deleted.
- **`getTallest` with nothing to return:** it gives back no values at all, not `nil`. So `tostring(PlotStats.getTallest({}))` still errors, and `select("#", ...)` is still 0. A comment marks the bare `return` so nobody "fixes" it.
- **Gaps in the list:** both functions still stop at the first `nil` in the block list, so blocks after a gap stay uncounted. They also still keep the first block on a height tie, handle NaN heights the same way, and start height at 0.

**Changes only for inputs that used to crash**
- `summarize` no longer has its own "expected a table" check, because the type annotation covers it. A non-table still errors, just with Luau's built-in message.
- A block with `Position = false` is now skipped instead of crashing.
- `format` on a summary with no `Variety` now prints "nil" instead of erroring.
- Formatting infinity or NaN still errors, with a clearer message.

**How I checked it**
- The Bash tool and some PowerShell commands were blocked because this session can't approve prompts. Most of my file and tool searches couldn't run.
- I also couldn't write a Roblox definitions file outside the project, so for the type check I briefly added a stand-in `Vector3` type inside this file and removed it afterwards.
- A real Studio or luau-lsp run with the Roblox definitions is still worth doing.