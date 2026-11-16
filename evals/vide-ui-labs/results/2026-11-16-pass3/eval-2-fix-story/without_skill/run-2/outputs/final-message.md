I fixed the story and the picker module. Nothing was tested: I don't have Studio or UI Labs here and the packages aren't installed, so please open the story to confirm. The shell was also blocked, so I read the files directly instead of listing them. `Main.client.luau` didn't need any changes.

**What was wrong and what I changed**

1. **The story wouldn't load (`attempt to index nil with 'DisplayName'`).** When the picker module loaded, it read `Players.LocalPlayer.DisplayName`. In edit mode there is no `LocalPlayer`, so it crashed. The title now looks up the name when it's drawn. The picker also takes an optional `PlayerName` prop:
   - **In game:** nothing is passed, so it still shows your display name.
   - **In the story:** there's a new **Look → PlayerName** text control (default "Player").

2. **Show Names did nothing until reload.** The story read the control's value once, and the picker only accepted a fixed true/false, so later changes were never seen. The story now passes the controls themselves, and the name label's visibility follows them, so toggling updates right away. Each tile was already sized to fit its name label, so hiding it with `Visible` looks the same as leaving it out did. `Main.client.luau` still passes `true`.

3. **The Selected control was never used.** The story read `props.controls.Selected`, but the control is inside the `Block` group. It now reads `props.controls.Block.Selected`.

4. **TileClick sounds kept piling up in SoundService.** The picker module created a Sound in `SoundService` every time it was required. UI Labs requires the module again on every open or reload, so each one added another copy. The sound is now created per picker, inside the picker's frame, so it's removed when the picker closes. Tiles play it through `SoundService:PlayLocalSound`, which should also work in Studio edit mode. The sound ID and volume are unchanged.

**What you need to do:** the TileClick sounds already in your place won't remove themselves. Select all the `TileClick` Sounds under SoundService and delete them, then save. After that, opening or reloading the story shouldn't add anything to your place.

Clicking a tile in the story still only prints the block name. The highlight follows the Selected control, as it did before.