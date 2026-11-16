I've cleaned up the comments in `BlockPicker.client.luau`. Only comments changed; the code is meant to be identical. I tried to confirm that with a script that strips comments and diffs against the last commit, but this session couldn't approve it. Running `git diff` will show it: the diff should contain only comment and blank-line changes.

**Counts:** 34 deleted, 2 rewritten, 5 kept.

**What I removed:**
- Comments that just repeated the code ("Get services", "Update the source", "Return the ScreenGui", and so on).
- Comments that only marked where a block ends (`end -- if`, `end) -- InputBegan`).
- The stray `CHILDREN` banner.
- The doc comment on `BlockButton`, which only repeated its parameters.
- The v2/v2.1 changelog lines in the header. That history belongs in commit messages.
- The two old Roact lines that were commented out.
- "Colors per the UI spec, section 2.3". A section number goes out of date, and meeting a spec doesn't need a comment.

**What I kept:**
- The file header, with the changelog removed and the em dash taken out.
- `HOTKEYS`: "by index into BLOCK_ORDER", which links the two tables.
- The note that PlacementController reads this attribute, so the names must stay in sync.
- The note that `Activated` also fires for touch and gamepad, so nobody swaps it for `MouseButton1Click`.
- "Skip keys typed into a TextBox, such as chat."
- `-- show the hotkey number` on `Text = tostring(order)`. It's borderline, but without it nobody would see that the label is the hotkey.
- The gamepad TODO, as is.

**Rewritten:** the header, and the last comment, which now reads "PlacementController needs a value before the player first picks".

**Worth a look:**
- **Wrong default:** the comment said "Default selection is Brick", but the code starts on `"Grass"`. I deleted the comment rather than change the code. Tell me which one is intended.
- **Redundant setting:** `ResetOnSpawn = false` is already Vide's default for a ScreenGui, so that line could go. I left it because this pass only touched comments.