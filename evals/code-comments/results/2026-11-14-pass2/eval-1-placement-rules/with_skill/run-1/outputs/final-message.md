I've written the module at `src/ReplicatedStorage/Shared/PlacementRules.luau`. The type checker (luau-lsp with Roblox definitions), selene and StyLua all pass with no errors. I haven't run it in Studio, so the rules are untested in a live game.

**What it gives you**

- **`PlacementRules.validate(player, blockType, position, blocksFolder)`** returns either `{ Success = true, Position = snappedCenter }` or `{ Success = false, Reason = ... }`. The reason is one of `"InvalidBlockType"`, `"InvalidPosition"`, `"BelowGround"`, `"TooHigh"`, `"NoCharacter"`, `"TooFar"` or `"Overlaps"`. The server can pass `blockType` and `position` straight from the remote. Wrong types, NaN and infinity get a reason back instead of an error, and very large numbers fail the height or distance check.
- **`PlacementRules.snapPosition(point)`** returns the center of the 4-stud cell the point falls in. The grid lines are at multiples of 4 from the Baseplate top (Y = 0), so the bottom layer of centers is at Y = 2.
- **`PlacementRules.snapFromSurface(hitPosition, hitNormal)`** is for the ghost preview. A raycast hit lands exactly on a cell boundary, so snapping it directly can pick the cell behind the surface you clicked. This helper first moves the point half a block out along the surface normal.
- It also exposes `BlockTypes`, `BlockSize`, `isBlockType(value)` and the exported types `BlockType`, `FailureReason` and `PlacementResult`.

**Choices worth checking**

- **Block type names** are PascalCase: `"Brick"`, `"Dirt"`, `"Grass"`, `"Window"`, `"Wood"`. The client must send exactly these strings.
- **Off-grid positions get snapped, not rejected.** `validate` snaps whatever position it receives, and on success returns the cell center. The server should build the block at that returned `Position`, not at the raw one the client sent.
- **Height limit:** the block's bottom must be at or above Y = 0 and its top at or below Y = 200, so the highest allowed center is Y = 198.
- **The 24-stud reach** is measured from the HumanoidRootPart to the block's center, not to its nearest face. If the player has no character or root part, the request fails with `"NoCharacter"`.
- **Overlap check:** it runs `workspace:GetPartBoundsInBox` on the passed folder, using a box slightly smaller than a block so that blocks touching side by side don't count as overlapping. This works whether the placed blocks are single Parts or Models, but it needs:
  - the folder to be inside Workspace
  - the blocks to keep `CanQuery` on (the default)
- **Baseplate height is hardcoded.** The module stores the Baseplate top as `GROUND_HEIGHT = 0`, with a comment to keep it in sync with `default.project.json`. It doesn't read `Workspace.Baseplate` at runtime, because on the client the part might not have loaded yet. If you resize or move the Baseplate, update that constant too.