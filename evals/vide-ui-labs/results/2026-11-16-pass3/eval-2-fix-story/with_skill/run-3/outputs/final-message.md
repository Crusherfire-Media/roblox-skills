The story should now open, Show Names should work live, and opening or reloading the story should no longer add anything to your place. I couldn't run anything to confirm this. The session blocked every command I tried, including the formatter, linter and type checker, and there was no Studio connection to open the story.

**What I changed**
- **Picker (`BlockPicker.luau`):**
  - It no longer reads `Players.LocalPlayer` when it loads. That was the "attempt to index nil with 'DisplayName'" error, since there is no player in UI Labs. The name in the title now comes in as a new `PlayerName` setting.
  - It no longer puts a `TileClick` sound in SoundService each time it's loaded. The sound now lives inside the picker and goes away with it.
  - Show Names now hides and shows the names live instead of being read once. Each tile keeps the same space whether its name shows or not, so the layout doesn't move.
- **`Main.client.luau`** passes the player's display name to the picker. In game the picker should look and work as before.
- **Story:**
  - It now reads the selection from its `Block` group. It was reading from the wrong place, so the picker got nothing.
  - Both the dropdown and clicking a tile move the yellow outline, and clicks print `Selected <name>`.
  - It has a new Display Name control for trying long names.
  - The controls are grouped and ordered Block, Player, Look.

**The type-checker errors after my reply:** it reported "Unknown require" errors, and I believe they come from an out-of-date `sourcemap.json`, not from the code. That file has the `Shared` and `StarterPlayerScripts` folders but none of the modules in them (`BlockTypes`, `BlockPicker`, `BlockPlacer`), and no `Stories` folder. One error is on Main's `BlockPlacer` require, which I didn't change. I tried to rebuild the sourcemap and re-check, but that command was blocked too.

**What you should do**
1. Rebuild the sourcemap and re-check the three files:
   - `rojo sourcemap default.project.json --output sourcemap.json`
   - `luau-lsp analyze` on the three files, then `stylua --check` and `selene`.
2. Delete the `TileClick` sounds already in SoundService and save. The fix stops new ones but doesn't remove the old ones.
3. Open BlockPicker in UI Labs and check that:
   - it opens with no error, and SoundService stays the same after opening and reloading;
   - Show Names toggles the names right away;
   - the dropdown and clicking tiles both move the outline;
   - a long display name is cut off with "…".

   The click sound won't play in UI Labs, because Studio doesn't play sounds there. It should still play in a playtest.