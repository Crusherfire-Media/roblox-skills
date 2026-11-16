I've added the starter kit as three new files.

**Config:** `src/ReplicatedStorage/Shared/StarterKit.model.json` creates `ReplicatedStorage.Shared.StarterKit`, a Configuration with number attributes Brick 20, Dirt 20, Grass 10, Window 0, Wood 10. Designers can change these in the Properties window. Because Rojo syncs from the file, also update the JSON so a later sync doesn't put the old numbers back.

**Server:** `src/ServerScriptService/StarterKit.server.luau` runs when a player joins and sets one number attribute on the Player for each entry in `BlockTypes.List`, using the value from `StarterKit`:
- If a block type has no attribute on `StarterKit`, the player gets 0. If the value isn't a number, it warns in the output and uses 0. Decimals are rounded down and negatives become 0.
- It won't overwrite a count that something else has already set.
- It also covers players who were already in the game when the script started.

**Client:** `src/StarterPlayer/StarterPlayerScripts/StarterKitNotification.client.luau` waits until every block type has a count, then shows one `SendNotification`, for example "Starter kit: 20 Brick, 20 Dirt, 10 Grass, 10 Wood".
- **Zero counts are left out**, so Window doesn't appear by default. That's my reading of "what they got"; if you want zeros listed, remove the `count > 0` check.
- `SetCore` fails if it runs before Roblox's own scripts are ready, so it retries for up to about 10 seconds.

**Checks:** I regenerated the sourcemap and ran luau-lsp, selene and stylua. All passed with no errors, and `StarterKit` shows up in the sourcemap. I haven't run it in Studio.

**What was blocked:** I tried a `rojo build` to confirm the model file becomes a Configuration with those five attributes. That command needed approval and this session can't grant it, so it didn't run. A quick look at `ReplicatedStorage.Shared.StarterKit` after your next sync will confirm it.

I haven't committed anything.