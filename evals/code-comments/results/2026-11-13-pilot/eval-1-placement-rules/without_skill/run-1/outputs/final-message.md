I added the module at `src/ReplicatedStorage/Shared/PlacementRules.luau`. The type check, selene and stylua all pass, but I haven't run it in Studio or tested it against real input yet. Nothing is committed.

**How to call it:**
```luau
local cell, reason = PlacementRules.check(player, blockType, position, blocksFolder)
if not cell then
	warn(`{player.Name} placement rejected: {reason}`)
	return
end
-- cell is the snapped block centre — place the block there
```
On success it returns the snapped centre of the block; on failure it returns `nil` and a reason. `blockType` and `position` accept any type, so you can pass the remote's arguments straight in. `player` and `blocksFolder` are trusted, because they come from your own server code.

**How each rule is handled:**
- **Block type:** must be exactly `"Brick"`, `"Dirt"`, `"Grass"`, `"Window"` or `"Wood"`. These are case-sensitive and capitalised, so the picker UI must send them the same way. The list is available as `PlacementRules.BLOCK_TYPES`, and there's an exported `BlockType` type.
- **Snapping:** `snap(position)` gives the centre of the 4-stud cell containing a point. The grid lines up with X/Z = 0 and with the top of the Baseplate (Y = 0, hardcoded), so a block on the ground has its centre at Y = 2. The server snaps the position again itself, so the client can't place blocks off the grid. Snapping an already-snapped centre returns the same centre.
- **Preview:** use `snapFromSurface(hit.Position, hit.Normal)`. A raycast hit sits exactly on a cell boundary, so this pushes the point half a block out along the surface normal before snapping. Otherwise float error can pick the cell underground or inside the block you clicked. Then pass the result to `check()` to decide whether to tint red, and keep the ghost part itself out of the blocks folder.
- **Height:** the block's bottom can't be below Y = 0, and its top can't be above Y = 200, which gives 50 layers.
- **Reach:** distance is measured from the HumanoidRootPart to the block's centre and must be 24 studs or less. If the player has no character, the reason is `"no character"`.
- **Overlap:** each block is checked as a box against every BasePart or Model in the folder, with a small tolerance so blocks that only share a face pass. It assumes placed blocks aren't rotated. It loops over the whole folder on every call, which is fine for now but will get slower as the folder grows into the thousands.
- **Garbage input:** a wrong type, NaN or infinity is rejected before any maths. Huge but finite numbers fail the reach check instead of causing an error.

The possible reasons are: `invalid block type`, `position is not a Vector3`, `position is not finite`, `below ground`, `too high`, `no character`, `too far away` and `overlaps a placed block`.

**Not checked:** placing a block inside a player (including yourself) or on the SpawnLocation is allowed, since neither was in your rules. Both are easy to add if you want them.