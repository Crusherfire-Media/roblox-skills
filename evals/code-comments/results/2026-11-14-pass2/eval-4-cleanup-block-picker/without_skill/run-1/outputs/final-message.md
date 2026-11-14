I cleaned up the comments in `BlockPicker.client.luau`. I only touched comments, so the code itself is unchanged. I haven't run selene or the game.

**Removed:**
- Comments that just repeated the code, like "Get services", "Update the source", "Return the ScreenGui" and "the size of each button".
- The v2/v2.1 changelog in the header. Git history already has it.
- The commented-out Roact lines left over from the move to Vide.
- The `-- CHILDREN --` banner, the `-- for` / `-- if` / `-- InputBegan` markers after `end`, and the doc block on `BlockButton` that only restated its parameter types.

**Kept** comments that explain why something is done or that tie to other code:
- The file header that describes the picker.
- The `--!strict` and selene directives.
- The note that the colors follow UI spec section 2.3.
- The two notes about `PlacementController` reading the `SelectedBlock` attribute.
- Why the button uses `Activated` instead of `MouseButton1Click`.
- Why `gameProcessed` input is skipped.
- That `HOTKEYS` is indexed by `BLOCK_ORDER`, and the "show the hotkey number" note.
- The gamepad TODO.

**Something to check:** there was a comment saying "Default selection is Brick", but the code is `source("Grass")`. I removed the comment and left the code alone. If the default really should be Brick, change it to `source("Brick")` at `BlockPicker.client.luau:38`.