I've added the story, but I haven't seen it render. Static checks pass: `luau-lsp analyze`, `selene` and `stylua --check` all report nothing. But I have no Studio connection here, so I couldn't run the story check, mount it in UI Labs, or measure the layout.

**How it works:** the story can't safely load the existing `BuildModeHud`, because building it adds a blur to Lighting, changes the camera's field of view, plays a sound, and waits on a remote. So I split it in two:

- **`StarterPlayerScripts/BuildModeHudView.luau`** (new): just the panel. It gets the player name, block name and placed count passed in, and touches nothing outside its own frame. This is what the story renders.
- **`StarterPlayerScripts/BuildModeHud.luau`**: the in-game version. It still does everything it did before: follows `BlockPlacer.BlockTypeChanged`, counts `BlockPlaced` events, adds the blur, zooms the camera and puts it back, and plays the open sound. It now hands those values to the view. It returns the same frame, so `Main.client.luau` is unchanged and B still opens it.
- **`ServerScriptService/Stories/GameUI.storybook.luau`** (new): the storybook for this folder.
- **`ServerScriptService/Stories/BuildModeHud.story.luau`** (new): the story. It only loads the panel, Vide, UI Labs and `BlockTypes`, so opening it leaves nothing in your place and doesn't touch your Studio camera.

**Controls**, in this order:
1. **SelectedBlock**: a dropdown filled from `BlockTypes.List`, so new block types show up on their own.
2. **PlayerName**: free text, starting at "Builder".
3. **PlacedCount**: a number from 0 to 99999.

**What to check in UI Labs** (Game UI → BuildModeHud):
- **Long names:** the name line is about 220 px wide in 18 px bold and cuts off with "...". A long display name (they can be up to 20 characters) will probably push "is building" off the end. Try a 20-character name to see.
- **Block colors:** each block's color swatch and name should line up. Window is a pale blue that may look faint on the dark panel.
- **Large counts:** "Placed: 99999" should fit on its line.

When you first open it, check the output window for errors and Lighting for a stray `BuildBlur`. Nothing is committed yet.