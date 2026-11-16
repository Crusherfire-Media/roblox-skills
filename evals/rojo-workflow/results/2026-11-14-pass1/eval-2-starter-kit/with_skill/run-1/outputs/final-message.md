I added the starter kit. All three checks pass: `luau-lsp analyze` reports no errors, `selene` finds 0 errors and 0 warnings, and `stylua --check` is clean. I haven't playtested it, because this session has no connection to Studio.

**What changed**

- **`src/ReplicatedStorage/Shared/StarterKit.model.json`** (new): syncs in as a Configuration named `StarterKit` at `ReplicatedStorage.Shared.StarterKit`, with the number attributes Brick 20, Dirt 20, Grass 10, Window 0 and Wood 10. Designers can tune them in the Properties window.
- **`src/ServerScriptService/Main.server.luau`**: when a player joins, it sets a number attribute on the Player for each block type in `BlockTypes.List`, using the value from `StarterKit` (so a player gets `Brick = 20`, and so on).
  - It finds `StarterKit` by searching all of ReplicatedStorage, so designers can move it.
  - It reads the values each time someone joins, so a change made during a playtest applies to the next player who joins.
  - If an attribute is missing or isn't a whole number of 0 or more, that count becomes 0 and the server logs a warning. A missing `StarterKit` also gives 0 counts and a warning.
- **`src/StarterPlayer/StarterPlayerScripts/Main.client.luau`**: once all five counts are on the local player, it sends one `SendNotification`, for example "You got: Brick x20, Dirt x20, Grass x10, Wood x10".
  - Types with a count of 0 (Window) are left out, and if every count is 0 there is no notification.
  - `SetCore` fails if it's called before Roblox's built-in scripts are ready, so the client retries for up to 10 seconds.
  - The notification is shown once per join, not on each respawn, because scripts in StarterPlayerScripts don't run again when the character respawns.

**Things to know**

- **Kept the existing scripts:** the project has no Module Loader, so I put the code in the two existing `Main` scripts rather than adding new scripts or systems.
- **Edits in Studio don't save back:** a value changed in Studio's Properties window is overwritten on the next Rojo sync and never reaches Git. To keep a new value, change it in `StarterKit.model.json`.
- **Not committed:** nothing is committed yet.

To check it in Studio, connect `rojo serve`, start a playtest, and look for the five attributes on your Player and the notification on screen.