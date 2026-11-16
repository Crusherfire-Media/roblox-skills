The client now tracks each block type's stock, shows it on the hotbar, and stops sending place requests for block types the player has none of. StyLua and selene pass with 0 errors and 0 warnings. I haven't run it in Studio, and I couldn't get a usable type-check: `luau-lsp analyze` has no Roblox definitions file here, so it only printed "Unknown type 'Instance'" noise from the packages. An earlier combined format/lint/type-check command was blocked by the permission system, so I ran those steps separately.

**What changed**
- **New `BlockStock.luau`**: holds the stock in a Charm signal, a table of block type name to count. It has a private setter and public `getStock` and `getCount(name)`. A block type the server hasn't reported yet counts as 0. `start()` listens to `StockChanged` and swaps in a new table on each change. `Main.client.luau` calls it after `mount`, before `BlockPlacer.start()`.
- **`BlockPlacer.luau`**: `placeAt` returns early when the selected block type's count is 0, so nothing is sent to the server. The server's own check is unchanged.
- **`BlockPicker.luau`** (takes a new `Stock` prop, connected to Charm with `useSignalState` in `Main.client.luau`):
  - Each tile shows its count in the bottom-right corner, with a text outline so it stays readable on both the dark wood tile and the pale window tile.
  - At 0 the tile turns gray and its count dims. I left the tile selectable: picking it just shows "0 left".
  - A rounded label just above the hotbar shows "<n> left" for the selected block type.
  - To fit that label, the root frame is now transparent and holds a `Panel` frame (the old background, padding and tile row) plus the label. Without that, the hotbar's tile layout would have pulled the label into the row.

**New UI Labs story.** The project had the UI Labs package but no stories, so I added `src/ServerScriptService/Stories/GameUI.storybook.luau` and `BlockPicker.story.luau`. The story has a control for the selected block and a stock slider per block type, from 0 to 999. Every other type starts at 0, so you see full and empty tiles side by side.

**To check in Studio**
1. Open the BlockPicker story and set a stock to 0, a single digit, and 999. Check that the count fits in the corner, the gray tile still looks selectable, and the label sits centered above the hotbar.
2. In a playtest, each tile should read 20 after you join. Place blocks until one type hits 0: its tile should go gray, and clicking with it selected should send nothing.

**Decision for you:** clicks quickly after the last block can still send a request or two before the server's update arrives, and the server rejects them. If you'd rather the client lower its count right away, that's a small change, but the count could be briefly wrong if the server refuses a placement for another reason (out of reach, cell taken).