I've added `src/ReplicatedStorage/Shared/PlacementRules.luau`. The type checker, selene and stylua all pass on it. I haven't run it yet: my quick Lune test of the snapping and the garbage-input handling was blocked by the permission system, so the code is type-checked but not executed.

**How to use it**

```lua
local cell, reason = PlacementRules.check(player, blockType, position, blocksFolder)
if not cell then warn(`{player.Name}: {reason}`) return end
-- place the block with its center at `cell`
```

- **`check`** returns the snapped center of the grid cell on success, or `nil` and a short reason on failure. The reasons are: `invalid block type`, `invalid position`, `below ground`, `too high`, `no character`, `out of reach`, `overlaps a block`.
- **Bad input:** `blockType` and `position` can be anything the client sends. Wrong types, NaN and infinities get a reason back instead of an error.
- **`snap(position, surfaceNormal?)`** gives the center of the 4-stud cell that `position` falls in. The bottom layer of cells sits on the Baseplate's top surface (Y = 0). For the preview, pass the raycast hit normal: it pushes the point half a block out from the clicked face. Without it, clicking the side or bottom of an existing block would pick that block's own cell. The server re-snaps whatever arrives, and snapping a cell center gives back the same center.
- **Constants:** `BLOCK_TYPES`, `BLOCK_SIZE`, `GROUND_Y`, `MAX_HEIGHT`, `MAX_REACH`, and `isBlockType()` are exported so the picker UI can use the same list.

**Choices I made that you might want to change**

- **Block type names** are `"Brick"`, `"Dirt"`, `"Grass"`, `"Window"`, `"Wood"`, with a capital letter. Use the same strings in your remote and UI.
- **Height limit:** "more than 200 studs up" applies to the top of the block, so the highest layer ends exactly at 200.
- **Reach** is measured from the HumanoidRootPart to the block's snapped center. Anything 24 studs or closer is allowed.
- **Overlap** checks for actual intersection, with 0.01 studs of tolerance, so blocks touching face to face are fine. It looks at every Part or Model directly inside the folder you pass, and rotated ones are handled.
- **Ground height** is hard-coded as `GROUND_Y = 0` to match `default.project.json`, not read from the Baseplate. That's because the Baseplate might not have streamed in yet on the client. If you move or resize the Baseplate, update this constant.

One caveat for the server: the player's character position is controlled by the client, so the reach check is only as trustworthy as that position.