A "<n> blocks left" label now sits just above the hotbar. The server syncs the player's count to their client through Charm and CharmSync, so the label updates every time they place a block. StyLua, selene and luau-lsp all pass on the changed files. I haven't played it in Studio or opened the new story in UI Labs, because there's no Studio connection in this session.

**How it works**
- **Shared data shape:** `src/ReplicatedStorage/Shared/PlayerData.luau` holds the per-player data type and its starting values. Right now that's `{ BlocksPlaced = 0 }`. It also builds each player's sync key (`PlayerData-<UserId>`) and names the two remotes.
- **Server:** `src/ServerScriptService/PlayerDataServer.luau` keeps one Charm signal per player and exposes `get(player)` and `update(player, fn)`. When the client says it's ready, the server starts syncing that player's signal, and stops when the player leaves. It ignores repeat ready requests, so a client can't spam it.
- **Placement:** `BlockPlacement.server.luau` no longer keeps its own count. It checks and increases `BlocksPlaced` through `PlayerDataServer`. The limit of 50 moved to `BlockTypes.MaxBlocksPerPlayer` so the client can read it too. The server still enforces it.
- **Client:** `PlayerDataClient.luau` keeps a client copy of the signal that only CharmSync writes to. It connects the sync listener before telling the server it's ready, so the first full update can't be missed.
- **UI:** `BlocksLeftLabel.luau` is a rounded label that reads "1 block left" in the singular and turns red at 0. `Main.client.luau` connects it to the synced count. Its position comes from a new `HotbarLayout.luau`, which now holds the hotbar sizes that `BlockPicker` used to define itself.
- **Story:** `src/ServerScriptService/Stories/` holds a storybook and `BlocksLeftLabel.story`, with a slider from 50 down to 0.

The server syncs the count of blocks placed, and the client subtracts it from the shared limit. If you later want different limits per player, sync a limit field the same way.

**Adding the next value:** add a field to the `PlayerData` type and its starting value in `PlayerData.luau`. Change it on the server with `PlayerDataServer.update` (return a new table). Read it in UI with `VideCharm.useSignalState(function() return PlayerDataClient.getData().YourField end)`. No new remotes or sync keys are needed.

**Please check in Studio**
- The label shows "50 blocks left" when you join and drops by one per block placed.
- At 0 it reads "0 blocks left" in red, and placing stops.
- It sits clear of the hotbar on both phone and desktop sizes.
- In UI Labs, open "Game UI → BlocksLeftLabel" and drag the slider down to 0.

**Left as is**
- `PlayerDataServer` creates its remotes as soon as it's loaded, the same way `BlockPlacement` does. If a test or story ever loads it outside a playtest, it should check `RunService:IsRunning()` first.
- The client never turns on `Vide.strict = RunService:IsStudio()`. It's worth adding right after Vide is first loaded.