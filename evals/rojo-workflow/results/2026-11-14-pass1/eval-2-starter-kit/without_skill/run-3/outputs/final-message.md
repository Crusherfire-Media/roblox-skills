I've added the starter kit. Lint, format and type checks pass, but I couldn't build the place or run it in Studio, so I haven't seen it work in a game.

**What I changed**
- **`src/ReplicatedStorage/Shared/StarterKit.model.json`** (new): a Configuration named `StarterKit` that syncs to `ReplicatedStorage.Shared.StarterKit`. It has number attributes Brick 20, Dirt 20, Grass 10, Window 0, Wood 10, which designers can edit in the Properties window.
- **`src/ServerScriptService/Main.server.luau`**: when a player joins, the server sets one number attribute per block type on the Player, using the counts from `StarterKit`.
  - It looks for `StarterKit` anywhere under ReplicatedStorage, so designers can move it.
  - If an attribute is missing or isn't a number, that block type gets 0 and the server prints a warning.
  - Players already in the game when the script starts also get their kit.
- **`src/StarterPlayer/StarterPlayerScripts/Main.client.luau`**: the client waits until it has a count for every block type, then shows one `SendNotification`, for example "You got: 20 Brick, 20 Dirt, 10 Grass, 10 Wood".
  - Block types with a count of 0 are left out, so Window doesn't appear by default.
  - Roblox can reject the notification for a moment right after joining, so the client keeps retrying for up to about 10 seconds.

**Checks**
- I regenerated `sourcemap.json` with `rojo sourcemap`; `StarterKit` shows up in it.
- `selene`, `stylua --check` and `luau-lsp analyze` all came back with no problems.
- `rojo build` was blocked: the session can't approve commands that need permission. That means I couldn't confirm the attributes actually reach Studio. They use the `attributes` field in a Rojo model file, which Rojo 7.7 supports. After syncing, check that `ReplicatedStorage.Shared.StarterKit` has the five attributes.

Nothing is committed.