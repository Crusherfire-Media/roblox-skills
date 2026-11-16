I've added a client-side stock module and hooked it into the hotbar and BlockPlacer. Type-checking, linting and the format check all pass with no errors. I haven't run the game or opened the hotbar in Studio, because Studio isn't reachable from here.

**New module: `BlockStock.luau`**
- It holds the player's counts in a Charm signal, as a table of block type name to count. The setter is private, and the only writer is the `StockChanged` listener, which copies the table on each update rather than changing it in place.
- Other code reads it through `BlockStock.getStock`, or through `BlockStock:GetCount(name)`, which returns 0 for a block type the server hasn't reported yet.
- `BlockStock:StartAsync()` waits for the remote and connects to it. Updates the server sends before the client connects are held by Roblox and arrive when it does, so the per-type messages sent on join aren't lost.

**Other changes**
- **`BlockPlacer.luau`**: `placeAt` now returns early when the selected block type's count is 0 or less, so it never fires `PlaceBlock` for it.
- **`BlockPicker.luau`**:
  - Takes a new `Stock` prop.
  - Each tile shows its count in the bottom-right corner. At 0 the tile turns a dark gray and its number goes gray.
  - A "<n> left" label sits just above the hotbar for the selected block type.
  - The tiles now sit inside their own inner frame, because otherwise the hotbar's horizontal layout would also have lined up the new label with the tiles.
- **`Main.client.luau`**: bridges `BlockStock.getStock` into Vide with `useSignalState`, passes it to the hotbar, and starts `BlockStock` in its own thread.
- **New story files**: `src/ServerScriptService/Stories/` now has a storybook and `BlockPicker.story`. The story lets you change the selected block type and each type's count.

**Things to know**
- **Empty tiles can still be selected.** Selecting one shows "0 left", which tells the player why nothing gets placed. If you'd rather empty tiles not respond to clicks at all, that's a small change.
- **Everything starts at 0 until the server's first update arrives.** Tiles look gray for a moment on join, and clicks in that window place nothing.
- **The hotbar's look and the story are untested.** The story hasn't been through the story check or a layout measurement. In UI Labs, open "Game UI → BlockPicker" and check:
  - the count is readable on light tiles, especially Window;
  - the gray of an empty tile is easy to tell apart from Dirt;
  - the "<n> left" label clears the hotbar's top edge.