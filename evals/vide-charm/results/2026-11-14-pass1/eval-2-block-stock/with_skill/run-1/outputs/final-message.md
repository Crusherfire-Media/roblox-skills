The client now keeps each block type's stock in Charm and uses it in the hotbar and in BlockPlacer. Type checking (luau-lsp), selene and stylua all pass. Nothing has run in Studio yet: no playtest, and no UI Labs check of the new story.

**New `BlockStock.luau`** (in StarterPlayerScripts)
- Keeps a Charm signal mapping block type name to count, updated from `StockChanged` by copying the table rather than editing it. `BlockStock.getStock` is the getter for UI; only this module writes the signal.
- `BlockStock:GetCount(name)` returns 0 for a block type the server hasn't reported yet.
- `BlockStock:StartAsync()` waits for the remote and connects to it. Counts the server sends before it connects (the join burst) are queued by the remote, so none are lost.

**`BlockPlacer.luau`**: `placeAt` now returns before firing `PlaceBlock` if `BlockStock:GetCount(selected) <= 0`. Before the first counts arrive, clicks place nothing, which matches what the server would allow anyway.

**`BlockPicker.luau`**
- Takes a new `Stock` prop. Each tile shows its count in the bottom-right corner, and at 0 the tile and its number turn gray. Empty tiles can still be selected.
- A "`<n> left`" label for the selected block type sits just above the hotbar panel. The tiles moved into an inner `Tiles` frame so the row layout doesn't move that label.
- Until the server has reported a block type, its tile shows no number and isn't grayed, so tiles don't flash gray when a player joins.

**`Main.client.luau`**: bridges the stock into Vide with `VideCharm.useSignalState(BlockStock.getStock)`, passes it to the hotbar, and calls `BlockStock:StartAsync()` before `BlockPlacer.start()`.

**Story (added beyond your list):** the project had no UI Labs stories, so I added `src/ServerScriptService/Stories/` with `Hotbar.storybook.luau` and `BlockPicker.story.luau`. The story has a count slider for each block type, plus an `IsReported` toggle that shows the hotbar before any counts arrive. Clicking a tile in the story selects it.

**Style:** the new files follow the roblox-dev style guide (`--!strict`, `const`, string requires, `Module:` methods). In the existing files I kept their current style and changed only the lines the feature needed, so the code base now mixes the two styles.

**To check on screen** (open the `BlockPicker` story or playtest):
- Each count is readable on every tile, including the light Window tile.
- An empty tile is clearly gray next to the others.
- The "n left" label sits just above the panel without crowding it.
- In a playtest, placing blocks counts down, and at 0 clicks stop placing.