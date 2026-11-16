I've added `src/ReplicatedStorage/Shared/PlacementRules.luau`. StyLua, selene and luau-lsp all pass on it, but I haven't run it in Studio or written any specs yet.

**What it exposes**
- **`PlacementRules.check(blockType, position, context)`** is the one call both the client and the server use. `blockType` and `position` are typed `unknown`, so the server can pass in whatever came over the remote. `context` is `{ RootPart = hrp?, BlocksFolder = folder }`, and those two come from the server, not the client. It never errors and returns one of:
  - `{ Ok = true, BlockType = ..., Position = snappedCenter }`: place the block at `Position`.
  - `{ Ok = false, Reason = ... }`, where `Reason` is one of `UnknownBlockType`, `InvalidPosition`, `BelowGround`, `TooHigh`, `NoCharacter`, `TooFar` or `Occupied`. These are short enough to log as they are.
- **`PlacementRules.snapToGrid(point)`** returns the center of the 4-stud cell that contains `point`. The grid starts at Y = 0, so a block on the ground has its center at Y = 2.
- **`PlacementRules.isBlockType(value)`**, plus `PlacementRules.BlockTypes` (the five names, in order, for your picker) and `PlacementRules.BlockSize`.

**Things to know when you wire it up**
- **Block names:** they are `"Brick"`, `"Dirt"`, `"Grass"`, `"Window"` and `"Wood"`, and the match is case-sensitive. The client has to send exactly these strings.
- **The server snaps every position itself**, so a client can't place a block off the grid. Sending either the cell center or the raw point works.
- **Preview positions:** for the ghost, pass the raycast hit plus a nudge along the surface normal: `hit.Position + hit.Normal * (BlockSize / 2)`. A point exactly on a face can round into the cell on the wrong side, which would make clicks on the ground come back `BelowGround`.
- **Height limits:** the bottom of a block can't go below Y = 0 and its top can't go above Y = 200, so the grid is 50 layers tall. Reach is measured from the HumanoidRootPart to the center of the snapped block.
- **Garbage input:** anything that isn't a Vector3, or has a NaN or infinite component, is rejected as `InvalidPosition`. Very large numbers that are still finite get snapped and then rejected by the height or reach checks.
- **Overlap check:** this is a box query against the blocks folder, shrunk by 0.05 studs on each side so blocks that share a face don't count as overlapping. Placed blocks need to stay in Workspace with `CanQuery` on, or the check won't see them.
- **Ground height is a fixed value:** Y = 0 is a constant in the module, with a comment to keep it in sync with the Baseplate in `default.project.json`. I didn't read it from `workspace.Baseplate` because with streaming turned on, the client might not have the Baseplate loaded.

Nothing is committed.