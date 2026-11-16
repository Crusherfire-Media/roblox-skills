I've fixed the story and the picker it depends on, but I haven't run any of it. My shell command was blocked because this session can't approve commands, so I couldn't run a linter, tests or Studio. Please open the story in UI Labs and play-test once to confirm.

**What was wrong and what I changed:**

1. **The error on load (`attempt to index nil with 'DisplayName'`).** The picker read `Players.LocalPlayer.DisplayName` as soon as it was loaded. In Studio's edit mode, where UI Labs runs, there is no local player, so that value is nil. The picker now takes the name for its title ("…'s blocks") as a `PlayerName` setting. `Main.client.luau` passes `Players.LocalPlayer.DisplayName`, so the game shows the same title as before. The story has a new **PlayerName** control under Look, which defaults to "Player".

2. **TileClick sounds piling up in SoundService.** Each time UI Labs loaded the picker, it made a new sound and put it in SoundService, and nothing ever removed it. Now each picker makes its own click sound inside its own panel, so the sound is removed when the picker closes or reloads.

3. **Show Names did nothing until reload.** The story read the control once instead of following its changes, and the picker only built the name labels at startup. The story now passes the control itself. The picker always builds the name labels and shows or hides them based on Show Names. Each tile already keeps room for its name either way, so the layout is unchanged.

4. **Selected control.** The story was reading it from the wrong place (`props.controls.Selected`). It now reads `props.controls.Block.Selected`, so choosing a block highlights that tile.

In game, the picker should look and work the same: same layout, same title, names shown, same click sound when you pick a tile.

**Things to know:**
- The dozens of TileClick sounds already in your SoundService are still there. These changes stop new ones from being added but don't remove the old ones. Delete them by hand in Studio and save the place.
- In the story, a click may make no sound, because Studio doesn't always play sounds while the game isn't running. Clicks do still print `Selected <name>`. In game the click sound plays as before.

The changes are in `BlockPicker.luau`, `BlockPicker.story.luau` and `Main.client.luau`.