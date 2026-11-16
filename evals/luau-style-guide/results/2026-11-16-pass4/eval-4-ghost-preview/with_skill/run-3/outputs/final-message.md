I've written the ghost preview class in `src/StarterPlayer/StarterPlayerScripts/GhostPreview.luau`. It passes the luau-lsp strict type check and StyLua with no errors. I haven't run it in a playtest yet.

**How the controller uses it**
```lua
local preview = GhostPreview.new("Brick")                     -- defaults
local preview = GhostPreview.new("Window", { Transparency = 0.3, RaycastDistance = 200 })

preview:SetBlockType("Wood")        -- player picks another block
local center = preview:GetPlacement() -- Vector3 if placeable, nil otherwise
if center then
	-- send the placement request with center
end
preview:Destroy()                   -- leaving build mode
```

**How it works**
- **Every frame:** it casts a ray from the mouse after the camera has moved for that frame, so the ghost lines up with what's on screen. The ray ignores the player's character and the ghost. It updates which character to ignore when the player respawns.
- **Placement:** from the point the ray hits, it moves half a block out from the surface and runs `PlacementRules.snap`. That lands in the empty cell against the face you're pointing at.
- **Sky:** when the ray hits nothing, the ghost is hidden and `GetPlacement()` returns nil.
- **Color:** it takes the color and material from `BlockTypes.Styles`. Where `PlacementRules.check` says no, the color is blended strongly toward red rather than turned solid red, so you can still tell which block it is. It only changes the color when the placeable/blocked state or the block type changes.
- **`PlacedBlocks` missing:** if that folder hasn't reached the client yet, the spot counts as not placeable. The server would refuse those placements anyway.
- **Repeated use:** `Destroy()` removes the per-frame update and the part, and calling it twice is safe. Each preview registers its frame update under its own name, so entering and leaving build mode many times can't leave two previews fighting over it.
- **Option checks:** it errors if `Transparency` is outside 0 to 1 or `RaycastDistance` isn't above 0.

**Choices you may want to change**
- **Glass ghost:** for Window blocks the ghost uses the Glass material, which looks different from other materials when see-through.
- **Placement check is client-side:** `GetPlacement()` uses this client's check, which includes the 24-stud reach limit. The server should still run `PlacementRules.check` itself before placing.
- **Style:** I followed your existing modules: `local` bindings, and the module's table named `GhostPreview` after the file.

The type check first failed because the local sourcemap didn't include the new file. I regenerated `sourcemap.json` with `rojo sourcemap`, and git doesn't track that file, so your working tree only shows the new module.