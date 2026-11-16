I've added the story and split the HUD so the story can render it without the blur, zoom or sound. I couldn't test any of this: running commands needs approval and there's no way to approve here, so nothing was linted or opened in Studio.

**What changed**
- **New `src/StarterPlayer/StarterPlayerScripts/BuildModeHudView.luau`**: the HUD's panel, labels and colour swatch, moved out of `BuildModeHud.luau` unchanged. It only draws what it's given (player name, selected block, placed count). It doesn't touch Lighting, the camera, sound or remotes.
- **`BuildModeHud.luau`**: still does everything it did before, in the same order. It listens for block type changes and `BlockPlaced`, adds the `BlurEffect`, zooms the camera and puts the old field of view back when closed, and plays the open sound. Then it hands its state to the view. It's still a plain function, so `Main.client.luau` and pressing B work as before with no edits.
- **New `src/ServerScriptService/Stories/BuildModeHud.story.luau`**: a UI Labs Vide story with three controls:
  - **selected block**: a dropdown filled from `BlockTypes.List`, so new block types show up automatically.
  - **player name**: a text box (default "Builder"). Long names get cut off with "…".
  - **placed count**: a number control, minimum 0, steps of 1.
- **New `src/ServerScriptService/Stories/Game.storybook.luau`**: a small storybook so UI Labs lists the story under "Game".

**Why the story leaves your place alone:** it only loads the view module, never `BuildModeHud` or `BlockPlacer`. So it adds no blur and plays no sound, doesn't change `CurrentCamera` and doesn't wait for `BlockPlaced`. Everything it makes goes inside the UI Labs preview frame and is destroyed when you close the story.

One thing to know: the view has no default sizing or layout of its own. When you change its look, the in-game HUD and the story both update, since they share the same code.