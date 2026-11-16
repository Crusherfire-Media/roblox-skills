The block picker now has a story. I haven't been able to open it in Studio, because this session has no connection to Studio. The type check, selene and stylua all pass with no errors.

**Open in UI Labs:** **Game UI → BlockPicker**

**Changes**
- **`src/ServerScriptService/Stories/Game.storybook.luau`** (new): the storybook. It picks up every story in the `Stories` folder. The game never requires that folder.
- **`src/ServerScriptService/Stories/BlockPicker.story.luau`** (new): the story. It has two controls:
  1. **Title**: a text field, set to "Blocks" to start. Type or paste any title to try a long one.
  2. **Selected**: a dropdown of every block type, filled from `BlockTypes.List`, so new blocks show up without editing the story.

  Clicking a tile in the preview selects it, and the story prints `Selected <name>` to Output. Changing the Selected dropdown afterwards resets the selection to the block you picked.
- **`BlockPicker.luau`**: one line. `Title` now accepts either a fixed string or a live value, so the title updates as you type. The game still passes `"Blocks"` and works as before.

**What to check on screen**
- The selected tile has a thick yellow outline and the others have a thin gray one, both from the dropdown and from clicking.
- **Long titles:** the panel's width comes from the number of tiles (about 370px for five), so a long title gets cut off with "…" rather than widening the panel. That's how it already behaved in game. If you'd rather have the panel grow or the title wrap, I can change the picker.

I haven't run the story check that mounts the story and looks for errors or stray instances, since it needs Studio. The picker doesn't touch anything outside its own frame, so I expect it to pass. Opening the story in UI Labs will confirm it.

Nothing is committed yet.