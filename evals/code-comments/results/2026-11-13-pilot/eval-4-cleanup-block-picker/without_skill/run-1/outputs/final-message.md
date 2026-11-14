I've tidied the comments in `BlockPicker.client.luau`. Only comments changed; the code is exactly the same.

**What I removed:**
- Comments that just repeated the next line of code ("Get services", "Import Vide", "Get the local player", "Update the source", "Return the ScreenGui", "don't reset on spawn", and so on).
- The `v2` / `v2.1` version history in the header. Git already tracks that.
- The commented-out Roact `require` and `Roact.mount` lines left over from the migration.
- The doc block on `BlockButton`, which only restated the parameter types.
- The `-- CHILDREN --` banner and the `end -- for`, `end -- if`, `end) -- InputBegan` markers at the ends of blocks.

**What I kept:**
- The file header describing what the picker does, and the `selene` directive.
- The pointer to the UI spec (section 2.3) for the colors.
- The note that `PlacementController` reads the `SelectedBlock` attribute, so the name has to stay in sync.
- Why it uses `Activated` instead of `MouseButton1Click`: `Activated` also fires for touch and gamepad.
- The note that the white outline only shows on the selected button.
- Why `gameProcessed` input is skipped: so typing in chat doesn't change the block.
- Why the attribute is set when the script starts.
- The gamepad TODO.

I also reworded the `HOTKEYS` comment to say it lines up index-for-index with `BLOCK_ORDER`.

**Worth a look:** the old comment said "Default selection is Brick", but the code is `source("Grass")`. I deleted the wrong comment and left the code alone. If Brick is the intended default, the code needs changing.