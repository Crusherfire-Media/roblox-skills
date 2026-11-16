I've built the inventory screen with Vide, started it from `Main.client.luau`, and written the design note at `docs/inventory-screen.md`. StyLua, selene and luau-lsp all pass. I haven't run it in Studio, so nothing has been playtested yet, including the controller behavior. I also couldn't run the UI Labs story check or the layout measurement, since both need a live Studio session.

**How it works**
- **HUD button:** it shows the block you're building with and opens the panel. On touch it's an 80×80 button in the top right, away from the thumbstick and jump button. On PC and Xbox it's a chip at the bottom center labeled with **B** (keyboard) or the console's **Y** glyph. It moves on PC because the player list sits in the top right there.
- **Panel:** 10 tiles, each with a color swatch, name and count.
  - **Locked:** a grayed swatch, a 🔒 and "Level N".
  - **Empty:** a faded swatch and "0".
  - **Selected:** a yellow outline plus a check mark, so it doesn't rely on color alone.
  - **Details line:** one sentence about the tile you hover, focus, or tapped and couldn't pick, e.g. "Reach level 4 to unlock Ice. You're level 3." Nothing is shown only on hover.
- **Picking a block closes the panel right away**, since switching blocks is the usual reason to open it. This is a guess worth checking with players; the doc lists it as a playtest question. Tapping a locked or empty tile makes it shake and shows why in the details line.

| | Open | Pick | Close |
|---|---|---|---|
| Touch | Tap the button | Tap a tile | ×, tap the dark background, or the button again |
| Mouse and keyboard | Click, or **B** | Click, or number keys 1–0 (shown on each tile) | **B**, ×, or click the background |
| Controller | **Y** | D-pad to move, **A** to pick; focus starts on the current block | **B** or **Y** |

**Phones and other screens:** phones get a compact layout with 96 px tiles, sized to fit a 667×375 screen without shrinking. Larger screens scale the whole UI up from 1080p. While the panel is open it hides Roblox's touch controls and turns off block placing, so a tap can't place a block behind it. It also follows the player's reduced motion and background transparency settings.

**Problems outside the UI that you should know about**
- **Number keys select locked blocks:** `BlockPlacer`'s number keys still select locked or empty blocks, even though the panel refuses them. The server doesn't check level or count either.
- **No placing on controller:** `BlockPlacer` only places blocks on mouse clicks and screen taps. Controller players can pick a block but can't place it yet.
- **No button hints on phone layout:** the A Pick / B Close hints are left out of the compact layout. The doc lists this as an accessibility exception.

A review pass found three bugs, which I fixed:
- The panel closed whenever controller focus was lost, such as when the player touched the mouse. It now closes only when **B** is held.
- Tiles could still be picked during the 0.2 s closing animation.
- A tile had no size of its own outside the grid, so it drew wrong in its story.

**Before shipping, check in Studio:**
- Open the stories in UI Labs under `Game UI → Inventory`.
- In the Device Emulator, try a small phone, a tablet, 1080p and the Xbox emulator, with Roblox's text size set to Largest. Long names may be cut off with "…" at that size, but the details line shows them in full.
- In the Controller Emulator, confirm that **B** closes the panel.

I added two folders you didn't ask for:
- The stories live in `src/ServerScriptService/Stories/` with a storybook. That folder syncs into ServerScriptService but never runs.
- `UI/` also holds small shared modules: screen facts, theme, types, tile sizes, and a state bridge to `BlockInventory`/`BlockPlacer`.

The code follows the style guide's `const` and string requires. That differs from the existing `local`/`script.Parent` requires, so one new line in `Main.client.luau` doesn't match the rest of that file.