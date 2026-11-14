I've tidied the comments in `src/StarterPlayer/StarterPlayerScripts/BlockPicker.client.luau`. Only comments and the blank lines around them changed. I couldn't run the automated check that compares the code before and after, because this session can't approve commands, so I compared it against the original by eye. Nothing is committed.

**Counts:** 33 comments deleted, 3 rewritten, 5 kept unchanged.

**Deleted**
- Comments that only repeated what the next line does, like "Get services", "Import Vide", "Rounded corners" and "Return the ScreenGui".
- End-of-block labels such as `end -- if`.
- The `CHILDREN` banner inside the button's property table.
- The empty doc comment on `BlockButton`, which only repeated its parameters.
- The two old Roact lines that were commented out.
- The changelog lines in the header (the v2 and v2.1 notes); that history belongs in commit messages.
- "Colors per the UI spec, section 2.3": the colors don't need a note, and a section number goes out of date.
- "Default selection is Brick": this was wrong, since the code starts on `"Grass"`.

**Rewritten**
- The file header now uses the `--[[@description:` format, without the file name, the changelog or the em dash.
- "Hotkeys, by index into BLOCK_ORDER" is now `-- By index into BLOCK_ORDER`.
- The comment on the final `selectBlock` call is now `-- Give PlacementController a value from the start`.

**Kept unchanged**
- The note that PlacementController reads the `SelectedBlock` attribute, so the name has to stay in sync.
- Why the button uses `Activated` (it also fires for touch and gamepad).
- Why the key handler skips game-processed input (typing in chat).
- `-- show the hotkey number`, which explains why the button label is the layout order.
- The gamepad TODO, now with a blank line before `mount` so it no longer looks like it describes that line.
- The `--!strict` and selene directives, untouched.

**Close calls you may want to change**
- I deleted the note on `BLOCK_ORDER` saying it sets the picker order. The name says most of it, but the hotkey mapping also depends on that order.
- I dropped "the size of each button" and "the gap between buttons" from `BUTTON_SIZE` and `BUTTON_GAP` rather than turning them into a "pixels" note, since `fromOffset` already shows that.

**Not fixed, since this pass only touches comments**
- The file has no `@author` or `@date` lines in the header that the style guide expects. I didn't make them up.
- The file has no UI Labs story yet.