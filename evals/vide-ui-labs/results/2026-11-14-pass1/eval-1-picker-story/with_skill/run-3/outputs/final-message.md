I added a UI Labs story for the block picker. I couldn't open Studio from here, so I haven't mounted the story or run the check that looks for errors and leftover instances. The type check, lint and format check all pass.

**What changed**
- **`src/StarterPlayer/StarterPlayerScripts/BlockPicker.luau`**: `Title` now accepts either a fixed string or a live value (`string | () -> string`). That's the only change. The game still passes `"Blocks"`, so `Main.client.luau` works as before.
- **`src/ServerScriptService/Stories/Game.storybook.luau`** (new): a storybook named "Game UI" that covers the `Stories` folder.
- **`src/ServerScriptService/Stories/BlockPicker.story.luau`** (new): the story, with two controls:
  1. **Selected**: a dropdown of every block in `BlockTypes.List`, so it updates when you add blocks.
  2. **Title**: a text box that starts as "Blocks". Paste in anything to try a long title.

Clicking a tile in the preview selects it and prints `Selected <name>` to Output, the same way the game uses it. Choosing a block from the dropdown rebuilds the picker with that block selected. One thing that may look odd: the dropdown doesn't follow your clicks. If you click Dirt while the dropdown still says Brick, picking Brick again does nothing because the value didn't change. Pick another block first, then Brick.

**What to check in UI Labs** (open Game UI → BlockPicker)
- The picker sits at the bottom center with all five tiles, and the selected tile has the yellow outline.
- Clicking each tile moves the outline and prints to Output.
- With a very long title, the panel stays as wide as the row of tiles and the title is cut off with "…". That's how the picker already handled long titles, and I didn't change it. If you'd rather the panel widen or the title wrap onto a second line, that's a small change I can make.
- Nothing new appears in the Explorer outside the preview while the story is open.

Nothing is committed yet.