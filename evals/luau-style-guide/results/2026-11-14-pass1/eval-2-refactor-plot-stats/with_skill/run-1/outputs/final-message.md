I've rewritten `src/ReplicatedStorage/Shared/PlotStats.luau`. It now starts with `--!strict` and exports `Block` and `Summary` types. `summarize`, `getTallest`, `format` and `compare` keep their names and arguments. StyLua passes. The strict type check (`luau-lsp analyze`) reported one error: `Unknown type 'Vector3'`. That's only because the project has no Roblox definitions file for the checker to load. I tried to re-check a copy with a `Vector3` stand-in, but the session blocked it: the shell command needed approval, and the file tools can't write outside the project. So run `luau-lsp analyze` with Roblox definitions, or open the file in Studio, before you count it as fully passing.

**What changed:**
- **Block types are listed once.** One table holds each type's name and cost, and the cost lookup is built from it. The old version listed every type twice in a table that mixed a list with name-to-cost keys. Adding a type is now one line.
- **Numbers have names.** The 4-stud block height, the bulk discount (more than 50 blocks, ×0.9) and the score weights are named constants.
- **Code is split up.** Thousands-separator formatting, counting block types used, and the score maths are now small helper functions. The deep `if` nesting became guard clauses, and the accidental global `fmt` is now local.
- **Variety bonus:** the "used every type" bonus checks against the number of block types instead of a hard-coded `5`. The result is the same today, and it stays right if you add a type.

**Odd behaviours I kept on purpose,** each marked with a comment:
- `getTallest` returns no values at all when nothing qualifies, rather than `nil`. Code that counts return values can tell the difference.
- `getTallest` also accepts a block whose `Type` is a number from 1 to 5. The old lookup table also stored the type names at those list positions, so the leaderboard may already depend on this.
- Both functions still stop reading at the first gap (`nil`) in the blocks list, because they use `ipairs`.
- The "expected a table" error message reads exactly as before, with no file and line prefix.
- Height is never below 0. Score uses the rounded-down height; `Height` itself isn't rounded.
- Formatting is the same as before: separators, rounding down, one decimal for height, and singular "block"/"type" for a count of 1.

**Inputs that used to crash and now don't** (nothing worked with these before, so no caller can depend on them):
- `summarize` with a numeric `Type` used to throw an arithmetic error. It now skips that block.
- `format` with an infinite or NaN `Total` or `Score` used to throw. It now prints `inf` or `nan`.

**Kept despite the style guide:**
- **`format`'s `short` switch:** the guide prefers two functions over a true/false argument, but the signature had to stay. It's typed `boolean?`.
- **Table check in `summarize`:** the guide would drop this check on a typed argument. I kept it because callers that aren't strict-checked can still pass anything.

I couldn't run old and new side by side. I worked out the matching behaviour by reading the code, and Roblox's test tools (Jest) weren't usable in this session. A spec covering the edge cases above would be a cheap safety net.