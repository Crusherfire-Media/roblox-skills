I wrote the ghost preview class in `src/StarterPlayer/StarterPlayerScripts/GhostPreview.luau`. StyLua and selene both pass with no errors or warnings. I haven't type-checked it with luau-lsp (that command was blocked by a permission prompt nobody could answer here), and it hasn't been run in Studio, so the frame-by-frame behaviour is untested.

**How the controller uses it:**
```lua
local ghost = GhostPreview.new("Brick")                                  -- defaults
local ghost = GhostPreview.new("Brick", { Transparency = 0.3, RaycastDistance = 200 })

ghost:setBlockType("Wood")                         -- when they pick another block
local placeable, center, reason = ghost:getPlacement()   -- on click
if placeable then remote:FireServer(blockType, center) end
ghost:destroy()                                    -- when they leave build mode
```

- **Following the mouse:** every frame it casts a ray from the mouse that ignores the ghost and the player's current character. It picks up the new character after a respawn. It moves half a block out from the surface the ray hits, then calls `PlacementRules.snap`, so the ghost lands in the cell beside the surface instead of inside it.
- **Hiding:** when the ray hits nothing, the ghost goes fully transparent and `getPlacement()` returns `false, nil`. It starts hidden, so it never shows up at the world origin before the first frame.
- **Colour:** it uses the block type's material and colour from `BlockTypes`, and turns red where `PlacementRules.check` says no. The check runs against `Workspace.PlacedBlocks`, and the reason (`"Occupied"`, `"OutOfReach"`, etc.) is passed back through `getPlacement()`.
- **Settings:** the defaults are a transparency of 0.5 and a raycast distance of 500 studs. You can override each one per ghost, or change the defaults for every ghost through `GhostPreview.DefaultTransparency` and `DefaultRaycastDistance`.
- **Teardown:** `destroy()` disconnects the per-frame update and removes the part. It's safe to call twice, and entering and leaving build mode repeatedly leaves nothing behind.

**Choices you might want changed:**
- **Ghost transparency overrides the block's own:** Window blocks look like every other ghost instead of appearing more see-through.
- **Red replaces the block colour:** a blocked spot shows a flat red rather than a red-tinted version of the block colour.
- **Missing folder shows red:** if `PlacedBlocks` hasn't reached the client yet, the spot shows as not placeable with the reason `"NoBlocksFolder"`, so it can't be clicked until the folder exists.
- **Placement is one frame old:** `getPlacement()` returns the result from the most recent frame rather than doing a new raycast. That's fine for a click handler, and the server re-checks every placement anyway.