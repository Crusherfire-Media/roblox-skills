I fixed the Window bug and added a regression test. luau-lsp, selene and StyLua all pass with no errors. As you said, the specs can't run here, so the new tests haven't been run yet.

**Cause:** `BlockInventory.take` didn't treat a missing block type as zero. The starter kit has no `Window` entry, so the check `if current and current < amount` skipped the refusal and the count was set to `0 - 1 = -1`. After that, `-1 < 1` blocked any more placements, which is the behaviour testers saw. The other block types are in the starter kit, so they stopped correctly at 0.

**Fix** (`src/ServerScriptService/Inventory/BlockInventory.luau:47`): `take` now counts a missing block type as 0 before checking, the same way `count` and `add` already do. `BlockPlacement.server.luau` didn't need changes.

**Regression test** (`src/ServerScriptService/Tests/Specs/Inventory/BlockInventory.spec.luau`): it uses Jest Roblox and checks five cases:
- Taking a Window from a kit that doesn't include Windows fails, and the count stays at 0. This is the exact bug.
- Repeated takes from an empty inventory all fail.
- A block type from the starter kit stops at 0.
- Taking more than the inventory holds fails and changes nothing.
- Once a Window has been added, it can be taken, and only once.

**Checks:** I rebuilt `sourcemap.json` with Rojo, and that file has changed because of the new spec. luau-lsp then found the spec and the Jest globals and reported no type errors. selene reported 0 errors and 0 warnings, and `stylua --check` found nothing to change. Two of my first commands were blocked by permissions, a file listing and a single combined check command, so I ran each check separately instead.

**Decision for you:** `take` still accepts a negative amount, which would add blocks and could go past `MaxStack`. Nothing calls it that way today (placement always takes 1), so I left it alone to keep the fix small. If you want it guarded, the change is to reject any amount below 0 at the start of `take`.