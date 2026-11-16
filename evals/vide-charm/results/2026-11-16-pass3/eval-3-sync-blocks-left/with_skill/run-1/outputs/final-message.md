A "50 blocks left" label now sits just above the hotbar, and the server updates it through Charm and CharmSync every time the player places a block. The type checker, selene and StyLua all pass. I haven't run it in Studio, though, so I haven't seen it update in a live game.

**How the count gets to the client**
- **`ReplicatedStorage/Shared/SyncedPlayerData.luau`** defines the shape of the synced data, currently `{ BlocksLeft: number }`, plus its default values. The 50 limit lives here now, so there's only one copy of it. Each player gets their own sync key (`PlayerData-<UserId>`), because a CharmSync key covers one signal for every player.
- **`ServerScriptService/PlayerData.luau`** gives each player a Charm signal holding that table and syncs it to that player's client only. Server scripts read it with `PlayerData.get(player)` and change it with `PlayerData.update(player, fn)`. The client tells the server when it's ready to receive, so the first full copy of the data isn't sent before the client is listening.
- **`StarterPlayerScripts/PlayerData.luau`** holds the client's copy, filled by CharmSync and read-only. You read it with `PlayerData.getData()`.
- **`BlockPlacement.server.luau`** no longer keeps its own `placedCounts` table. It refuses a placement when `BlocksLeft` is 0 and takes one away after each placement, so the number the player sees is the same number the server enforces.

**Adding the next value:** add a field to `Data` and `DEFAULT` in `SyncedPlayerData`, change it on the server with `PlayerData.update`, and read it in the UI with `VideCharm.useSignalState(function() return PlayerData.getData().NewField end)`. You don't need new remotes or sync code.

**UI**
- **`BlocksLeftLabel.luau`** is a dark rounded label. It says "1 block left" for one and turns red at 0.
- **`Hotbar.luau`** stacks the label above `BlockPicker` at the bottom center. I moved the bottom-of-screen positioning from `BlockPicker` into `Hotbar`, and `BlockPicker` now takes an optional `LayoutOrder`.
- **`Main.client.luau`** connects the label to the synced count and starts the client sync.

I also added UI Labs stories for both new components in `ServerScriptService/Stories`, with a new `GameUI.storybook`. That folder is only for Studio and the game never loads it.

**Not done**
- I haven't run the stories in UI Labs or checked the layout on screen. In UI Labs, open **Hotbar** and try `BlocksLeft` at 0, 1 and 50 to see the red state, the "1 block left" wording, and how it sits above the tiles.
- In a playtest, check that the label starts at 50, goes down by one per block, and reaches 0 at the limit.
- A Python-based edit command was blocked by the permission settings, so I made those edits with the normal edit tool. The result is the same.

Separately, `Main.client.luau` doesn't turn on Vide's strict mode (`Vide.strict = RunService:IsStudio()` right after requiring Vide). Strict mode catches common UI bugs during development, and I can add that line if you want it.