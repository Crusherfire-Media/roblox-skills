A "<n> blocks left" label now sits just above the hotbar. The count comes from the server through Charm and CharmSync, and it updates each time the server accepts a placement. StyLua, selene and luau-lsp all pass with no errors. I haven't run it in Studio or played it, so the live update hasn't been seen working yet.

**How the count gets to the client**
- **`ReplicatedStorage/Shared/PlayerDataSync.luau`**: describes the per-player data both sides share. It holds the `PlayerData` type (just `BlocksLeft` for now), the starting values (`BlocksLeft = 50`), the remote's name, and one sync key per player.
- **`ServerScriptService/PlayerData.luau`** (new): the server's copy of every player's data, kept in one Charm signal. It sets up a player's data when they join and removes it when they leave. `Main.server.luau` starts it with `PlayerData:Start()`. Once a client says it's ready, the server sends that player's own entry to them and nobody else.
- **`StarterPlayerScripts/PlayerData.luau`** (new): the client's copy, filled in by CharmSync. It shows the starting values until the first update arrives (about one frame), and the UI only reads from it.
- **One remote, `PlayerDataSync`**, does both jobs: the client fires it once to say it's ready, and the server sends the updates back through it.

**Change to the limit check:** `BlockPlacement.server.luau` no longer keeps its own `placedCounts` table or `MAX_BLOCKS_PER_PLAYER` constant. It rejects a placement when `BlocksLeft <= 0` and subtracts one through `PlayerData:Update` after a successful one. The 50-block limit is now `DefaultData.BlocksLeft` in the shared module.

**Adding the next synced value:** add a field to `PlayerData` and `DefaultData`, change it on the server with `PlayerData:Update(player, ...)`, and read it in UI with `VideCharm.useSignalState(function() return PlayerData.getData().NewField end)`. No new remote or setup is needed.

**UI**
- **`BlocksLeftLabel.luau`** (new): a pill-shaped label above the hotbar. It says "1 block left" when there's one, and its text turns red at 0.
- **`Hotbar.luau`** (new): stacks the label above the block picker and now owns the bottom-of-screen position. I took the position settings out of `BlockPicker.luau`, which now accepts a `LayoutOrder` instead.
- **`Main.client.luau`**: mounts the `Hotbar` and starts syncing in its own thread.
- **UI Labs story**: I added `ServerScriptService/Stories/Hotbar.story.luau` (plus a storybook) with a slider for the count. Rojo will sync it into the place, where it doesn't run. If you don't use UI Labs, you can delete the folder.

**What to check in a playtest**
- The label reads "50 blocks left" and goes down by one with each block placed.
- At 0 it turns red and further clicks place nothing.
- On a phone-sized screen, the label doesn't crowd the hotbar.

The two `PlayerData` modules use `const` and string requires, following the style guide; the older files still use `local`.

This change is over 100 lines and adds a remote. That's normally when I'd run the Roblox reviewer agent, but I don't start agents unless you ask, so say if you want that review.