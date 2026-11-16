I added the module at `src/ReplicatedStorage/Shared/PlacementRules.luau`. The type checker (luau-lsp), the linter (selene) and the formatter check (stylua) all pass on it, and no other file changed. I haven't run it in Studio yet, so none of the rules have been tested in play.

**How to use it**

```lua
local result = PlacementRules.validate(blockType, position, {
	Baseplate = workspace.Baseplate,
	BlocksFolder = blocksFolder,
	RootPart = character and character:FindFirstChild("HumanoidRootPart"),
})
if result.Ok then
	-- result.BlockType, result.Position (the snapped block center)
else
	warn(result.Reason)
end
```

`blockType` and `position` can be anything a client sends. The module checks them and never errors. When a request fails, `Reason` is one of these: `InvalidBlockType`, `InvalidPosition`, `BelowBaseplate`, `TooHigh`, `NoCharacter`, `TooFar` or `Occupied`. It also exposes `PlacementRules.snapToGrid(position, baseplate)`, `PlacementRules.BlockTypes` for the picker, and `PlacementRules.BlockSize`.

**How the rules work**

- **Block names:** the five types are `"Brick"`, `"Dirt"`, `"Grass"`, `"Window"` and `"Wood"`. The capitalized names follow the style guide's enum rule, so the remote and UI should send these exact strings.
- **Grid:** 4-stud cells measured from the top corner of the Baseplate, so blocks line up with its edges and the bottom layer sits on it. `validate` snaps the position before checking anything, so the server never trusts the client's own snapping.
- **Height:** the bottom of a block can't go below the top of the Baseplate, and its top can't go above 200 studs.
- **Reach:** measured from the HumanoidRootPart to the snapped block center, up to 24 studs. If there's no root part (no character, or a dead one), the request fails with `NoCharacter`.
- **Overlap:** a spatial query limited to the folder you pass in, using a box 0.1 studs smaller than a block, so blocks touching face to face are allowed. This means placed blocks must stay queryable (`CanQuery` on, which is the default). It also means the ghost preview part must not be inside that folder, or it would block its own spot.
- **Bad input:** non-strings, non-Vector3 values, and NaN or infinite numbers are all rejected. Very large finite numbers still snap and then fail the height or reach check.

**Things to know when you wire it up**

- **Clicking on a block face:** a point exactly on a cell boundary snaps to the cell above it (or the one on the positive side, for X and Z). So the client should pass `hit.Position + hit.Normal * (PlacementRules.BlockSize / 2)`, not the raw hit point. Otherwise clicking the side or bottom of a block, or a hit slightly below Y = 0, picks the wrong cell or fails with `BelowBaseplate`. The doc comment on `snapToGrid` says this too.
- **Baseplate edges:** nothing stops a block from being placed past the edge of the Baseplate if the player is standing near it, because you didn't list that as a rule. It's an easy check to add if you want it.
- **Rotated Baseplate:** the grid math assumes the Baseplate isn't rotated.