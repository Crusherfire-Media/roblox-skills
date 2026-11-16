I fixed the story and the picker, but I haven't run any of it. I couldn't open Studio or UI Labs from here, and my one shell command that tried to list the repo was blocked by the permission system. Everything below comes from reading the code, and the edits were made directly to the files.

**What was wrong and what I changed**

1. **The crash.** `BlockPicker.luau` read `Players.LocalPlayer.DisplayName` as soon as it loaded. There's no local player when UI Labs runs in edit mode, so loading the story failed with "attempt to index nil with 'DisplayName'". The picker now takes a `PlayerName` prop instead. `Main.client.luau` passes `Players.LocalPlayer.DisplayName`, so the title in game is unchanged. The story gets a new **Look → PlayerName** text control (default "Builder") to fill it in.

2. **Show Names doing nothing until reload.** There were two causes:
   - The story called `props.controls.Look.ShowNames()`, which passed the value once instead of the live control.
   - The picker decided whether to create the name labels only once, when it was built.

   Now the story passes the control itself, and each tile always has its name label, with visibility following `ShowNames`. That prop accepts either `true`/`false` (what Main uses) or a live value. The tiles are always the same height, so in game it looks exactly as before with names on.

3. **TileClick sounds piling up in SoundService.** The module put a new `Sound` into SoundService every time it was loaded, and UI Labs loads it again on every open and reload. Now each picker makes its own click sound inside its own frame, so the sound is removed when the picker closes and the story no longer adds anything to your place. Clicking a tile still plays the same sound at the same volume.

4. **Block → Selected control was disconnected.** The story read `props.controls.Selected`, but the control sits inside the `Block` group. It now reads `props.controls.Block.Selected`.

**One thing for you to do:** the TileClick sounds already in SoundService won't go away on their own, because they're saved in your place. Delete them once in Studio. Nothing else in `src` uses them.

Please test it: open the story, toggle Show Names and change Selected without reloading, reload a few times and check SoundService stays empty, then play-test to confirm the in-game picker is unchanged.