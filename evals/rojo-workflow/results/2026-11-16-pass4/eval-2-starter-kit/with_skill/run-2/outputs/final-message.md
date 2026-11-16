I've added the starter kit. The local checks pass, but I haven't run it in Studio or playtested it.

**Files**
- **New: `src/ReplicatedStorage/Shared/StarterKit.model.json`** creates a Configuration called `ReplicatedStorage.Shared.StarterKit` with number attributes Brick 20, Dirt 20, Grass 10, Window 0 and Wood 10. Designers can change these in the Properties window.
- **`src/ServerScriptService/Main.server.luau`**: when a player joins, the server goes through `BlockTypes.List` and copies each count from StarterKit onto the Player as an attribute (for example `Brick = 20`). If a block type has no number attribute on StarterKit, it logs a warning and gives 0. After all the counts, it sets one extra attribute, `StarterKitGiven = true`, so the client knows the whole kit has arrived.
- **`src/StarterPlayer/StarterPlayerScripts/Main.client.luau`**: waits for `StarterKitGiven`, then shows one notification such as "20 Brick, 20 Dirt, 10 Grass, 10 Wood". The script runs once per session, so the notification doesn't come back on respawn.

**Choices you may want to change**
- **Zero counts are left out of the notification**, so Window doesn't appear while it's 0. If the player gets nothing at all, the text says "No blocks this time."
- **The notification retries.** `SetCore("SendNotification")` fails for a short time after joining, so the client tries every 0.5 seconds, up to 20 times.
- **The kit is given once per session.** Players don't get it again on respawn. Counts aren't saved, so a player who rejoins gets a fresh kit.
- **The players' counts are copied when they join.** Changing StarterKit during a playtest only affects players who join after the change.

**Checks:** Regenerating the sourcemap worked, and it shows `StarterKit` as a Configuration. luau-lsp analysis found 0 errors and 0 warnings. `selene` and `stylua --check` both passed. The JSON file is saved without a byte order mark.

**Blocked:** Two commands were denied because this session can't approve permission prompts:
- my first command to list the repo files (I used the file tools instead);
- a test `rojo build`, meant to confirm the five attributes make it into the built place.

Rojo did pick up the file, but you'll want to check that StarterKit shows its five attributes in Studio once `rojo serve` syncs.

Nothing is committed. The changes are on `main`.