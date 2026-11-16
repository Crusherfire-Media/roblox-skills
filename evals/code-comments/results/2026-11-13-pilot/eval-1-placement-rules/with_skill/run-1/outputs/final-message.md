I added `src/ReplicatedStorage/Shared/PlacementRules.luau`. luau-lsp (strict mode), selene and stylua all pass with no errors. I haven't run it in Studio yet, so none of the rules have been tested in a playtest.

**How you call it**

- `PlacementRules.validatePlacement(blockType, position, context)` takes `blockType` and `position` exactly as the remote delivers them. `context` holds `{ Baseplate, BlocksFolder, Player }`. It returns either:
  - `{ Success = true, BlockType, Position }`, where `Position` has already been snapped. The server should build the block at this position, not at the one the client sent.
  - `{ Success = false, Reason }`. Reasons are short and loggable, such as `"unknown block type"`, `"position is not finite"`, `"too far from the player"` or `"overlaps a placed block"`.
- `PlacementRules.snapPosition(position, baseplate)` is the shared snapping, so the preview and the server land on the same cell. `PlacementRules.BlockSize` is 4.
- The client can call the same function each frame with `Player = Players.LocalPlayer` and tint the ghost red whenever `Success` is false.

**How the rules work**

- **Grid:** 4-stud cells. On X and Z they line up with the Baseplate's corner, and vertically they start at its top surface, so the lowest layer rests on the ground. The grid is worked out from the Baseplate's position and size rather than hardcoded.
- **Height:** the block's bottom can't be below the Baseplate top, and its top can't be more than 200 studs above it.
- **Distance:** the block's center must be within 24 studs of `HumanoidRootPart`. If the player has no character, the request fails rather than erroring.
- **Overlap:** a single `GetPartBoundsInBox` check against `BlocksFolder`, using a box slightly smaller than 4×4×4 so blocks that only touch face to face are allowed.
- **Bad input:** anything that isn't a string or a `Vector3` is rejected with a reason. NaN and infinite values are rejected too. Huge numbers become infinity when stored in a `Vector3` and get caught by the same check.

**Two things to know when you wire it up**

- **Clicking a block's face:** snapping picks the cell that contains the point you pass in. A mouse hit on a block's face sits exactly on the cell boundary, which can pick the block you clicked instead of the cell in front of it. Nudge the hit position along the surface normal first, e.g. `hit + normal * 2`. This is also in the function's doc comment.
- **Ghost preview:** keep the ghost part out of `BlocksFolder`, or set `CanQuery = false` on it. Otherwise it will count as an overlap.

Running the type check regenerated `sourcemap.json`, so it now includes the new module and will show as changed in git. I haven't committed anything.