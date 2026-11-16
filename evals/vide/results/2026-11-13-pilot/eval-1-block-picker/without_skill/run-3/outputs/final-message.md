I've added a Vide hotbar. It shows the five block types from `BlockTypes`, highlights the selected one, and selects a block when you click or tap its slot. It updates when someone switches with the number keys. selene, stylua and luau-lsp all pass, but I haven't run it in Studio, so it's untested on a real phone or PC.

**Files**
- New: `src/StarterPlayer/StarterPlayerScripts/Hotbar.luau` (the hotbar).
- Changed: `Main.client.luau` now shows the hotbar before calling `BlockPlacer.start()`. That function waits for the server, so the hotbar appears straight away.

**What it does**
- **Bar:** it sits at the bottom centre. Each slot is a colour swatch with its number key (1–5) in the corner, and the selected block's name appears above the bar. The selected slot gets a thick white border and a lighter background. The Window swatch is see-through like the block.
- **Clicking or tapping a slot** calls `BlockPlacer.setBlockType`. The highlight changes immediately rather than waiting a frame for `BlockTypeChanged`, which is delayed in this project.
- **Number keys:** the hotbar listens to `BlockPlacer.BlockTypeChanged`, so switching with a number key moves the highlight.
- **Phones and PC:**
  - The bar keeps clear of notches and the home indicator.
  - On narrow screens it shrinks to at most half the screen width, so it stays away from the thumbstick and jump button. It never shrinks below 70%, so slots stay about 45px, which is big enough to tap.
  - The number labels only show when a keyboard is connected.
- **Taps don't leak into the world:** slots and the bar behind them both absorb the click or tap. Tapping a slot, or the gap between slots, won't also place a block behind the bar.
- **Respawning:** I set `ResetOnSpawn = false`. Without it, the hotbar would disappear when the player respawns, because a script creates it rather than it living in `StarterGui`.

Running the checks rewrote `sourcemap.json`, and nothing is committed.