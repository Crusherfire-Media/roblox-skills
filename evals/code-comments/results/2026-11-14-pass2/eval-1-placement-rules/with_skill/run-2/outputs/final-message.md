I've written the module at `src/ReplicatedStorage/Shared/PlacementRules.luau`. It passes StyLua and selene. It has not been type-checked or run: the type-check command needed approval, and this session couldn't ask for it. Before you build on it, open it in Studio with strict mode on and check Script Analysis, then try a few placements.

**What it exposes**
- `validatePlacement(blockType, position, context)` takes the block type and position as raw remote arguments, plus `{ Baseplate, PlacedBlocks, RootPart }`. It never errors on bad input. It returns either `{ Ok = true, BlockType, Position }`, where `Position` is the snapped spot to place the block, or `{ Ok = false, Reason }`.
- The reasons, checked in this order: `"invalid block type"`, `"invalid position"`, `"below ground"`, `"too high"`, `"no character"`, `"out of reach"`, `"overlaps a block"`.
- `snapToGrid(position, baseplate)` returns the center of the grid cell that contains the point. Snapping a center gives back the same center, so the client can send its snapped preview position and the server snapping it again won't move it.
- `getCellFromHit(hitPosition, normal, baseplate)` is an extra helper for the preview. A mouse hit lands exactly on a cell edge, so this nudges it half a block out from the face first. Clicking the top of a block or the ground then puts the new block on top of it.
- `isBlockType`, `getGroundHeight`, and the constants `BlockSize`, `MaxHeight` and `MaxReach`.

**Choices you may want to change**
- **Names:** the block types are `"Brick" | "Dirt" | "Grass" | "Window" | "Wood"`, with capital first letters. The picker has to send those exact strings.
- **Grid:** up and down, the grid starts at the top of the Baseplate. Sideways, it lines up with the world origin. With your Baseplate centered at 0, that matches its edges anyway.
- **Height limit:** the top of a block can be at most 200 studs above the ground, which allows 50 layers.
- **Reach:** measured from the HumanoidRootPart to the center of the block.
- **Overlap:** checks every part directly inside the folder you pass. It assumes blocks aren't rotated. Blocks sitting face to face pass. Anything in the folder that isn't a part, such as a Model, is ignored.
- **Garbage input:** NaN and infinite values are rejected outright, because NaN would otherwise slip past the distance check. Wrong types are rejected before anything reads them.
- **Rotation:** the module assumes the Baseplate isn't rotated.

I haven't committed anything.