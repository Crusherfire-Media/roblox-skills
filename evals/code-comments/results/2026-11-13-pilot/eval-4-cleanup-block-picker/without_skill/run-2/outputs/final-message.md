I tidied up the comments in `BlockPicker.client.luau`. Only comments changed; the code is the same.

**Removed:**
- Comments that just repeated the code, like "Get services", "Import Vide", "Update the source" and "Return the ScreenGui".
- End-of-block markers (`-- for`, `-- if`, `-- InputBegan`) and the `CHILDREN` banner.
- The version history (v2, v2.1) in the header. Git already keeps that.
- The leftover commented-out Roact code.
- The docblock on `BlockButton`, since the type annotations already say the same thing.

**Kept:**
- The header saying what the picker does, and the selene directive.
- The pointer to the UI spec (section 2.3) for the colors.
- The note that HOTKEYS lines up with BLOCK_ORDER by index.
- The warning that PlacementController reads the `SelectedBlock` attribute, and why `selectBlock` runs at startup.
- Why the button uses `Activated` instead of `MouseButton1Click`.
- Why the hotkey handler skips input when `gameProcessed` is set.
- That the outline only shows on the selected button, and the TODO about gamepad shoulder buttons.

**Something to check:** a comment said "Default selection is Brick", but the code starts on `source("Grass")`. I deleted the wrong comment and left the code alone. If Brick is what you actually want, change it to `source("Brick")`.