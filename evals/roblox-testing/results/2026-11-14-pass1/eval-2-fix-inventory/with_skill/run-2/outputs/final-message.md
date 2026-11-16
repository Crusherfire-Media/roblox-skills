I fixed the bug and added a regression test. luau-lsp, selene and StyLua all pass. The spec hasn't been run, because it needs Studio. So it hasn't been seen to fail on the old code or pass on the new code; I only checked that by reading it.

**Cause.** `BlockInventory.take` only refused when the block type had an entry in the inventory and that entry was too low. Window isn't in the starter kit, so it has no entry at all. That let the first take through and set the count to `0 - 1 = -1`. After that, `-1 < 1` refused every later take. The other block types all have entries in the kit, so they stopped at 0 correctly.

**Fix** (`src/ServerScriptService/Inventory/BlockInventory.luau:48`): a missing block type now counts as 0 before the check:
```lua
local current = inventory.Counts[name] or 0
if current < amount then
	return false
end
inventory.Counts[name] = current - amount
```
`BlockPlacement.server.luau` didn't need any changes: it already does nothing when `take` returns false.

**Regression test** (`src/ServerScriptService/Tests/Specs/Inventory/BlockInventory.spec.luau`): one table-driven test of `take`, asking for 3 Windows each time. For each case it checks whether the take succeeded and how many are left:
- **A type it was never given** (the bug): refused, 0 left. On the old code this row should fail with `true` and `-3`.
- **Fewer than asked:** refused, still 2.
- **Exactly as many as asked:** succeeds, 0 left.

When you have Studio open, run it with a `testPathPattern` of `Inventory/BlockInventory`.

**Assumptions:**
- The testing guidelines say to agree the list of tested behaviors with you before writing specs. You weren't available, so I picked these three cases myself.
- I tested `BlockInventory` on its own rather than through `BlockPlacement`. That script makes a RemoteEvent and listens for real players as soon as it loads, so it can't run in a spec. Its handling of a refused take is a simple early return.
- The new spec file uses `const` and `--!strict`, following the project's style guide. I left the existing files' `local` style alone so the diff only contains the fix.

Nothing is committed.