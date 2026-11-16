I added the starter kit, and all the project checks pass. I haven't run it in Studio, so the join flow and the notification are untested.

**Config: `src/ReplicatedStorage/Shared/StarterKit.model.json`**
This adds a `Configuration` named `StarterKit` at `ReplicatedStorage.Shared.StarterKit`, with number attributes Brick 20, Dirt 20, Grass 10, Window 0 and Wood 10. Designers can change these in the Properties window.

**Server: `src/ServerScriptService/Main.server.luau`**
- When a player joins, the server goes through `BlockTypes.List` and sets an attribute on the Player for each block type, using the count from `StarterKit`.
- Players who are already in the server when the script starts get the kit too.
- If a block type has no attribute on `StarterKit` it gets 0. If the value isn't a number, it gets 0 and a warning is printed. Counts are rounded down and can't go below 0.
- After all the counts are set, it sets `StarterKitGiven = true` on the Player. This tells the client the counts are in place.

**Client: `src/StarterPlayer/StarterPlayerScripts/Main.client.luau`**
- It waits for `StarterKitGiven`, then shows one "Starter kit" notification, for example "You got 20 Brick, 20 Dirt, 10 Grass, 10 Wood".
- Blocks with a count of 0, like Window, are left out of the message. If every count is 0, no notification is shown.
- `SetCore("SendNotification")` fails if it's called too early in a session, so the client retries it for up to about 10 seconds.

**Checks**
- The sourcemap rebuilt, and it lists `StarterKit` as a `Configuration`.
- `luau-lsp analyze` found 0 errors and 0 warnings, and `selene` and `stylua --check` passed.

**Not verified:** I tried a full `rojo build` to confirm the counts load onto `StarterKit`, but this session blocked the command because it needed approval. If they're missing when you sync into Studio, write each one in the form `{"Float64": 20}` instead of a plain number.

The change is not committed.