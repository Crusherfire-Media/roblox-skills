I cleaned up the comments in `BlockPicker.client.luau`. Only comments changed; the code is the same. I haven't committed anything.

**Removed:**
- Comments that just repeat what the next line does, like "Get services", "Import Vide", "Rounded corners", "Return the ScreenGui" and "don't reset on spawn".
- End-of-block markers (`end -- if`, `end) -- InputBegan`) and the `CHILDREN` banner.
- The doc block on `BlockButton`. It only repeated the type annotations.
- The two commented-out Roact lines.
- The v2 / v2.1 changelog in the header. Git history already records that.

**Kept:**
- The header describing what the picker does.
- The pointer to the UI spec (§2.3) for the colors.
- The two notes about keeping the `SelectedBlock` attribute in sync with PlacementController.
- Why it uses `Activated` instead of `MouseButton1Click`.
- Why it checks `gameProcessed`: so typing in chat doesn't switch blocks.
- The selection-outline note and the gamepad TODO.
- I reworded the `HOTKEYS` comment to say it lines up with `BLOCK_ORDER`.

**Possible bug:** the old comment said "Default selection is Brick", but the code is `source("Grass")`. I deleted the comment and left the code alone. If Brick is the intended default, change that line to `source("Brick")`.