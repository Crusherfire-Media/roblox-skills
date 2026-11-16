I added the starter kit, and the README's lint, format and type checks all pass. I haven't run it in Studio, so the notification hasn't been seen on screen yet.

**What changed**
- **New `src/ReplicatedStorage/Shared/StarterKit.model.json`**: Rojo turns this into a `Configuration` named `StarterKit` at `ReplicatedStorage.Shared.StarterKit`. It has number attributes Brick 20, Dirt 20, Grass 10, Window 0 and Wood 10.
- **`src/ServerScriptService/Main.server.luau`**: when a player joins, the server goes through `BlockTypes.List` and copies each count from `StarterKit` onto the Player as an attribute, so you get `player:GetAttribute("Brick") == 20`.
  - It reads the counts at join time, so changing them in Properties during a Studio play test affects the next player who joins.
  - If a block type has no attribute on `StarterKit`, it logs a warning and gives 0.
  - It also handles players who were already in the game before the script connected.
- **`src/StarterPlayer/StarterPlayerScripts/Main.client.luau`**: waits until the Player has a count for every block type, then shows one `SendNotification` such as "20 Brick, 20 Dirt, 10 Grass, 10 Wood".
  - Block types with a count of 0 are left out, so Window doesn't appear.
  - `SetCore` fails if it's called too early in a session, so the call is retried for up to about 10 seconds.
  - Scripts in StarterPlayerScripts don't restart when the character respawns, so the notification only shows once per session.

**Checks:** I regenerated `sourcemap.json`, and `luau-lsp analyze`, `selene src` and `stylua --check src` all pass with no problems.

**Not checked:** I tried a `rojo build` to confirm the Configuration and its attributes come out right in the built place, but this session blocked the command because it needed approval. The sourcemap does include `StarterKit`, but the attribute values haven't been checked in a real build or in Studio.

**Note for designers:** Rojo only syncs from the files into Studio. If someone changes the counts in Studio while Rojo is syncing, the next sync can overwrite their changes. To make a change stick, it needs to go into `StarterKit.model.json`.