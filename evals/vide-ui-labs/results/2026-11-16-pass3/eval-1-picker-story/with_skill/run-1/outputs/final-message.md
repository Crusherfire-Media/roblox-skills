The block picker story is written. luau-lsp, selene and stylua all pass on the project. I couldn't open Studio from this session, so nobody has mounted the story in UI Labs yet. The first time you open it is the first real run.

**What changed**

- **`src/ServerScriptService/Stories/GameUI.storybook.luau`** (new): the storybook that points UI Labs at the `Stories` folder. It shows up as "Game UI".
- **`src/ServerScriptService/Stories/BlockPicker.story.luau`** (new): the picker story. Its controls panel has three entries:
  1. **Block**: a dropdown of every block type, built from `BlockTypes.List`, so new blocks show up without editing the story.
  2. **Title**: free text, starting as "Blocks".
  3. **UseLongTitle**: shows a sample title wider than the panel, so you don't have to type one to test that case.

  Clicking a tile selects it the way it does in game, and prints `Selected <name>` to Output. The selection is kept inside the story, so both the dropdown and tile clicks can change it. Changing the dropdown after a click jumps the selection back to the dropdown's choice.
- **`BlockPicker.luau`**: `Title` now accepts either fixed text or a live value (`string | () -> string`). Before, the picker read the title once, so editing it in the controls panel wouldn't have updated the preview. The game passes plain text, so `Main.client.luau` is unchanged and the in-game picker works as before.

**What to check in UI Labs**

- **Game UI → BlockPicker**: the panel sits at the bottom centre of the preview, the way it does on screen.
- Change **Block**, then click tiles: only one tile should have the yellow outline at a time.
- Edit **Title** and turn on **UseLongTitle**: a long title is cut off with "…" at the panel's edge, because the title label was already set up that way. If you'd rather it wrap onto a second line or make the panel wider, that's a small change to the picker.
- Edit `BlockPicker.luau` while the story is open: the preview should reload with your change.

Nothing is committed.