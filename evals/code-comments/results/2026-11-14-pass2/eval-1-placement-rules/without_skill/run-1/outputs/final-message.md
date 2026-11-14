I've written the module at `src/ReplicatedStorage/Shared/PlacementRules.luau`. It passes selene and StyLua. The type checker found one real error, a bad type cast, which I fixed. There were no Roblox type definitions installed, so Roblox names like `Vector3` and `BasePart` couldn't be checked; I hid those warnings and the rest came back clean. I haven't run it in Studio, so none of the rules have been tested against real input yet. Nothing is committed.

**How you call it**
```lua
local center, reason = PlacementRules.validate(blockType, position, rootPart, placedFolder)
if not center then warn(`{player.Name}: placement rejected ({reason})`) return end
-- place the block at `center`
```
- **Client preview:** make the same call each frame and tint the ghost red when it returns `nil`.
- **Server:** if the check passes you get back the snapped center of the block, so put the block there rather than at whatever position the client sent.
- **Reasons it can give:** `invalid block type`, `position is not a Vector3`, `position is not finite`, `below ground`, `too high`, `no character`, `out of reach`, `space occupied`.

**How each rule works**
- **Block types:** `BLOCK_TYPES` lists `"Brick" | "Dirt" | "Grass" | "Window" | "Wood"` in that order, which the picker can use. Anything that isn't a string from that list is rejected without erroring.
- **Snapping:** `PlacementRules.snap(pos)` returns the center of the 4-stud grid cell the point falls in. The grid starts at `GROUND_Y = 0`, the top of the Baseplate. Snapping a center gives back the same center, so it doesn't matter if the client has already snapped.
- **Height:** cells are allowed from the ground up to where the top of the block is at 200, so there are 50 layers.
- **Reach:** measured from the `HumanoidRootPart` to the block's center, up to 24 studs.
- **Overlap:** checked with `GetPartBoundsInBox`, limited to the folder you pass in. The box is shrunk by 0.05 on each side so blocks touching face to face don't count as overlapping.
- **Garbage input:** wrong types, NaN and infinity are rejected up front. Huge numbers that are still finite get snapped and then fail the height or reach check.

**Things to watch when you wire it up**
1. **Click position:** don't send the raw raycast hit. A hit sits exactly on a cell edge and can snap to the wrong side, which shows up as a random `below ground` when clicking the Baseplate. Push it into the cell first: `snap(hit.Position + hit.Normal * 2)`.
2. **Ghost preview:** keep it out of `placedFolder`, or it will count as overlapping itself. Placed blocks need `CanQuery = true` (the default) for the overlap check to see them.
3. **Ground height:** `GROUND_Y` is a fixed 0, taken from the Baseplate in `default.project.json`. That way the client and server can't disagree, but you'll need to update it if the Baseplate moves.
4. **Not checked:** a block can overlap the player, the SpawnLocation, or sit past the Baseplate's edge if the player stands at the rim. You didn't ask for those rules; I can add any of them.