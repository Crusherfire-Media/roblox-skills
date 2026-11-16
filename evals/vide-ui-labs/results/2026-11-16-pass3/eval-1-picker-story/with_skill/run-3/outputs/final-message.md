I've added the story and a storybook. I couldn't run it in Studio: this session has no way to run Luau in your edit session, so the story-mounting check and the layout measurement haven't been run. The project's own checks all pass: luau-lsp analyze, selene and stylua report nothing.

**Changes**
- `src/ServerScriptService/Stories/BlockPicker.story.luau` is the new story. The controls panel has two entries:
  - **Block** is a dropdown listing every block in `BlockTypes.List`, so new blocks show up in it automatically.
  - **Title** is a text field that starts as "Blocks".

  The selection is kept inside the story. Picking from the dropdown sets it, and clicking a tile in the preview sets it too, so the yellow outline moves the way it does in game.
- `src/ServerScriptService/Stories/BlockGame.storybook.luau` is the new storybook, so the story appears under "Block Game" in UI Labs instead of "Unknown Stories".
- `BlockPicker.luau`: the only change is that `Title` now accepts a live value as well as a plain string (`string | () -> string`). Without this, the preview would keep showing the first title even after you edit the control. `Main.client.luau` still passes `"Blocks"`, so the game works as before.

**What to check in UI Labs** (open Block Game → BlockPicker.story):
1. Five tiles appear with Brick outlined in yellow.
2. Changing **Block** moves the outline.
3. Clicking a tile moves the outline. If you then change **Block** again, the dropdown takes over.
4. Paste a long string into **Title**. The panel stays about 370 px wide, so a long title is cut off with "…" rather than wrapping or widening the panel. If you'd rather it wrapped or shrank to fit, that needs a change to the picker.
5. The Output window shows no errors, and nothing new appears in the Explorer outside the preview.

I haven't committed anything.