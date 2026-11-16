I added a block picker story with two controls. Clicking a tile in the preview selects it, as in game. I couldn't open it in UI Labs or run the story check, because this session has no connection to Studio. So far it has only passed the project's offline checks: StyLua, luau-lsp (0 errors, 0 warnings) and selene.

**What changed**
- **`BlockPicker.luau`**: the `Title` prop now accepts a string or a source (`string | () -> string`). Before, the picker read the title once, so a control couldn't change it. The game still passes `"Blocks"` and behaves the same.
- **`Stories/BlockPicker.story.luau`** (new) has two controls:
  1. **Title**: a text box you can type any title into.
  2. **Selected**: a dropdown of every block type, built from `BlockTypes.List`, so new blocks show up without editing the story.
  
  Clicking a tile selects it and prints `Selected <name>` to Output.
- **`Stories/Game.storybook.luau`** (new): the storybook. It shows the story in UI Labs under "Block Game".

**Selection behavior:** picking a block in the dropdown resets the preview to that block. After you click a different tile, picking the block the dropdown already shows does nothing, because the control didn't change. Pick a different block first.

**Long titles:** the picker's width is set by the number of tiles, about 368 px for five, so a long title gets cut off with "…". The full text can't be seen anywhere, including in game. If you'd rather long titles wrap onto more lines and the panel grow taller, I can make that change.

**What to check in Studio**
1. Open **Block Game → BlockPicker** in UI Labs. Look for errors in Output and for anything new in the Explorer outside the preview.
2. Change the Selected dropdown and check that the yellow outline moves.
3. Click tiles and check that the outline follows and Output prints the name.
4. Type a long title and decide whether "…" is acceptable.
5. Playtest once to confirm the picker and the number keys 1 to 5 still select blocks in game.

Nothing is committed.