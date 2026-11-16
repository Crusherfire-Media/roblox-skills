I've added the starter kit, but it's untested. None of the project's checks ran (Rojo sourcemap/build, luau-lsp, selene, stylua): they needed approval, and this session had no way to ask for it. I read the code over by hand instead. Before you rely on it, run the four commands under **Checks** in the README and test it in Studio.

**What I added**

- **`src/ReplicatedStorage/Shared/StarterKit.model.json`**: this becomes a Configuration called `ReplicatedStorage.Shared.StarterKit` with number attributes Brick 20, Dirt 20, Grass 10, Window 0, Wood 10. Designers can edit them in the Properties window. It uses Rojo's `attributes` field in model files.
- **`src/ServerScriptService/StarterKit.server.luau`**: when a player joins, it sets one number attribute on the Player for each block type in `BlockTypes.List`, using the values from the config.
  - The server finds `StarterKit` anywhere under ReplicatedStorage, so designers can move it.
  - A missing or non-number value counts as 0, with a warning. Values are rounded down and can't go below 0.
  - It won't overwrite a count that's already set on the player.
  - It also covers players who joined before the script connected.
- **`src/StarterPlayer/StarterPlayerScripts/StarterKitNotification.client.luau`**: waits until the player has a count for every block type, then shows one `SendNotification` such as "You got: Brick x20, Dirt x20, Grass x10, Wood x10".
  - Block types with 0 (Window) are left off the list.
  - If the notification system isn't ready yet, it retries for up to about 10 seconds.
  - It shows only once per session, not on each respawn.

**Decisions for you**

- **Studio edits can be lost.** If designers change the counts in Studio while Rojo is syncing, Rojo doesn't write those changes back to `StarterKit.model.json`. The file's values can overwrite them on the next sync. Final values should go into that file, or designers should tune only in places where Rojo isn't syncing.
- **New block types need a matching attribute.** If you add a block type to `BlockTypes.luau`, add the same attribute to `StarterKit.model.json`. Otherwise players get 0 of it and the server logs a warning.