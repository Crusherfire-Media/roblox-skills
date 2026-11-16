I fixed the bug in `BlockInventory.take` and added a regression spec. luau-lsp, selene and StyLua all pass. As expected, I couldn't run the specs themselves because they only run in Studio.

**Cause:** `take` (`src/ServerScriptService/Inventory/BlockInventory.luau:47`) only checked whether there were enough blocks when the block type already had an entry:

```lua
local current = inventory.Counts[name]
if current and current < amount then return false end
inventory.Counts[name] = (current or 0) - amount
```

The starter kit has no `Window` entry, so `current` was `nil`. That skipped the check, the take succeeded, and the count was set to `0 - 1 = -1`. After that, `-1` was a real number that failed the check, which is why players got exactly one Window and then nothing. Brick, Dirt, Grass and Wood are in the kit, so they always had an entry and stopped correctly at 0.

**Fix:** A missing entry now counts as 0 before the check (`local current = inventory.Counts[name] or 0`), which matches how `count` and `add` already treat missing types. `BlockPlacement.server.luau` didn't need changes.

**One change beyond the report:** `take` now also refuses a negative `amount`. Without that, taking a negative number would add blocks and skip the `MaxStack` cap that `add` enforces. The server only ever calls `take(..., 1)`, so the game behaves the same. If you meant negative takes to be allowed, the guard is one condition you can remove.

**Regression spec:** `src/ServerScriptService/Tests/Specs/Inventory/BlockInventory.spec.luau` tests:
- **The reported bug:** a starter-kit inventory refuses `Window`, the count stays 0, and no `Counts.Window` entry is created.
- **Empty inventory:** repeated takes are all refused.
- **Normal types:** taking down to 0 works, then the next take is refused.
- **Too many:** asking for more than the inventory holds is refused and the count doesn't change.
- **Negative amount:** refused.
- **Added later:** a type that was missing and then added can be taken normally.

**Checks:** I regenerated `sourcemap.json` first, as the README says. That rewrites a tracked file, so it may show up in your diff. The new spec and `JestGlobals` both appear in the sourcemap, so luau-lsp did type-check the spec's requires. I haven't committed anything.