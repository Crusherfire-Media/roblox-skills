I cleaned up the comments in `BlockPicker.client.luau`. Only comments changed. I meant to confirm that with a script that diffs the file with comments removed, but it needed permission that this session couldn't grant, so it didn't run. I copied the code over line by line, but `git diff` will show you quickly that only comment lines changed.

**What's left:** I deleted about 35 comments and kept 6, plus the file header and the `--!strict` and selene lines.

- **Header:** trimmed to a two-line summary of what the picker does. I removed the "v2 / v2.1" history lines because git already has that history.
- **Kept as they were:** the note that the `SelectedBlock` attribute name must match PlacementController, the note that `Activated` also fires for touch and gamepad, "Skip keys typed into a TextBox, such as chat", "show the hotkey number", the note on the initial `selectBlock` call, and the gamepad TODO.
- **Removed:** comments that only repeated what the code says, like "Get services", "Return the ScreenGui" and `end -- if`. I also removed the old commented-out Roact lines, the `CHILDREN` banner, and the doc comment on `BlockButton`, which only restated its parameters.

**Things to check:**
- **Possible bug:** the old comment said "Default selection is Brick", but the code is `source("Grass")`. I deleted the comment because it was wrong, but I don't know which one you meant. If it should be Brick, that's a one-word code change.
- **Spec reference removed:** "Colors per the UI spec, section 2.3" is gone. Section numbers go out of date, and the color table makes sense without it. If the colors really must match an outside spec, a comment saying that would be worth putting back.

**Judgment calls you can overrule:**
- I kept "Hotkeys, by index into BLOCK_ORDER" because it explains how the two tables line up.
- I removed the comments on `BLOCK_ORDER`, `BUTTON_SIZE` and `BUTTON_GAP` because the names already say what they are.

I haven't committed anything.