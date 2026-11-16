I've rewritten `src/ReplicatedStorage/Shared/PlotStats.luau` and it now starts with `--!strict`. Nothing has been run: the session blocked every shell command, so I couldn't type-check it with luau-lsp, format it with StyLua or test it with Lune. I checked the behavior by reading the code against the original, line by line.

**What changed**
- **Types:** the four functions are fully typed, and the module exports `BlockType`, `PlotBlock` and `Summary`.
- **One table split in two:** the old `T` mixed a list of names with a name-to-cost lookup. It's now `BLOCK_TYPES` (the list, in order) and `BLOCK_COSTS` (the costs), with a note to keep them in sync.
- **Named constants:** the bare numbers are now named: the half-height of 2, the score points (10, 2, 25, 100) and the bulk discount (more than 50 blocks, ×0.9).
- **Smaller pieces:** the "all types used" bonus checks `#BLOCK_TYPES` instead of a hard-coded 5, so adding a block type means adding it to both tables. `fmt` with its two true/false flags is now `formatWholeNumber` plus a `"%.1f"` call. Scoring and counting the types used moved into small helpers, and the nested `if`s became early `continue`s.
- **Two side effects gone:** `fmt` is no longer a global, and the module's returned table is now named `Module` inside the file.

**Edge cases that still work the same**
- Both loops still use `ipairs`, so blocks after a `nil` gap in the list are still ignored. A plain `for ... in` loop would have changed that.
- Height starts at 0, and the top of a block is `Position.Y + 2`. `Height` stays unrounded and only the score rounds it down.
- On a tie, `getTallest` still returns the first block. It still returns **no values at all** (not `nil`) when nothing qualifies, so `select("#", ...)` gives the same result.
- The old code also treated the numbers 1–5 as block types in `getTallest`, so `getTallest({ { Type = 1, Position = ... } })` returns that block. I kept that in one small helper. If no caller passes numbers, you can delete it.
- `summarize` still raises exactly `summarize expected a table of blocks, got <type>` with no file prefix, using `error(msg, 0)`.
- `format` gives the same strings, including "1 block" / "1 type", the thousands commas (negative numbers too) and one decimal place for height.

**Inputs that used to crash and now don't**
These never returned anything before, so no existing caller can depend on them:
- `summarize` with a number 1–5 as a block type used to crash on the cost line. It now skips that block.
- `format` with a value that has no digits, such as NaN or infinity, still raises an error, but with a clearer message.

**Still to check**
1. Run luau-lsp in strict mode. The one line I'm least sure about is the bare `return` in `getTallest`, whose declared return type is `PlotBlock?`. I expect Luau to accept it, but I couldn't confirm.
2. Run StyLua on the file. I hand-wrapped the score calculation, and StyLua may lay it out differently.