I've written the `GhostPreview` class in `src/StarterPlayer/StarterPlayerScripts/GhostPreview.luau`. I haven't run it in Studio, and I couldn't run any checks either: my one shell command was denied because this session can't approve permission prompts, so neither the type checker nor the linters have seen the file.

**How the controller uses it**
```lua
local GhostPreview = require(script.Parent.GhostPreview)

local ghost = GhostPreview.new("Brick")                  -- defaults: 0.5 transparency, 500-stud ray
-- or GhostPreview.new("Brick", { Transparency = 0.3, RaycastDistance = 200 })

ghost:setBlockType("Wood")                               -- when the player picks another block
local placeable, position = ghost:getPlacement()         -- on click
if placeable then
    -- send the placement request with position
end
ghost:destroy()                                          -- when leaving build mode
```

**What it does each frame**
- **Placement:** it casts a ray from the mouse that ignores your character and the ghost itself. It moves half a block out from the surface the ray hits, then snaps that point to the grid with `PlacementRules.snap`, so the ghost sits in the empty cell next to that surface rather than inside it.
- **Hiding:** when the ray hits nothing (sky, or anything past the ray length), the ghost is hidden and `getPlacement()` returns `false, nil`.
- **Color:** it takes the color and material from `BlockTypes.Styles`. Where `PlacementRules.check` fails against `Workspace.PlacedBlocks`, it turns red. Every block uses the same transparency setting, so the Window block's own 0.5 transparency is ignored.
- **When the spot is blocked:** `getPlacement()` still returns the position along with `false`, in case you want to show feedback there. Only send the request when the first value is `true`.

**Behaviour you might trip over**
- **Missing folder:** if `PlacedBlocks` doesn't exist yet, every spot shows as not placeable. That's because `PlacementRules.check` needs the folder, and the server couldn't accept a placement then either.
- **Respawning:** it re-reads your character every frame, so the ray keeps ignoring the right character after a respawn.
- **Entering and leaving build mode many times:** `destroy()` disconnects the per-frame update and deletes the part, and it's safe to call twice. Make a new object with `GhostPreview.new` each time you enter build mode; a destroyed one can't be reused.
- **Other raycasts:** the ghost has `CanQuery` turned off, so neither your own raycasts nor the overlap check in `PlacementRules.check` will hit it. It's parented to the camera, so only the local player sees it.