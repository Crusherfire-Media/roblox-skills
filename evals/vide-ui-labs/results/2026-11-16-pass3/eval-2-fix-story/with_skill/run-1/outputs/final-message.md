I fixed the story and the picker. The type check, selene and stylua all pass. I couldn't run the story check or open UI Labs from here (this session has no Studio connection), so the story hasn't been mounted yet.

**What was wrong**

1. **The error:** `BlockPicker.luau` read `Players.LocalPlayer.DisplayName` as soon as the module loaded. There's no local player in edit mode, so UI Labs couldn't load the story.
2. **The TileClick pile-up:** the module also created a `TileClick` sound in `SoundService` as soon as it loaded. UI Labs reloads every module from scratch each time a story opens or reloads, so each reload added another sound to your actual place.
3. **Show Names did nothing:** the story read the control's value once, and the picker only ever built the name labels once from that value. A change only showed up after a reload.
4. **Selected wasn't connected:** the story looked for `props.controls.Selected`, but that control is in the `Block` group, so the value was missing. Clicking a tile also didn't move the highlight in the story.

**Changes**

- **`BlockPicker.luau`**
  - The player's name now comes in as a `PlayerName` prop.
  - The click sound is created inside the picker's frame, so it goes away when the story closes. It also plays inside the UI Labs window.
  - `ShowNames` can now be a live value. The name labels are always built and shown or hidden with it, so the layout is unchanged: tiles always left room for the name.
- **`Main.client.luau`:** passes `PlayerName = Players.LocalPlayer.DisplayName`. In game the picker looks and works as before; the only difference is that the sound sits under the picker instead of in `SoundService`.
- **`BlockPicker.story.luau`:**
  - Reads controls through their groups.
  - Passes Show Names in live.
  - Holds the selection itself, so both the control and tile clicks move the highlight.
  - Adds a `Player > Name` control for the title.

**What you need to do**

- **Delete the leftover sounds:** the `TileClick` sounds already in `SoundService` are saved in your place, and this fix won't remove them.

**What to check in UI Labs:** open BlockPicker. It should mount with no error, and:
- Toggling Show Names should hide and show the labels right away.
- Changing Selected, or clicking a tile, should move the yellow outline. A click should also ping and print `Selected <name>`.
- Changing Player > Name should update the title.
- Reloading should add nothing to `SoundService`.

**Optional:** the project never sets `Vide.strict = RunService:IsStudio()`. It's worth adding where Vide is first required, because it catches more mistakes while you're in Studio.