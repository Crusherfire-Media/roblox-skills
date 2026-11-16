I've cleaned up the comments in `BlockPicker.client.luau`. I meant to change only comments and blank lines, but the check that strips comments and compares the code against git was blocked by the permission system. `git diff` will show you there's no code change.

**Counts:** 30 deleted, 4 rewritten, 4 kept unchanged.

**Removed:**
- **Comments that just repeat the code:** "Get services", "Import Vide", "Rounded corners", the docblock on `BlockButton`, the `end -- if` / `end -- for` / `end) -- InputBegan` markers, and similar.
- **Version history:** the v2 and v2.1 lines in the file header. That belongs in commit messages.
- **Commented-out Roact code:** the old `require` and `mount` lines. Git still has them.
- **"Colors per the UI spec, section 2.3":** a section number goes out of date, and the colors don't need a comment.
- **"Default selection is Brick":** this was wrong. The code actually starts on `Grass`.
- **The single `CHILDREN` banner:** it was the only one in the file, so it wasn't part of a pattern.

**Kept, because they explain why:**
- PlacementController reads the `SelectedBlock` attribute, so the name has to stay in sync.
- `Activated` is used instead of `MouseButton1Click` because it also fires for touch and gamepad.
- `gameProcessed` skips keys typed into a TextBox, such as chat.
- The gamepad TODO. I moved it next to the input handler it's about.

**Rewritten:**
- **File header:** cut down to a two-line description, with `--[[` and `]]` each on their own line and no em dash.
- **`HOTKEYS`:** "Hotkeys, by index into BLOCK_ORDER" became "By index into BLOCK_ORDER". Both lists have to stay in the same order.
- **Button `Text`:** "show the hotkey number" became "the hotkey number". It explains that the layout order is also the hotkey.
- **Last call:** shortened to "So PlacementController has a value from the start".

**Judgment calls you may want to change:**
- I deleted the comment on `BLOCK_ORDER` ("the order they appear in the picker") because the name already says it.
- I deleted the comments on `BUTTON_SIZE` and `BUTTON_GAP` rather than adding "pixels" to them.

**Outside this pass, no change made:** `ResetOnSpawn = false` is already Vide's default for a ScreenGui, so that line could go.