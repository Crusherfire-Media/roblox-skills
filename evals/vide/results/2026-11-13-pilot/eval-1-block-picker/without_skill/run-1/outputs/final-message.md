I added a Vide hotbar. It shows the five block types, highlights the selected one, selects a block when you click or tap it, and stays in sync when you switch with the number keys. I haven't run it in Studio, so I haven't seen it on screen or tried it on a phone. The project's checks all pass: luau-lsp analyze, selene and stylua.

**New file: `src/StarterPlayer/StarterPlayerScripts/Hotbar.luau`**
- Each slot shows a colour swatch for the block (Window is see-through, matching its transparency), the block's name, and its number key. The number only appears on devices with a keyboard.
- **Highlight:** the selected slot gets a thicker gold outline and a lighter background.
- **Selecting:** clicking or tapping a slot calls `BlockPlacer.setBlockType`.
- **Staying in sync:** the hotbar doesn't keep its own idea of which block is selected. It reads `BlockPlacer.getBlockType()` when it starts and then listens to `BlockPlacer.BlockTypeChanged`. So the number keys, or anything else that calls `setBlockType`, update the highlight too.
- **Phones:**
  - Slots scale with the screen: 13% of the screen's shorter side, between 44 and 68 px, so they never get smaller than a comfortable tap target.
  - The bar sits at the bottom centre, clear of the thumbstick and jump button, and uses `DeviceSafeInsets` to stay away from notches.
  - Tapping a slot doesn't also place a block in the world behind it. Roblox already marks taps and clicks on buttons as handled by the UI, and BlockPlacer ignores those.

**Changed: `Main.client.luau`** now mounts the hotbar into PlayerGui before calling `BlockPlacer.start()`, because `start()` waits for the server's remote and would otherwise delay the UI. I didn't need to change `BlockPlacer`.

When you test, check that the bar doesn't overlap the jump button on a small phone in landscape. If it does, raise `BOTTOM_MARGIN` or lower `MAX_SLOT_SIZE` at the top of `Hotbar.luau`.

Nothing is committed yet.