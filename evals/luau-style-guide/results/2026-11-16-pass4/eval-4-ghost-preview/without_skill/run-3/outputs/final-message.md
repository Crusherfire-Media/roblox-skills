I wrote the ghost preview class in `src/StarterPlayer/StarterPlayerScripts/GhostPreview.luau`. All the project's checks pass with no errors (luau-lsp analyze, selene and stylua --check). I haven't run it in Studio, so nobody has seen it follow the mouse yet.

**How the controller uses it**

```lua
local GhostPreview = require(script.Parent.GhostPreview)

local ghost = GhostPreview.new("Brick")              -- defaults: transparency 0.5, raycast 500 studs
-- or: GhostPreview.new("Brick", { Transparency = 0.3, MaxDistance = 200 })

ghost:setBlockType("Wood")                          -- when the player picks another block

local canPlace, position, reason = ghost:getPlacement()  -- on click
if canPlace then
	-- send placement request with position
end

ghost:destroy()                                     -- when leaving build mode; safe to call twice
```

**What it does**

- **Every frame:** it casts a ray from the mouse into the world, ignoring the player's character and the ghost itself. It checks the character every frame, so it still works after the player respawns. The ray is moved half a block off the surface it hits before `PlacementRules.snap`, so the ghost lands in the grid cell next to that surface.
- **Pointing at the sky:** the ghost is hidden, and `getPlacement` returns `false, nil, "NoTarget"`.
- **Color:** it uses the color and material from `BlockTypes`. Where `PlacementRules.check` says no, it turns red, and `getPlacement` passes on the reason from `check` (`"OutOfReach"`, `"Occupied"`, etc.).
- **Entering and leaving build mode often:** each ghost updates itself on its own uniquely named render step, and `destroy` removes that step and deletes the part. Nothing is left behind after many enter/leave cycles.
- **Assumptions:**
  - **The `PlacedBlocks` folder:** if it doesn't exist yet, the ghost treats it as "no blocks placed" instead of waiting for it. That way the preview isn't stuck red until the server creates the folder.
  - **Transparency:** your chosen transparency applies to every block type, including Window, which ignores its own 0.5 from `BlockTypes` while previewed.
  - **Ghost size:** the ghost is 0.05 studs smaller than a real block so its faces don't flicker against neighbouring blocks.
  - **Bad arguments:** an unknown block type, or out-of-range options, raise an error immediately.

`getPlacement` returns what the ghost showed on the last frame, so a click acts on what the player saw. The server should still run `PlacementRules.check` itself, since it has the final say.

To run the checks I regenerated `sourcemap.json`; git shows no changes to it. The new file is not committed.