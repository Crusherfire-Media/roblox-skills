I tidied the comments in `BlockPicker.client.luau` and changed no code. I checked that by eye against the original. A script to confirm it (stripping comments from both versions and diffing them) needed a permission prompt this session can't show, so it didn't run.

**Counts:** about 35 comments deleted, 2 rewritten, 6 kept.

- **Deleted:**
  - Comments that just repeat what the line below does ("Get services", "Import Vide", "Selects a block type" and so on).
  - The `end -- if`, `end -- for` and `end) -- InputBegan` markers.
  - The doc comment on `BlockButton`, which only repeated its parameters.
  - The v2/v2.1 version history in the header. That belongs in commit history.
  - "Colors per the UI spec, section 2.3": a section number goes out of date, and the colors don't need a note.
  - The `CHILDREN` banner, since banners only belong at the top level of a file.
  - Both commented-out Roact lines. Git still has them.
- **Rewritten:**
  - The header is now a one-line summary, with `--[[` and `]]` each on their own line.
  - "Set the initial attribute so PlacementController has a value from the start" is now "Give PlacementController a value from the start".
- **Kept:**
  - The `--!strict` and selene lines, which are tool settings rather than comments.
  - The note that PlacementController reads the attribute, so the names must match.
  - "Activated also fires for touch and gamepad".
  - "Skip keys typed into a TextBox".
  - "Hotkeys, by index into BLOCK_ORDER".
  - "show the hotkey number".
  - The gamepad TODO, which I moved up to sit just above the input handler.

**Things to check:**
- **Starting block:** the old comment said the default was Brick, but the code starts on `"Grass"`. I deleted the wrong comment. If Brick is what you meant, the code needs changing.
- **`ResetOnSpawn = false`:** Vide already sets this by default, so that line could go. I left it because this pass was comments only.

**Your call:**
- I kept "show the hotkey number" because it explains why the button text is the layout order.
- I deleted the two size comments on `BUTTON_SIZE` and `BUTTON_GAP` because the names already say what they are.

I haven't committed anything.