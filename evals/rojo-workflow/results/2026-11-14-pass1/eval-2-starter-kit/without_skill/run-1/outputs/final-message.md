The starter kit is in place. All four project checks pass with no errors or warnings: the Rojo sourcemap regenerates, and luau-lsp, selene and stylua are clean. I couldn't run it in Studio from here, so I haven't seen it work in a live game.

**What I added**
- **`src/ReplicatedStorage/Shared/StarterKit.model.json`** (new): Rojo builds this as a `Configuration` named `StarterKit` at `ReplicatedStorage.Shared.StarterKit`. It has the number attributes Brick 20, Dirt 20, Grass 10, Window 0 and Wood 10, which designers can edit in the Properties window. The regenerated sourcemap shows it as a `Configuration`.
- **`src/ServerScriptService/Main.server.luau`**: when a player joins, the server goes through `BlockTypes.List` and sets an attribute on the player for each block type, using the count from `StarterKit` (for example `Brick = 20`). If a block type has no number attribute in the config, it gives 0 and prints a warning, so every block type always gets a value. Players who were already in the game when the script started get the kit too.
- **`src/StarterPlayer/StarterPlayerScripts/Main.client.luau`**: waits until all the count attributes have arrived on the local player, then sends one notification titled "Starter kit", e.g. "20 Brick, 20 Dirt, 10 Grass, 10 Wood". `SendNotification` can fail if it's called too early in the session, so the script retries for up to about 10 seconds. The notification shows once per session, not on each respawn.

**Choices you may want to change**
- Block types with a count of 0 (Window, by default) are left out of the notification. If every count is 0, it says "No starting blocks this time."
- Counts are rounded down and can't go below 0.

**Two things to know**
- **Studio edits aren't saved to the file automatically.** Rojo syncs from the file into Studio, not the other way. If a designer changes a count in Properties and wants to keep it, the value has to go into `StarterKit.model.json`, or the next sync will overwrite it.
- **`sourcemap.json` changed** because I regenerated it. That file is tracked in git, so it will show up in the diff.

My first command to look around the repo was blocked by the permission check, so I read the files with the file tools instead. Nothing is committed.