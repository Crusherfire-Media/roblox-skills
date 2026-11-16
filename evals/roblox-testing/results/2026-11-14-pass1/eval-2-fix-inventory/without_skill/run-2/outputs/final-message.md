I fixed the bug and added a regression spec. luau-lsp, selene and StyLua all pass with no errors or warnings. I couldn't run the spec itself, since specs only run in Studio.

**Cause:** in `BlockInventory.take` (`src/ServerScriptService/Inventory/BlockInventory.luau`), the "not enough blocks" check only ran when the block type already had an entry:

```lua
local current = inventory.Counts[name]
if current and current < amount then return false end
inventory.Counts[name] = (current or 0) - amount
```

Windows aren't in `STARTER_KIT`, so a new player's inventory has no Window entry at all. The check was skipped and the count was set to `0 - 1 = -1`. After that the entry existed, so later placements were refused. The other block types always had an entry, which is why they stopped correctly at 0.

**Fix:** a missing entry now counts as 0 before the check (`local current = inventory.Counts[name] or 0`), so taking a block type the player was never given fails and changes nothing. I left `BlockPlacement.server.luau` as it was: it already rejects the placement when `take` returns false.

**Regression test:** `src/ServerScriptService/Tests/Specs/Inventory/BlockInventory.spec.luau`
- The main case uses the real starter kit and checks that taking a Window fails, twice in a row, with the count staying at 0.
- It also covers a normal take, taking more than you hold, stopping at 0 for a type you were given, and an inventory created with nothing in it.

**Assumptions:**
- The spec loads Jest through `ServerScriptService.Tests.Packages.JestGlobals`, as the README says. The `require` calls resolved cleanly in luau-lsp, so the paths should be right in Studio too.
- `take` still doesn't reject zero or negative amounts. A negative amount would add blocks, and could push a count past `MaxStack`. Nothing calls it that way today (placement always takes 1), so I left it outside this fix. If you want, I can add a guard.