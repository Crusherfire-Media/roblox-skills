I've added the starter kit, but I couldn't test it in Studio from here, so it hasn't been run in a playtest yet. Analysis (`luau-lsp`), lint (`selene`) and format (`stylua --check`) all pass with no errors. The regenerated sourcemap shows `StarterKit` as a Configuration, a Script and a LocalScript, as intended.

**New files**
- `src/ReplicatedStorage/Shared/StarterKit.model.json`: a Configuration named `StarterKit` (it ends up at `ReplicatedStorage.Shared.StarterKit`) with number attributes Brick 20, Dirt 20, Grass 10, Window 0, Wood 10. Designers can change these in the Properties window.
- `src/ServerScriptService/StarterKit.server.luau`: when a player joins, it sets one number attribute on the Player for each entry in `BlockTypes.List`, using the value from `StarterKit`.
  - It finds `StarterKit` anywhere under ReplicatedStorage, so designers can move it.
  - It reads the counts at join time, so a value changed during a playtest applies to the next player who joins.
  - If a block type has no number attribute, it gives 0 and logs a warning.
- `src/StarterPlayer/StarterPlayerScripts/StarterKit.client.luau`: waits until all five counts have reached the client, then shows one "Starter kit" notification such as "20 Brick, 20 Dirt, 10 Grass, 10 Wood".
  - Types with a count of 0 are left out, which is why Window isn't listed.
  - If the notification can't be shown yet, it retries for about 10 seconds, then logs a warning.

**Things to know**
- **Counts in Studio vs Git:** the next Rojo sync overwrites any change a designer makes to the attributes in Studio. To keep new counts, change them in the `.model.json` file, or write them back with `rojo syncback`.
- **New block types:** if one is added to `BlockTypes.luau`, it also needs an attribute on `StarterKit`. Until then, players get 0 of it and the server logs a warning.
- **Separate scripts:** I put this in new scripts rather than in the existing `Main` scripts.
- **Not committed:** I haven't made a commit.
- **Blocked command:** my first attempt to list files and read the project through Bash was blocked by the permission check. I read the files with the file tools instead, so nothing was missed.