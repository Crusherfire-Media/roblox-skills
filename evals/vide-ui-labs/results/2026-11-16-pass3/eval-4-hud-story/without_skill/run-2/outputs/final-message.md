I've added the story. I couldn't run or check any of it, though. This session can't approve shell commands, so Rojo, StyLua, Selene and luau-lsp were all blocked. Nothing has been opened in Studio or played in game yet.

**What I changed**

- **`src/StarterPlayer/StarterPlayerScripts/BuildModeHudView.luau`** (new): the HUD panel itself, moved out of `BuildModeHud` without changes. It takes three values (player name, selected block, placed count) and only draws them. It doesn't touch the world.
- **`src/StarterPlayer/StarterPlayerScripts/BuildModeHud.luau`**: still does everything it did before. It follows the selected block and counts `BlockPlaced` events, adds the blur, zooms the camera in and back out, and plays the open sound. Then it hands the live values to the view. It's still a function with no arguments, so `Main.client.luau` is unchanged and B shows the HUD as before.
- **`src/ServerScriptService/Stories/BuildModeHud.story.luau`** (new): a UI Labs Vide story that loads only the view. Its controls are:
  - `SelectedBlock`: a dropdown of the block types in `BlockTypes`.
  - `PlayerName`: a text box, set to "Builder" to start. Type in long names to check how the panel cuts them off.
  - `PlacedCount`: a whole number, 0 or higher.
- **`src/ServerScriptService/Stories/Game.storybook.luau`** (new): a small storybook so the story is listed under "Game" in UI Labs.

**Why opening the story doesn't affect your place or camera**

The story never loads `BuildModeHud` or `BlockPlacer`. Because of that, opening it can't:
- add a blur to Lighting
- change the Studio camera's field of view
- create or play the sound
- wait on the `BlockPlaced` remote, which doesn't exist in edit mode

Everything the story creates is under the UI Labs preview area, and UI Labs deletes it when you close the story. Both story files are plain modules, so they won't run in a live game.