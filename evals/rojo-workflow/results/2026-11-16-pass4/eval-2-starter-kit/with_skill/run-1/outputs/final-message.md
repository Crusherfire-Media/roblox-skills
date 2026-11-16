I've added the starter kit as three new files. Nothing is committed yet. All the local checks pass, but I haven't played it in Studio.

**What I added**
- **`src/ReplicatedStorage/Shared/StarterKit.model.json`**: a Configuration named `StarterKit` under `ReplicatedStorage.Shared`, with number attributes Brick 20, Dirt 20, Grass 10, Window 0, Wood 10. Designers can change them in the Properties window.
- **`src/ServerScriptService/StarterKit.server.luau`**: when a player joins, it goes through each block type in `BlockTypes.List` and sets that count as an attribute on the Player. When every count is set, it also sets `StarterKitGiven = true`.
  - It finds `StarterKit` anywhere under ReplicatedStorage, so designers can move it.
  - If an attribute is missing, negative or not a number, the player gets 0 of that block and the server logs a warning. Decimals are rounded down.
  - It also handles players who joined before the script connected.
- **`src/StarterPlayer/StarterPlayerScripts/StarterKitNotification.client.luau`**: waits for `StarterKitGiven`, then sends one `SendNotification` titled "Starter kit", for example "20 Brick, 20 Dirt, 10 Grass, 10 Wood".
  - Block types with a count of 0 are left out, so Window doesn't appear.
  - It doesn't repeat when the player respawns.
  - `SetCore` can fail right after joining, before Roblox is ready to show notifications, so it retries every 0.5 seconds, up to 20 times.

**Decisions you might want to change**
- **The extra `StarterKitGiven` attribute**: I added it so the client only shows the notification once every count has arrived, not while some are still missing. It sits on the Player next to the block counts.
- **Plain scripts, not Module Loader modules**: the Module Loader package is installed but the project doesn't run it yet, so I matched the existing `Main` scripts.

**Checks**
- **Passed**: `stylua --check`, `selene` and `luau-lsp analyze` (strict mode) found no problems. The sourcemap shows `StarterKit` coming through as a Configuration, which means Rojo read the JSON file. The file has no byte order mark (BOM), which would stop Rojo from reading it.
- **Blocked**: `rojo build`, which would have confirmed the attribute values themselves, needed approval and this session can't grant it.
- **Not done**: playing the game to see the counts and the notification, because I can't reach Studio from here. That's the thing to check next.