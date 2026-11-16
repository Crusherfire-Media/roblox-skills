I've cleaned up the comments in `BlockPicker.client.luau`. I only touched comments and the blank lines around them, so the code should be byte-identical. I tried to confirm that by diffing the old and new versions with comments stripped out, but the command needed approval and this session can't grant it, so it never ran. Running `git diff` will show you the change.

**Counts:** 30 deleted, 3 rewritten, 6 kept.

**Deleted:**
- Comments that just repeated the code, like "Get services", "Import Vide", "Selects a block type", the `BlockButton` doc block, and the notes on the button size and gap constants.
- The `end -- for`, `end -- if` and `end) -- InputBegan` markers.
- The commented-out Roact `require` and `mount` lines.
- The v2 and v2.1 changelog lines in the header. Change history belongs in commit messages.
- "Colors per the UI spec, section 2.3": it pointed to a section number that can go out of date, and the colors don't need a comment.
- "Default selection is Brick": this was wrong, because the code starts on `"Grass"`.
- The `CHILDREN` banner inside the table constructor. Banners are only for the top level of a file.
- Two comments that used em dashes and only described what the code already shows.

**Rewritten:**
- File header: removed the filename and changelog, and put `--[[` and `]]` on their own lines.
- `BLOCK_ORDER`: now just "Picker order, left to right".
- `HOTKEYS`: now just "By index into BLOCK_ORDER".

**Kept:**
- The note that PlacementController reads the `SelectedBlock` attribute. It links this file to another one.
- Why the button uses `Activated` instead of `MouseButton1Click`.
- `gameProcessed` skips keys typed into chat.
- The note on setting the attribute at the start.
- `-- show the hotkey number` on the button text.
- The TODO about gamepad shoulder buttons.
- `--!strict` and the selene directive, unchanged.

**Things you might want to change:**
- **Starting block:** the old comment said the picker starts on Brick, but the code starts on Grass. I left the code alone. Change `source("Grass")` if Brick was intended.
- **Header format:** the project style guide wants a `--!strict` / `--@author` / `--@date` / `--[[@description:` header. I kept the existing summary rather than inventing author and date values.
- **Two comments I could have cut:** I kept `-- show the hotkey number` because the button's number is how players find the key to press. I kept `-- By index into BLOCK_ORDER` because the two tables have to stay in the same order. Either can go if you think the code already makes these clear.