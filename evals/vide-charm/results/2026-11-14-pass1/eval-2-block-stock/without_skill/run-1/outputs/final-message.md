The client now keeps the block stock in Charm and uses it in the hotbar and in `BlockPlacer`. StyLua and selene pass on the client scripts. I couldn't run a useful type-check because the project has no Roblox definitions file, so `luau-lsp` flags every Roblox type as unknown. I also haven't run it in Studio, so the hotbar layout and the remote wiring are untested.

**New module, `BlockStock.luau`**
- It holds a Charm signal with each block type's count (`getStock()`), plus a helper `getCount(name)`. When a count changes, the table is replaced with a new one rather than edited in place. That matters because Charm freezes tables in Studio.
- `start()` waits for the `StockChanged` remote and listens to it. It ignores bad data and names that aren't real block types.
- Before the server's first update arrives, a block type has no entry at all rather than a 0, so "not known yet" and "none left" stay separate.

**`BlockPicker.luau` (hotbar)**
- Each tile shows its count in the bottom-right corner. At 0, the tile's color fades toward gray and the number dims. A grayed tile can still be selected; it just won't place anything.
- A "<n> left" label for the selected block type sits just above the hotbar.
- New prop: `Stock: () -> { [string]: number }`.
- **Structure change:** the tile row lays out all of its children in a line, so the label couldn't go inside it. The root `BlockPicker` frame is now transparent and holds two children: the label (`SelectedStock`) and the original panel, now called `Tiles`. Anything that looks up tiles by path now needs `BlockPicker.Tiles.<Name>`.
- Counts and the label stay blank until the server's first update arrives.

**`BlockPlacer.luau`**
- `placeAt` returns early, before the raycast, when the selected type's count is 0. A type with no count yet also counts as 0.

**`Main.client.luau`**
- Bridges the stock into Vide with `VideCharm.useSignalState`, the same way the selected block type already was, and passes it to `BlockPicker`.
- Starts `BlockStock` in its own thread, so neither start function waits for the other's remote.

The client doesn't lower the count itself when placing; it waits for the server's `StockChanged`. The server also limits placements to one per 0.1 s, so with fast clicking on your last block the client might send one extra request before the update arrives. The server still rejects it.