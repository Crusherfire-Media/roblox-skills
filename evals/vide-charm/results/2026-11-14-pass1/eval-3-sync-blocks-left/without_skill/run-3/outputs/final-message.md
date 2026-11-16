Players now see "<n> blocks left" just above the hotbar, and the server sends the new count through CharmSync each time they place a block. The luau-lsp type check, selene and StyLua all pass, but I haven't run it in Studio, so the sync and the label are untested in a real game.

**How the count gets to the client**
- **`src/ReplicatedStorage/Shared/PlayerData.luau`** describes each player's data. For now it holds one field, `BlocksLeft`, which starts at 50. The file also sets the per-player sync key and the remote's name.
- **`src/ServerScriptService/PlayerData.luau`** keeps one Charm signal per player and offers `PlayerData.get(player)` and `PlayerData.update(player, fn)`. When a client says it's ready, the server subscribes that player to their own data only. It unsubscribes them when they leave.
- **`src/StarterPlayer/StarterPlayerScripts/PlayerData.luau`** is the client side. It applies the updates the server sends and exposes them as a read-only signal through `PlayerData.get`, which returns nil until the first update arrives.
- **One remote, `PlayerDataSync`**, carries everything: the client fires it once to say it's ready, and the server uses it to send updates. It isn't tied to the block count, so other values can use it too.

**Adding the next value:** add a field to the type and a starting value in the shared `PlayerData.luau`. Change it on the server with `PlayerData.update`, and read it on the client through `PlayerData.get`. You don't need any new remotes or sync code.

**Changes to existing code**
- **`BlockPlacement.server.luau`**: I removed `placedCounts` and `MAX_BLOCKS_PER_PLAYER`. The script now checks `BlocksLeft <= 0` and subtracts one with each placement, so the limit is only stored in one place (the starting value of 50).
- **UI**: the new `BlocksLeftLabel.luau` is hidden until the first update arrives and turns red at 0. It says "1 block left" rather than "1 blocks left". To put the label above the hotbar, `Main.client.luau` now places both in a container at the bottom of the screen. Because of that, `BlockPicker.luau` no longer positions itself; it just takes a `LayoutOrder`.

The changes aren't committed.