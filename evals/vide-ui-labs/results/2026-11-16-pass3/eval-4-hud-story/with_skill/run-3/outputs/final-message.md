I've added the story, but I haven't been able to run it in Studio: no Studio connection was available here. Please open it in UI Labs as the first check.

**The HUD is now split into two modules**

The old HUD read `Players.LocalPlayer` and waited for a server remote, and both of those break when nothing is running. It also added the blur to `Lighting`, changed `CurrentCamera.FieldOfView` and played the sound as soon as it was built. A story can't render it as it was without doing all of that to your edit place, so I split it:

- **`BuildModeHudView.luau`** (new, next to the HUD) is just the panel, with the same layout and look as before. It gets the player name, block type and placed count from outside, and touches nothing beyond its own frame.
- **`BuildModeHud.luau`** is still what `Main.client.luau` shows when you press B. I didn't change `Main`. It keeps the blur, the camera zoom and its reset on close, the open sound, the block-type updates from `BlockPlacer`, and the placed count that starts at 0 each time build mode opens. It now builds its panel with `BuildModeHudView`.

One small change in game: the wait for the `BlockPlaced` remote now runs in its own thread, because Vide components mustn't pause while they're being built. The panel no longer waits for that remote before it appears. The count works the same once the remote exists.

**The story** is in `src/ServerScriptService/Stories/`:
- `GameUI.storybook.luau` is the storybook for that folder.
- `BuildModeHudView.story.luau` has three controls in this order:
  1. **Block**: a dropdown of every block type, built from `BlockTypes.List`, so new blocks appear automatically.
  2. **PlayerName**: free text.
  3. **PlacedCount**: a slider from 0 to 10,000.

The story only loads the panel module and `BlockTypes`, so it never creates the blur, moves the camera or plays the sound.

**Checks:** StyLua and selene pass on the changed files. luau-lsp shows no errors in my files; the errors it does report are all inside the Vide and UI Labs packages.

**What to look at in UI Labs** (Game UI → BuildModeHudView):
- A 20-character name (the Roblox maximum), such as `ABCDEFGHIJKLMNOPQRST`. The line reads "<name> is building" and gets cut off with "…", so a long name will probably lose the "is building" part. That's existing behavior; I didn't redesign it.
- PlacedCount at 10000, to see the count line at its widest.
- Each block, to check the color swatch and name.
- After closing the story, Lighting should have no `BuildBlur` and the camera's FieldOfView should be unchanged.

The panel sits 16 px from the top-left corner of the preview, as it does in game. Nothing is committed yet.