I've wired the client up to the stock the server sends. It isn't tested: shell commands were blocked in this session, so I couldn't run selene, StyLua or luau-lsp, or play it in Studio.

**New `BlockStock.luau`**
- Keeps the stock in a Charm signal holding each block type's count by name, like the selected block type in BlockPlacer.
- `BlockStock.start()` waits for `StockChanged` and updates the counts as messages arrive, ignoring names that aren't real block types. Messages the server sends before the client connects are queued by Roblox, so the counts it sends on join aren't lost.
- `BlockStock.getCount(name)` returns 0 for a block type the server hasn't reported yet.

**`BlockPlacer.luau`**
- `placeAt` now returns early if the selected block type's count is 0, so it never asks the server for one.
- A player can still select an empty block type; it just won't place.

**`BlockPicker.luau`**
- Each tile shows its count in the bottom-right corner, with a dark outline so it's readable on light tiles like Window.
- At 0, the tile turns a dim gray and its number fades.
- A "`<n> left`" label for the selected block type sits 6px above the hotbar and turns gray at 0.
- The panel's layout would also have arranged the new label as if it were a tile. To prevent that, I moved the tiles into an inner `Tiles` frame. The panel itself (`BlockPicker`) looks and sits exactly as before.
- It takes a new prop, `Stock`.

**`Main.client.luau`**
- Bridges the stock into Vide with `VideCharm.useSignalState(BlockStock.getStock)` and passes it to the hotbar.
- Calls `BlockStock.start()` before `BlockPlacer.start()`.

Until the server's first counts arrive, every tile shows 0 and is grayed out. That should be very brief after joining, and nothing can be placed during it anyway.

Nothing is committed.