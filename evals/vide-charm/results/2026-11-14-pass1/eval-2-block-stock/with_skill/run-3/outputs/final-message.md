The client now keeps the block stock in Charm and shows it on the hotbar, and BlockPlacer no longer asks the server to place a block type the player has none of. The type check, selene and stylua all pass, but I haven't playtested it or opened the story in Studio, because I can't reach Studio from here.

**What changed**
- **`BlockStock.luau` (new):** holds the counts in a Charm signal, like the selected block type in BlockPlacer. Other code reads them through `BlockStock.getStock` or `BlockStock:GetCount(name)`, and only the `StockChanged` remote changes them. A block type the server hasn't reported yet counts as 0.
- **`BlockPicker.luau`:** takes a new `Stock` prop.
  - Each tile shows its count in the bottom-right corner.
  - At 0 the tile turns gray and its number dims. It can still be selected, and then the label reads "0 left".
  - "<n> left" for the selected block type sits just above the hotbar. To fit it there, the panel now sits inside a see-through `BlockPicker` frame and is renamed `Tiles`.
- **`BlockPlacer.luau`:** `placeAt` stops before firing `PlaceBlock` when the selected block type's count is 0. The server still does its own check.
- **`Main.client.luau`:** passes the stock into the hotbar and starts listening to `StockChanged` before `BlockPlacer.start()`. The counts the server sends on join wait in the remote's queue until the client connects, so none are lost.
- **UI Labs story (new):** `src/ServerScriptService/Stories/BlockPicker.story.luau` and a `GameUI.storybook.luau`. There's a slider for each block type's count, and clicking a tile selects it.

**Things to know**
- **Gray tiles at join:** for a moment after joining, before the counts arrive, every tile shows 0 and is gray.
- **Mixed styles:** the new files use the style guide (`--!strict`, string requires, `const`). In the three existing files I kept their current style.
- **Strict mode:** Vide's strict mode isn't turned on anywhere. Adding `Vide.strict = RunService:IsStudio()` near the top of `Main.client.luau` would catch impure bindings during development.
- I haven't committed anything.

**To check in Studio**
- In a playtest, tiles should start at 20, and placing a block should lower its tile's count and the "N left" label.
- At 0, clicking in the world should send nothing to the server.
- Open the `BlockPicker` story in UI Labs and drag a slider to 0 to see that tile gray out.
- Make sure the white numbers are readable on the light-blue Window tile.