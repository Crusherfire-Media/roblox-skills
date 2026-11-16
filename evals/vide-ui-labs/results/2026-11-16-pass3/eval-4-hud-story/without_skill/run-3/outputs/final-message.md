I've added the story. I couldn't test it: shell commands needed approval and this session can't grant it, so I couldn't run luau-lsp, selene, stylua or rojo. Nothing has been run in Studio either, so please open it in UI Labs to confirm.

**What changed**

To render the HUD without the in-game effects, I split it into two parts:

- **`src/StarterPlayer/StarterPlayerScripts/BuildModeHudView.luau`** (new): just the panel, moved over unchanged. It takes the player name, selected block and placed count as reactive props. It doesn't blur, change the camera, play a sound, create instances outside its own frame or wait on remotes, so the story can render it safely.
- **`BuildModeHud.luau`**: still the function `Main.client.luau` passes to `show(isBuildMode, BuildModeHud)`, so `Main.client.luau` is untouched. It keeps all its game behaviour: listening for block selection changes, counting `BlockPlaced` events, the blur, the field-of-view zoom with restore on close, and the open sound. It now hands that state to the view instead of building the frames itself.
- **`src/ServerScriptService/Stories/BuildModeHud.story.luau`**: a Vide story with three controls:
  - **`SelectedBlock`**: a dropdown of every block in `BlockTypes.List`, so new block types appear automatically.
  - **`PlayerName`**: free text for trying long names. The `" is building"` text is added after it, and the label already cuts off with "…" when it runs out of room.
  - **`PlacedCount`**: a number, minimum 0, step 1. I set the drag sensitivity explicitly because the UI Labs default is the starting value × 10, which is 0 here and would make dragging do nothing.
- **`src/ServerScriptService/Stories/Stories.storybook.luau`**: puts the story under a "Build Mode" group in UI Labs. Without it, the story would show up under "Unknown Stories".

**Why it leaves your place and camera alone**

The story only loads the view, `BlockTypes`, Vide and UILabs. It never loads `BuildModeHud`, which is the only module that touches Lighting, the camera or sounds. UI Labs parents the panel to its own preview frame, and it's removed when the story closes. Nothing on the server loads modules from `ServerScriptService` automatically, so the story files have no effect during play.