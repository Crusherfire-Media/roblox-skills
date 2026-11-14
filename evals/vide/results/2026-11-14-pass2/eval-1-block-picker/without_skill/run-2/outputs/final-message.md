I added the hotbar. It shows the five block types from `BlockTypes`, highlights the selected one, and clicking or tapping a slot selects that block. I haven't run it in Studio. The only checks were `selene` (0 errors, 0 warnings) and `stylua --check` (no issues), so it hasn't been tested on PC or a phone.

**New: `src/StarterPlayer/StarterPlayerScripts/Hotbar.luau`** (a Vide component)
- Each slot shows the block's colour, its name and a small number for its key (1 to 5).
- **Highlight:** the selected slot gets a white border, a darker background and a slightly bigger colour swatch, with a short animation between slots.
- **Selecting:** slots use `Activated`, which fires for both mouse clicks and taps. A slot just calls `BlockPlacer.setBlockType`.
- **Staying in sync:** the hotbar starts from `BlockPlacer.getBlockType()` and updates whenever `BlockPlacer.BlockTypeChanged` fires. Number keys and taps both go through `BlockPlacer`, so there's one source of truth. The connection is disconnected if the UI is torn down.
- **Phones:** slots resize with the screen so all five fit, but never go below 44 px, so they stay easy to tap. The bar sits at the bottom centre, clear of the thumbstick and jump button.
- **No accidental placing:** clicking or tapping a slot shouldn't also place a block behind it. `BlockPlacer` already skips clicks that the UI handled and taps that weren't in the world.

**Changed: `Main.client.luau`**
- It now mounts the hotbar into `PlayerGui` before calling `BlockPlacer.start()`, because `start()` waits for the server.
- `ResetOnSpawn` is off so the hotbar survives respawns. The script in `StarterPlayerScripts` only runs once, so the hotbar wouldn't be rebuilt if it were reset.

When you test it in Studio, check that the bar doesn't overlap the jump button on a small phone in the device emulator.