I added a UI Labs story and storybook for the block picker. I couldn't run or lint anything here: shell commands need approval and none can be given in this session. **None of this has been tested in Studio or UI Labs yet.**

**What I added**
- `src/ServerScriptService/Stories/BlockPicker.story.luau` is the story itself. It loads the real `BlockPicker` module from `StarterPlayer.StarterPlayerScripts`, so the preview shows exactly what the game uses. The controls panel has three options:
  - **Selected**: a dropdown listing every block type from `BlockTypes.List`. It defaults to Brick, which is also the default in game.
  - **Title**: a text box, starting as "Blocks".
  - **LongTitle**: a toggle that swaps in a very long title so you can check truncation without typing one.
- `src/ServerScriptService/Stories/Stories.storybook.luau` is a storybook that picks up any `*.story` module in that folder, so the story appears under "Block Game" in UI Labs.

**Clicking tiles:** the story keeps its own selection value. Clicking a tile updates it, the same way it does in game, and changing the Selected dropdown overwrites it. One quirk: UI Labs doesn't let a story push values back into its controls panel. So after you click a tile, the dropdown still shows the old block, and choosing that same block again won't do anything until you pick a different one first.

**Change to the picker:** in `BlockPicker.luau`, `Title` now accepts either a plain string or a function that returns one, so the title can update live in the preview. In game, `Main.client.luau` still passes `"Blocks"`, so the game code is unchanged.

**Long titles:** the panel's width comes only from the number of tiles (about 368px for 5 blocks), so a long title gets cut off with "…" rather than widening the panel. That's how it already worked, and the story just makes it easy to see. If you'd rather the panel grow or the text wrap, that would be a change to the picker itself.

To try it, sync with Rojo, open UI Labs, and pick "Block Game → BlockPicker".