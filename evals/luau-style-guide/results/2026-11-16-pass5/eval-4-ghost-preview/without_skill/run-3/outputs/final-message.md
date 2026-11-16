I've written the ghost preview class in `src/StarterPlayer/StarterPlayerScripts/GhostPreview.luau`. The type checker, selene and stylua all pass on it. I haven't run it in Studio, so it hasn't been tried in a live game yet.

**What the controller calls:**
```lua
local ghost = GhostPreview.new("Brick")              -- defaults: 0.5 transparency, 500-stud ray
local ghost = GhostPreview.new("Brick", { transparency = 0.3, maxDistance = 200 })
ghost:setBlockType("Wood")                          -- when they pick another block
local center, canPlace = ghost:getPlacement()       -- on click; center is nil when pointing at the sky
if center and canPlace then --[[ send placement request with center ]] end
ghost:destroy()                                     -- when they leave build mode; safe to call twice
```

**How it works:**
- **Raycast:** every frame it casts a ray from the mouse, ignoring the player's character and the ghost itself. It runs just after the camera moves, so the ghost doesn't trail a frame behind. The character is looked up fresh each frame, so it still works after a respawn.
- **Placement:** it steps half a block out from the hit point along the surface, then calls `PlacementRules.snap`. That puts the ghost in the empty cell next to whichever face you're pointing at.
- **Hiding:** when the ray hits nothing, the ghost is removed from the world and `getPlacement()` returns `nil, false`.
- **Color:** it uses the block's color and material from `BlockTypes`, and turns red wherever `PlacementRules.check` says no.
- **Many sessions:** each ghost hooks into the frame update under its own name, and `destroy()` unhooks it and deletes the part. Entering and leaving build mode many times won't leave old ghosts or frame updates behind.
- **Size:** the ghost is 0.05 studs smaller than a real block so it doesn't flicker against neighbouring blocks.

**Decisions for you:**
- **Missing `PlacedBlocks` folder:** if the folder isn't in Workspace yet, the spot counts as not placeable and the ghost shows red. I assumed the server can't accept blocks before it creates the folder. If you'd rather treat a missing folder as "nothing placed yet", it's a one-line change in `_update`.
- **Last frame's answer:** `getPlacement()` returns what was worked out on the last frame, which is what the player saw when they clicked. The server should still run `PlacementRules.check` itself before accepting a block.