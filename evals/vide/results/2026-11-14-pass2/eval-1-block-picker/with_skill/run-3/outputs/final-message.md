I've added the hotbar: five block slots along the bottom of the screen that highlight the selected block and select a block when clicked or tapped. I haven't run it in Studio. The type check, selene and stylua all pass, but nobody has looked at it on screen yet.

**How it works**
- **Staying in sync:** the hotbar listens to `BlockPlacer.BlockTypeChanged`, so pressing 1 to 5 moves the highlight. Clicking or tapping a slot calls `BlockPlacer.setBlockType`, and the highlight moves on that same frame.
- **Taps don't place blocks:** BlockPlacer already ignores input that the UI handles, so tapping a slot only selects it.
- **The selected slot** gets a thick white outline and a lighter background. That way the selection isn't shown by color alone. Slots also change shade when hovered and pressed.
- **Each slot** shows a color swatch from `BlockTypes` and the block's name. The number key appears in the corner, but only when keyboard and mouse is the player's main input, so phone players don't see key hints.
- **Phones** get a smaller version, with 64-unit slots instead of 80, which are still big enough for a thumb. The layout switches live if the window or device changes. On large monitors the whole UI grows with one scale, so it doesn't look tiny at 1440p or 4K.

**Changes**
- `src/StarterPlayer/StarterPlayerScripts/Hotbar.luau`: the hotbar itself. It gets its data from whoever creates it, so it can be reused or previewed later.
- `src/StarterPlayer/StarterPlayerScripts/Hud.luau`: the screen that holds the hotbar and connects it to BlockPlacer.
- `src/StarterPlayer/StarterPlayerScripts/Screen.luau`: tracks screen size and the player's main input for the layout.
- `src/StarterPlayer/StarterPlayerScripts/Main.client.luau`: now creates the HUD before starting BlockPlacer. It also turns on Vide's strict mode in Studio, which catches common Vide mistakes during development.

**What to check in a playtest**
1. Press 1 to 5 and check the highlight follows. Click slots and check you can still place blocks in the world.
2. In the Device Emulator, try a small phone (667×375). The hotbar should sit between the thumbstick and the jump button. Check that tapping a slot selects it. It shouldn't start the thumbstick, which can appear anywhere in the lower-left part of the screen; I couldn't confirm which one wins without Studio.
3. Try 1440p or 4K and check the bar grows with the screen.

**Not covered**
- **Gamepad:** there's no way to switch blocks with a controller, which wasn't in the brief. Shoulder buttons cycling through the slots would be the usual fix.
- **Previews:** the project doesn't use UI Labs, so I didn't write a preview story for the hotbar. Say if you want it set up.

Nothing is committed.