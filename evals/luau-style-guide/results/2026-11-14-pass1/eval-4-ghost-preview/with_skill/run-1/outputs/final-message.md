I wrote the ghost preview class at `src/StarterPlayer/StarterPlayerScripts/GhostPreview.luau`. It passes the project's formatter, linter and type checker with no errors or warnings. I haven't tried it in Studio, so nothing has been tested in a running game yet.

**How the controller uses it:**

```lua
const GhostPreview = require("./GhostPreview")

local ghost = GhostPreview.new("Brick") -- defaults: 0.6 transparency, 500-stud ray
local ghost = GhostPreview.new("Window", { Transparency = 0.3, RaycastDistance = 200 })

ghost:SetBlockType("Wood")

local isPlaceable, cell = ghost:GetPlacement()
if isPlaceable and cell then
	-- send the placement request for cell
end

ghost:Destroy()
```

**What it does:**
- **Every frame:** it casts a ray from the mouse that ignores the character and the ghost. When the character respawns, the ignore list picks up the new one. It then moves half a block off the hit surface and calls `PlacementRules.snap`. That way it lands in the cell in front of the face you point at, not inside the block you hit.
- **Sky:** the ghost hides when the ray hits nothing, and `GetPlacement()` returns `false, nil`.
- **Color:** it uses the block type's color and material from `BlockTypes`, and turns red where `PlacementRules.check` fails. It looks up `Workspace.PlacedBlocks` each frame. If that folder doesn't exist yet (the server script is still empty), the ghost shows red and reports the spot as not placeable.
- **Return values:** `GetPlacement()` returns two values: whether the block can go there, and the cell center. When the ghost is red, the center is still returned but the first value is `false`.
- **Leaving build mode:** `Destroy()` disconnects the per-frame update and deletes the part. Calling it twice is safe, so build mode can open and close any number of times. `new()` raises an error if the transparency isn't between 0 and 1 or the ray length isn't a positive, finite number.

**Choices you might want to change:**
- The ghost always uses the transparency the caller passed, even for Window. Window is already 0.5 transparent as a placed block, so if you ask for 0.3, the ghost will look more solid than the real window.
- The game doesn't use the Module Loader setup with a `<Name>System` folder, so I put the file at the path you asked for. Your next controller can require it as a sibling, as in the example above.

Nothing is committed yet.