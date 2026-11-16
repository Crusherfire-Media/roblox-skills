I added the story. I haven't run it in Studio or UI Labs, and I didn't run any build or type check, so please open it once to confirm.

**New files** in `src/ServerScriptService/Stories/`:
- `Stories.storybook.luau`: a storybook called "Block Game" that tells UI Labs to look for stories in this folder.
- `BlockPicker.story.luau`: the picker story. Its two controls:
  - **Title**: a text field, starting as "Blocks". Paste in something long to see how the title handles it. The title is set to cut off with "…", so expect it to be clipped at the panel's width rather than wrap or overflow.
  - **Selected**: a dropdown listing every block type from `BlockTypes.List`.

**Clicking tiles:** the story keeps its own copy of the selection, and the tile's normal click handler updates it. This is the same path the game uses, just without `BlockPlacer`.

**One limitation:** clicking a tile in the preview doesn't move the Selected dropdown, because the story can't write back to the controls panel. Picking a block in the dropdown always takes over again.

**Change to `BlockPicker.luau`:** I widened the `Title` type from `string` to `string | () -> string` so the story can change the title while it's showing. That's a type change only. Vide already accepts either form, and `Main.client.luau` still passes `"Blocks"`, so the picker should behave the same in game.

One thing tried and blocked: my first shell command to list the repo was denied by the session's permission settings, so I read the files with the file tools instead.