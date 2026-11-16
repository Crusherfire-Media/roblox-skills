I cleaned up the comments in `BlockPicker.client.luau`. Only comments changed; the code itself is untouched, and I haven't run or linted it.

**Removed:**
- Comments that just repeat the code, like "Get services", "Import Vide", "Update the source", "Return the ScreenGui", "the size of each button" and "don't reset on spawn".
- The "CHILDREN" banner, the doc block above `BlockButton` that repeated its parameter types, and the end-of-block labels (`-- for`, `-- if`, `-- InputBegan`).
- The two commented-out Roact lines.
- The v2/v2.1 changelog in the header. Git history already records that.
- **"Default selection is Brick"**: this was wrong, because the code starts on `"Grass"`. I didn't change the starting block. If Brick was the intended default, change `source("Grass")` to `source("Brick")`.

**Kept**, because they explain things the code alone doesn't:
- The file header describing what the picker does.
- The `selene` directive.
- The note that the colors come from the UI spec, section 2.3.
- The note that HOTKEYS are matched by index to BLOCK_ORDER.
- The `PlacementController` attribute notes, both the one about keeping the name in sync and the initial-value call.
- Why it uses `Activated` rather than `MouseButton1Click`.
- That the white outline only shows on the selected button.
- Why `gameProcessed` input is skipped.
- The gamepad TODO, which I moved off the `mount` line into its own spot.