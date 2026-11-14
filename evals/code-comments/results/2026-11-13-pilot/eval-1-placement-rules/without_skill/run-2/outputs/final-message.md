I added `src/ReplicatedStorage/Shared/PlacementRules.luau`. selene, StyLua and the luau-lsp type check all pass. I haven't run it in Studio, so the rules haven't been tested in a live game yet. I didn't commit anything.

**How it's used**
- **`validate(player, blockType, position, placedFolder)`** is the main check. On success it returns the snapped block centre, so the server places the block exactly where the check said it could. On failure it returns `nil` and a short reason you can log: `"invalid block type"`, `"position is not a Vector3"`, `"position is not finite"`, `"below ground"`, `"too high"`, `"no character"`, `"out of reach"` or `"space occupied"`.
- **`snap(position)`** gives the centre of the 4×4×4 grid cell that contains a point. The cells start at the top of the Baseplate, so a block placed on the ground rests on it.
- **`snapFromSurface(hitPosition, normal)`** is for the client's ghost preview. It moves the raycast hit half a block outward along the face you clicked before snapping. Without that, clicking the side or underside of a block could pick the block's own cell instead of the empty one next to it.
- `BLOCK_TYPES` lists the five types in order for the picker, and the size, height and reach limits are exposed as constants.

**How it copes with bad input**
- Anything that isn't one of the five type names, or isn't a `Vector3`, is rejected before any maths runs.
- NaN and infinite coordinates are rejected first. This matters because NaN fails every comparison, so it would otherwise get past the distance check.
- Very large but finite numbers snap without erroring and then fail the reach check.
- `player` isn't checked because the remote supplies it, so it can be trusted.

**Choices you may want to change**
- **Type names** are `"Brick"`, `"Dirt"`, `"Grass"`, `"Window"` and `"Wood"`. The client has to send exactly these strings.
- **Ground height** is the constant `GROUND_Y = 0`, which matches the Baseplate in `default.project.json`, rather than being read from the part. That way the client and server always agree even if the Baseplate hasn't streamed in on the client yet. If you move or resize the Baseplate, update this constant.
- **Height limit:** a block's top can be at most 200 studs above the ground, which allows 50 layers.
- **Reach** is measured from the HumanoidRootPart to the block's centre.
- **Overlap** uses `workspace:GetPartBoundsInBox`, limited to `placedFolder`, with the search box shrunk slightly so blocks that share a face still count as fine. This means placed blocks need `CanQuery` left on, which is the default.