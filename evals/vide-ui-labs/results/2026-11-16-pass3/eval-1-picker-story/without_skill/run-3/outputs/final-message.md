I added a UI Labs story for the block picker and a storybook to list it. The type checker, selene and stylua all pass with no errors. I haven't opened the story in UI Labs, since I can't run Studio from here.

**New files in `src/ServerScriptService/Stories`:**
- **`BlockPicker.story.luau`** is a Vide story with two controls:
  - **Title** is a text field set to "Blocks" to start. Type anything into it, including a really long title. With a long title, the picker keeps its width and cuts the text off with "…".
  - **Selected** is a dropdown of the block names in `BlockTypes.List`, so new block types will appear in it automatically.
  - **Clicking a tile in the preview** selects it, as it does in game. The dropdown can't change itself to match a click, so it may show a different block than the preview. Picking from the dropdown again takes over the selection.
- **`Stories.storybook.luau`** makes the story show up in UI Labs under "Block game".

**One change to `BlockPicker.luau`:** UI Labs sends control values to the story as live values rather than plain strings. So `Title` now accepts either a plain string or a live value (`string | () -> string`). Nothing else in the picker changed, and `Main.client.luau` still passes the plain string `"Blocks"`, so the picker works the same in game.

Regenerating the sourcemap updated `sourcemap.json` to include the two new files. Nothing is committed yet.