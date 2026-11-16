Players now see "<n> blocks left" just above the hotbar, and it updates as they place blocks. The count is kept on the server and sent to each player with Charm and CharmSync over one RemoteEvent. I haven't run it in Studio. StyLua and selene pass on `src`. I couldn't do a real type-check: there's no Roblox definitions file locally, so `luau-lsp` only reported missing Roblox globals, and my filtered retry was blocked by the permission system.

**How it works**
- **`Shared/PlayerState.luau`** defines each player's synced data, which is just `blocksLeft` for now, plus its starting values, the remote's name and the sync key for each player.
- **`ServerScriptService/PlayerStateServer.luau`** keeps one Charm signal per player and syncs it to that player's client through a RemoteEvent called `PlayerStateSync`. Code changes a player's data with `PlayerStateServer.update(player, function(state) ... end)`. It cleans up when a player leaves, and a remote event that arrives after they've left won't recreate their data.
- **`BlockPlacement.server.luau`** no longer has its own `placedCounts` table. It sets `blocksLeft = 50` when a player joins, checks `blocksLeft <= 0` to refuse a placement, and subtracts 1 on each one. The synced value is now the only count the server keeps.
- **`PlayerStateClient.luau`** holds the client's copy, which is empty until the server's first update arrives. `start()` tells the server the client is ready to receive updates.
- **`BlocksLeft.luau`** is the label. It stays hidden until the first update arrives, so it never flashes a wrong number. `Main.client.luau` reads the client's copy using VideCharm, which was already installed.
- **`HotbarLayout.luau`** holds the hotbar's sizes, which used to be inside `BlockPicker.luau`. Both the hotbar and the label use it, so the label stays lined up if the hotbar's size changes. The hotbar itself looks the same.

**Adding the next value:** add a field to the `PlayerState` type, give it a starting value in `Default`, change it on the server with `PlayerStateServer.update`, and read it on the client from `PlayerStateClient.get()`. No new remote or sync setup is needed.

**Decision for you:** at exactly one block the label says "1 block left" rather than "1 blocks left". If you want your exact wording everywhere, it's a one-line change in `BlocksLeft.luau`.