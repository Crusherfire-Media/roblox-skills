I wrote the ghost preview class in `src/StarterPlayer/StarterPlayerScripts/GhostPreview.luau`. The type checker, linter and formatter all pass with no errors. I haven't tested it in Studio, so I haven't seen it follow the mouse yet.

**How the controller uses it**
```lua
local GhostPreview = require(script.Parent.GhostPreview)

local ghost = GhostPreview.new("Brick")   -- or GhostPreview.new("Brick", { Transparency = 0.4, RaycastDistance = 200 })
ghost:setBlockType("Wood")                -- when the player picks another block

-- on click:
local canPlace, position, reason = ghost:getPlacement()
if canPlace then
	-- send the placement request with position (the center of the grid cell)
end

ghost:destroy()                           -- when the player leaves build mode
```

**What it does**
- **Options:** both are optional. Transparency defaults to 0.6 and the raycast length to 500 studs.
- **Placement:** every frame it casts a ray from the mouse, ignoring your character and the ghost. It steps half a block out from the surface the ray hits and puts the ghost in that grid cell with `PlacementRules.snap`. When the ray hits nothing (the sky), the ghost is hidden.
- **Color:** it uses the block's color and material from `BlockTypes`, and turns red wherever `PlacementRules.check` says no, using the `PlacedBlocks` folder. It also stays red until the server has created that folder.
- **`getPlacement()`:** returns whether the block can go there, the cell's center (nil when the ghost is hidden), and the reason when it can't, such as `"Occupied"`, `"OutOfReach"` or `"NoBlocksFolder"`. The reason is there in case you want to show feedback.
- **Entering and leaving build mode repeatedly:** each ghost gets its own uniquely named per-frame update. `destroy()` stops that update and removes the part. Calling `destroy()` twice does nothing, and calling `setBlockType` after `destroy()` raises an error.

**Choices I made that you may want to change**
- The ghost is 0.05 studs smaller than a block so its faces don't flicker against the blocks it touches.
- It updates right after the camera each frame, so it doesn't trail the view by a frame.
- `getPlacement()` reports the result from the last frame rather than recomputing on click. It can be at most one frame old, and the server checks the placement again anyway.

Running the checks also rewrote `sourcemap.json`.