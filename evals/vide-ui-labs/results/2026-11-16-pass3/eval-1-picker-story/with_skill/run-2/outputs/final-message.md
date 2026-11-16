I added a UI Labs story for the block picker. It passes the type check, lint and format check, but I haven't seen it run: I have no connection to Studio, so I couldn't mount it in UI Labs or run the story check that catches errors there.

**What changed**
- **`src/ServerScriptService/Stories/GameUI.storybook.luau`** (new): the storybook, so UI Labs finds stories in this folder. It shows up as "Game UI".
- **`src/ServerScriptService/Stories/BlockPicker.story.luau`** (new): the picker story. The controls panel has two controls:
  - **Title**: a text box, starting at "Blocks". It updates the preview as you type.
  - **Selected**: a dropdown of every block type, filled from `BlockTypes.List`, so new block types appear in it automatically.
  
  Clicking a tile in the preview selects it, as it does in game. Changing the dropdown afterwards moves the selection back to whatever you pick.
- **`BlockPicker.luau`**: one line. `Title` now accepts a live value as well as a plain string, which is what lets the Title control update the preview. The game still passes the string `"Blocks"`, so the picker works in game exactly as before.

**What to check in UI Labs** (open Game UI → BlockPicker):
1. The panel appears at the bottom of the preview with the Brick tile outlined in yellow.
2. Clicking each tile moves the yellow outline to it.
3. Choosing a block in the Selected dropdown moves the outline too, including after you've clicked a tile.
4. A long title: the panel stays the same width (it's sized to the five tiles), so a long title gets cut off with "…" at the right edge. That's how the picker already behaved. If you'd rather long titles wrap onto a second line or widen the panel, I can change that.
5. Edit the picker's source while the story is open and check it reloads without errors in the Output window.

The story is never loaded by the game itself.