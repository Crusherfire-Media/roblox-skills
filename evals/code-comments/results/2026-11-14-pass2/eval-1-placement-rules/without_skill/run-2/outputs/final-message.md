I've written the module at `src/ReplicatedStorage/Shared/PlacementRules.luau`. I haven't run or checked it: my command to run stylua, selene and luau-lsp was blocked because this session can't approve commands. Please run the four commands from the README before you build on it.

**What the module provides**
- **Settings you can change:** `BLOCK_SIZE` (4), `GROUND_Y` (0, the top of the Baseplate), `MAX_HEIGHT` (200), `MAX_REACH` (24) and `BLOCK_TYPES`.
- **`snap(position)`** returns the center of the 4-stud grid cell that contains the position. Cell centers sit at 4k+2 on every axis, so a block on the bottom layer rests on the Baseplate. Snapping a center gives back the same center.
- **`snapFromHit(hitPosition, hitNormal)`** is for the preview's raycast. A hit point lies exactly on a cell edge, so it first moves half a block out from the surface. Clicking the ground or the top of a block gives the cell above it; clicking a block's side gives the cell beside it.
- **`check(player, blockType, position, blocksFolder)`** returns `true, nil, cellCenter` when the spot is allowed, or `false, reason` when it isn't. It snaps the position itself, so the client can send a raw point or a cell center and the server places the block at the `cellCenter` it gets back.

**How `check` works, in order**
1. **Block type:** it must be a string and one of the five. Otherwise: `"invalid block type"`.
2. **Garbage input:** the position must be a `Vector3` with no NaN or infinite parts, and it's checked again after snapping. Very large but finite numbers just fail the reach check. Reasons: `"position is not a Vector3"` and `"position is not finite"`. These checks happen before any maths, so bad input shouldn't cause an error.
3. **Height:** the whole block must be between Y 0 and Y 200, so the top layer is the 196–200 cell. Reasons: `"below ground"` and `"above height limit"`.
4. **Reach:** the distance is measured from the HumanoidRootPart to the snapped block's center. If the player has no character or root part, it fails with `"no character"` instead of erroring. Otherwise: `"out of reach"`.
5. **Overlap:** it searches only inside `blocksFolder`, using a box slightly smaller than a block, so blocks touching face to face are allowed. Reason: `"overlaps a block"`.

**Things to know**
- **Block type names:** I used lowercase (`"brick"`, `"dirt"`, …) to match how you wrote them. Your picker and remote need to send those exact strings, or you can change the list.
- **Ghost preview:** don't put it inside `blocksFolder`, or every spot will count as an overlap.
- **Placed blocks:** the overlap search skips parts with `CanQuery` turned off, so leave it on for placed blocks.
- **Ground height:** `GROUND_Y` is a fixed 0 rather than read from the Baseplate, so loading the module never depends on the Baseplate having loaded yet. If you move or resize the Baseplate, update it.
- **Performance:** each call does one spatial search, which should be fine for checking the preview every frame.