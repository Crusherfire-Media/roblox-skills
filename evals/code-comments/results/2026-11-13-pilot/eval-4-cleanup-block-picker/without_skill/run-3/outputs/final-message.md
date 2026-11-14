I cleaned up the comments in `BlockPicker.client.luau`. Only comments changed; the code is exactly the same. I haven't run anything, since a comment-only change doesn't affect behaviour.

**Removed:**
- The version history in the header (v2 / v2.1). Git already records that.
- The commented-out Roact code left over from the migration.
- Comments that just repeated the code below them, like "Get services", "Import Vide", "Get the local player" and "Update the source".
- The docblock on `BlockButton`, which only restated the parameter names and types.
- The `-- CHILDREN --` banner and the `end -- for` / `end -- if` / `end) -- InputBegan` markers.

**Kept, some reworded to be shorter:**
- The header saying what the picker does.
- The pointer to section 2.3 of the UI spec for the colours.
- The note that `HOTKEYS` lines up index-for-index with `BLOCK_ORDER`.
- The note that `PlacementController` reads the `SelectedBlock` attribute, so the name has to stay in sync.
- Why it uses `Activated` rather than `MouseButton1Click`.
- Why `gameProcessed` input is skipped (typing in chat).
- Why `selectBlock` is called once at startup.
- The TODO about gamepad shoulder buttons.

**Something to check:** a comment said "Default selection is Brick", but the code starts on `"Grass"` (`source("Grass")`). I removed the comment rather than guess which one is right. If Brick is supposed to be the default, the code needs changing.