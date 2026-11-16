I've written the ghost preview class in `src/StarterPlayer/StarterPlayerScripts/GhostPreview.luau`. It passes StyLua and Selene, but I haven't type-checked it or run it in Studio. Running the type checker needed a permission prompt, which this session can't show, so it was denied.

**How the controller uses it:**
```lua
local ghost = GhostPreview.new("Brick")              -- defaults: transparency 0.5, raycast 500 studs
local ghost = GhostPreview.new("Brick", { Transparency = 0.3, RaycastDistance = 200 })

ghost:setBlockType("Wood")                           -- when the player picks another block
local center, canPlace, reason = ghost:getTarget()   -- on click
if center and canPlace then --[[ send placement request with center ]] end
ghost:destroy()                                      -- when they leave build mode
```

**What it does:**
- **Every frame:** it casts a ray from the mouse that ignores the current character and the ghost. It picks up the new character after a respawn. It then steps half a block off the surface along the hit face and snaps that point with `PlacementRules.snap`, so the ghost lands in the empty cell next to whatever the mouse is over.
- **Sky:** when the ray hits nothing, the ghost is hidden and `getTarget()` returns `nil, false`.
- **Color:** it uses the block's color and material from `BlockTypes`, and turns red wherever `PlacementRules.check` fails. `getTarget()` also passes back the reason the check gives (e.g. `"OutOfReach"`, `"Occupied"`).
- **PlacedBlocks:** the folder is looked up by name every frame. Until the server creates it, the ghost checks against an empty folder, so nothing counts as occupied rather than erroring.
- **Enter/leave many times:** `destroy()` disconnects the per-frame update and removes the part, and calling it twice is safe. Make a new ghost each time the player enters build mode; a destroyed one can't be reused.

**Choices you might want changed:**
- If a block's own transparency is higher than the ghost's, the higher one wins, so Window ghosts stay at least 0.5 transparent.
- The ghost's position is updated once per frame, on `RunService.PreRender`, using the mouse position. It doesn't handle touch or gamepad aiming.