A "<n> blocks left" label now sits just above the hotbar and updates as the player places blocks. The count comes from the server through Charm and CharmSync, with no hand-made remote for the value. StyLua, selene and luau-lsp report no problems in `src`, but I haven't run it in Studio, so it hasn't been tested in a live game.

**How the count gets to the client**
- **Server state:** `src/ServerScriptService/PlayerState.luau` keeps each player's synced values as Charm atoms. `blocksLeft` starts at 50, and that limit constant moved here from BlockPlacement.
- **Placement check:** `BlockPlacement.server.luau` no longer keeps its own `placedCounts` table. It refuses to place when `blocksLeft()` is 0 or less, and subtracts 1 after each block. That atom is now the only count.
- **Sending it:** `PlayerSync.server.luau` makes one `PlayerSync` RemoteEvent. When a client says it's ready, the script subscribes that player to their own atoms; CharmSync then sends the full state once and only changes after that. It also unsubscribes players when they leave.
- **Keys:** `Shared/PlayerSync.luau` names each value per player (`blocksLeft:<UserId>`), because CharmSync needs a different key for each player's data.
- **Receiving it:** `StarterPlayerScripts/PlayerState.luau` holds the client's copies. They stay `nil` until the first sync arrives. `PlayerSync.client.luau` registers them, listens on the remote, then tells the server it's ready.

**UI**
- `BlocksLeft.luau` is a small rounded label. It stays hidden until the count arrives and turns red at 0.
- `Main.client.luau` now positions a container at the bottom of the screen that stacks the label above `BlockPicker`. BlockPicker no longer positions itself; it only takes a `LayoutOrder`.
- It says "1 block left" rather than "1 blocks left". If you want the exact wording at 1 too, it's a one-line change.

**Adding the next synced value:** add an atom with the same field name to both PlayerState modules (the server one with its starting value, the client one starting at `nil`), and change it on the server with `PlayerState.get(player).<field>(newValue)`. Nothing else needs to change.

Two of my commands were blocked automatically because this session can't answer permission prompts, but neither left anything unchecked. One would have run StyLua's auto-format, so I made its single line-wrap change by hand and the format check passes. The other was a filtered version of the type check, which I re-ran without the filter.