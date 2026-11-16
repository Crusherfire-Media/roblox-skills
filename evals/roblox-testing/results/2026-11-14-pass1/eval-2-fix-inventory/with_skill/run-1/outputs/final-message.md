I fixed the Window bug and added the regression test. luau-lsp, selene and StyLua all pass on `src`. The specs themselves haven't run, because there's no Studio here, so nothing has confirmed the new test fails on the old code and passes on the new.

**Cause:** `BlockInventory.take` (`src/ServerScriptService/Inventory/BlockInventory.luau:47`) only refused when it had a count to compare. A block type missing from the inventory has no count at all, and Window is the only type missing from the starter kit. So the check was skipped, the take went through, and the count was set to 0 − 1 = −1. After that the count was a real number below 1, so every later Window placement was refused. Brick, Dirt, Grass and Wood are all in the kit, which is why they stopped correctly at 0.

**Fix:**
- `take` now treats a missing type as 0 before comparing, so taking one is refused and nothing changes.
- I also changed the `Counts` type to `{ [string]: number? }`. With the old type, luau-lsp assumed every lookup returned a number, so it couldn't flag the missing case. Nothing outside the module reads `Counts` directly, so nothing else changed.
- `BlockPlacement.server.luau` needed no change: it already returns early when `take` refuses.

**Regression test** (`src/ServerScriptService/Tests/Specs/Inventory/BlockInventory.spec.luau`), three tests through `BlockInventory.new`, `take` and `count`:
- **Taking a type the inventory never held** is refused, and the count stays 0. This is the bug from the report.
- **Taking more than the inventory holds** is refused, and the count is unchanged.
- **Taking the last block of a type** succeeds and leaves 0, so the fix can't pass by refusing everything.

**Assumptions:**
- I didn't add a test for `BlockPlacement` itself: that would need fake players and remotes, and the bug was entirely in `take`.
- The test files are new and not committed. I didn't commit anything because you didn't ask.

**To run it:** in Studio with Rojo synced, call Jest's `runCLI` with `testPathPattern = "Inventory/BlockInventory"`. The never-held case should pass now; on the old `take` it would have failed with the result `true`.