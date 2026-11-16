I've hooked the client up to the stock. I haven't run or checked any of it: the session blocked my shell commands, so I couldn't list the project or run a linter or type checker. Please test it in Studio.

**New: `BlockStock.luau`**
- Keeps the stock in a Charm signal: a table of block type name → count. Each update replaces the table rather than changing it in place, so Charm and frozen mode both work.
- `BlockStock.getStock` returns the whole table and `BlockStock.getCount(name)` returns one count. Both can be read inside Charm effects and computed values.
- `BlockStock.start()` waits for the `StockChanged` remote and listens to it. It ignores names that aren't real block types and values that aren't numbers. Roblox holds remote events until a listener connects, so the counts the server sends on join aren't lost.
- A count the server hasn't sent yet reads as 0. So for a moment after joining, the tiles may look grayed out.

**`BlockPlacer.luau`**
- `placeAt` now returns early when the selected block type's count is 0 or below, so it never fires `PlaceBlock` for it.

**`BlockPicker.luau`**
- Each tile shows its count in the bottom-right corner. At 0 the tile turns gray and the number dims.
- A "`<n> left`" label for the selected block type sits just above the hotbar, and also dims at 0.
- **Structure change:** the panel's `UIListLayout` would have pulled the label into the row of tiles. So the root `BlockPicker` frame is now a transparent container (same name, position and size). It holds a `Panel` frame with the tiles and the `Remaining` label. Anything that looked up tiles directly under `BlockPicker` now needs to look under `BlockPicker.Panel`.
- It takes a new `Stock` prop.

**`Main.client.luau`**
- Passes the stock into Vide with `VideCharm.useSignalState(BlockStock.getStock)` as the `Stock` prop, and calls `BlockStock.start()` before `BlockPlacer.start()`.

The client doesn't subtract a block when it places one; it waits for the server's `StockChanged`. If someone clicks very fast on their last block, an extra request can still reach the server, which turns it down. I can add a client-side subtraction if you want that closed off.