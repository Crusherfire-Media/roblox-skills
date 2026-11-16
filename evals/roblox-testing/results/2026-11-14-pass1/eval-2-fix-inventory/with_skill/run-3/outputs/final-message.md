I fixed the bug and added the regression test. luau-lsp, selene and StyLua all pass. The spec hasn't been run, since there's no Studio here, so its first real run will be yours.

**Cause:** in `BlockInventory.take` (`src/ServerScriptService/Inventory/BlockInventory.luau:47`), the "not enough blocks" check only ran when the block type already had an entry:

```lua
local current = inventory.Counts[name]
if current and current < amount then
```

Window isn't in the starter kit, so it had no entry. The check was skipped, the placement went through, and the count became `0 - 1 = -1`. After that the entry existed, so the check worked again, which is why it stopped at -1. Brick, Dirt, Grass and Wood all start with an entry, so they stopped at 0 as they should.

**Fix:** a missing entry now counts as 0 before the check (`local current = inventory.Counts[name] or 0`, then `if current < amount`). The behavior matches what the function's comment already said. `BlockPlacement.server.luau` didn't need any changes.

**Regression test** (`src/ServerScriptService/Tests/Specs/Inventory/BlockInventory.spec.luau`): one table-driven test with two rows. Each checks that `take` returns `false` and the count stays at 0:
- **A type the inventory was never given** (Window, with only Brick in the kit): this is the reported bug, and it fails on the old code.
- **A type it has an entry for, but at 0** (Brick = 0): this covers the case that already worked, so the two ways of having no blocks are both tested.

To run it in Studio with Rojo synced, call Jest's `runCLI` with `testPathPattern = "Inventory/BlockInventory"`.

**Checks:** I regenerated the sourcemap and ran the README commands one at a time. luau-lsp reported nothing, selene had 0 errors and 0 warnings, and `stylua --check` passed. One combined command was blocked by the permission system, so I ran them separately instead; nothing was skipped. Regenerating the sourcemap didn't change any tracked file.

**Calls I made:**
- I tested at `BlockInventory.take`, not through the `PlaceBlock` remote. The remote needs a real Player and a running game, which a spec can't provide.
- I didn't touch the case where `take` is passed a negative amount, which would add blocks. The server only ever passes 1, so it's out of scope.
- Nothing is committed. The changes are the fix and the new spec, both uncommitted in the working tree.