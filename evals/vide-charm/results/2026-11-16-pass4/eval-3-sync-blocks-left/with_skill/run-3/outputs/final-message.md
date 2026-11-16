The "<n> blocks left" label now sits above the hotbar. The server syncs the count to each player through Charm and CharmSync, and the label updates every time the server accepts a placement. luau-lsp, selene and stylua all pass. I couldn't run it in Studio, so neither the live sync nor the UI Labs story has actually been run yet.

**How it works**
- **Shared definition** (`src/ReplicatedStorage/Shared/SyncedPlayerData.luau`): holds the type of the synced data (`{ BlocksLeft: number }`), its starting values, each player's sync key, and the remote's name.
- **Server** (`src/ServerScriptService/PlayerData.luau`): keeps one Charm signal per player and sends it with CharmSync over a single `PlayerDataSync` remote. Other server scripts use `PlayerData.get(player)` and `PlayerData.update(player, fn)`. `Main.server.luau` starts it.
- **Placement**: `BlockPlacement.server.luau` now checks and counts down `BlocksLeft` instead of its own count table, so the synced value is the only count. I moved the 50 into `BlockTypes.MaxBlocksPerPlayer` so the server and client defaults match.
- **Client** (`StarterPlayerScripts/PlayerData.luau`): a Charm signal that CharmSync fills from the server. It connects its listener before asking the server for data, so the first update isn't missed. `Main.client.luau` reads `BlocksLeft` from it and passes it to the new `BlocksLeftLabel.luau`.

**Adding the next value:** add a field to `Data` and to `createDefault` in `SyncedPlayerData`, have the server change it with `PlayerData.update`, and read it on the client from `PlayerData.getData()`. No new remote is needed.

**Review fixes:** I ran the change through the Roblox reviewer and fixed two edge cases it raised:
- If a player rejoins the same server quickly, the old player's sync entry is dropped. Otherwise the new client would show stale data.
- A placement request that arrives after the player has left is rejected. Before, it would have been placed without being counted.

**Choices and loose ends:**
- **Wording:** the label says "1 block left" for one, not "1 blocks left". At 0 it turns red.
- **Duplicated layout numbers:** the label works out its height from BlockPicker's sizes, which it copies, with a "keep in sync" comment in both files. If the hotbar's size changes, update `HOTBAR_TOP` in `BlocksLeftLabel.luau` too.
- **Story:** I added the project's first UI Labs storybook and a `BlocksLeftLabel` story in `ServerScriptService/Stories`, with a slider from 0 to 50.
- **Vide strict mode:** `Main.client.luau` doesn't set `Vide.strict = RunService:IsStudio()`. Turning it on catches mistakes in UI code during development.

**To check in Studio:** the label should start at "50 blocks left" just above the hotbar and drop by one per block. It should turn red at 0, and further clicks should place nothing.