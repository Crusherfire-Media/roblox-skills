I've written the shared module at `src/ReplicatedStorage/Shared/PlacementRules.luau`. Nothing has been run yet: the type check, selene and stylua checks from the README were blocked because this session can't approve shell commands. I checked the code by hand, but please run those four commands before you build on it.

**How to use it**

```lua
local center, reason = PlacementRules.validate(player, blockType, position, placedFolder)
if not center then
	warn(`{player.Name} placement rejected: {reason}`)
	return
end
-- place a block at `center`
```

- **`validate`** snaps the position itself and returns the center of the snapped grid square on success. Otherwise it returns `nil` and a reason: `"invalid block type"`, `"invalid position"`, `"below ground"`, `"too high"`, `"no character"`, `"out of reach"` or `"overlaps block"`.
- **`snapToGrid(position)`** is the snapping used by both the preview and the server. Snapping an already-snapped position gives the same result, so the client can send either the raw point or the snapped one.
- **Other exports:** `isValidBlockType`, `BLOCK_TYPES`, `BLOCK_SIZE`, `GROUND_Y`, `MAX_HEIGHT` and `MAX_REACH`.

**Choices I made where your rules left room**

- **Block type names** are lowercase strings exactly as you listed them: `"brick"`, `"dirt"`, `"grass"`, `"window"`, `"wood"`.
- **Ground level** is fixed at `GROUND_Y = 0`, matching the Baseplate top in `default.project.json`. I didn't read it from `workspace.Baseplate` so the module doesn't depend on that part being loaded on the client. If you move the Baseplate, update this number.
- **Height:** a block's bottom must be at or above ground, and its top at most 200 studs up. That gives exactly 50 layers.
- **Reach** is measured from the HumanoidRootPart to the block's center. `validate` takes the `Player` and looks up the character each call, so a missing or respawning character gets `"no character"` instead of an error.
- **Overlap** is a box test against every part inside the folder you pass in, including parts nested in models. A small allowance means blocks sharing a face don't count as overlapping. It assumes placed blocks are never rotated.

**Bad input from the client**

- A wrong type, NaN or infinity is rejected before any maths happens.
- Huge but finite numbers fail the reach check.
- Every limit check is written so that a NaN value fails it rather than slipping through. This also covers a NaN HumanoidRootPart position on the server.

**One thing to handle when you build the preview:** don't snap the raw mouse hit point directly. A click on a block's side lands exactly on the edge between two grid squares and can snap into the block you clicked. Snap `hit.Position + hit.Normal * (BLOCK_SIZE / 2)` instead (there's a comment on `snapToGrid` saying so).

**Performance:** the overlap check goes through the whole folder on every call. That's fine for now. If the build count gets large, a lookup table keyed by grid square would be quicker.