I've built the inventory screen with Vide, started it from `Main.client.luau`, and written the design note at `docs/inventory-screen.md`. StyLua and Selene pass. I haven't run it in Studio or on a device, and the type check (`rojo sourcemap` + `luau-lsp analyze`) was blocked by a permission prompt, so it hasn't been type-checked either.

**What players get**
- **Blocks button** at the bottom centre, away from the mobile thumbstick and jump button. It shows the block you're building with, how many you have ("Brick x48"), and the shortcut for your current input: a B key on PC, or the controller's Y button.
- **Inventory screen**: a dimmed backdrop and a panel showing your level, a grid of all ten blocks, and an info bar.
  - Each tile shows a colour swatch, the name and how many you have.
  - The block you're building with has a gold outline and a tick.
  - Locked blocks are covered with a padlock and "Level N", so they don't rely on colour alone.
  - The info bar explains the tile in focus, e.g. "🔒 Ice unlocks at level 4. You're level 3."
- **Sizing for phones**: tiles are at least 96×88 px, and two rows fit on a landscape phone without scrolling. On narrow or portrait screens the grid uses fewer columns and scrolls. The panel stays inside the phone's safe area.

**Controls**

| | Touch | Mouse and keyboard | Controller |
|---|---|---|---|
| Open | Tap the Blocks button | Click it, or press **B** | **Y** |
| Close | Tap ✕ or outside the panel | ✕, click outside, or **B** | **B** |
| Pick a block | Tap the tile (screen closes) | Click the tile (screen closes) | Stick or D-pad, then **A** (screen closes) |
| Locked block | Tile shakes and the info bar says which level unlocks it | Same, on click; hovering shows the info too | Same, on **A**; selecting shows the info too |

**Choices you might want to change**
- One tap picks the block and closes the screen, so kids can switch blocks and get back to building quickly.
- On a controller, the screen opens with your current block already selected, and selection can't leave the panel.
- The open/close key is B. Escape is left alone because Roblox uses it for its own menu.
- While the screen is open, clicks and taps don't place blocks; placing comes back when it closes. On PC the mouse is also freed from shift lock and first person so you can click the panel.
- Counts, locks and the level update live, and pressing number keys while the screen is open moves the gold outline.

**Gaps in the existing code (not changed)**
- **Number keys ignore locks.** In `BlockPlacer.luau` the 1–0 keys can select a locked block such as Gold. The screen refuses locked blocks, but the keys don't check `isUnlocked`.
- **Blocks with a count of 0 can still be picked**, the same as with the number keys. The server doesn't check counts either, so a player can build with blocks they don't have. I'd gate this once the server sync is written.

**Things to check in Studio**
- The ✓, ✕ and 🔒 symbols rely on Roblox's fallback font, so check they display on Xbox.
- On a controller, B should close the screen rather than just clearing the selection. If Roblox handles B first, the screen still closes, but check it.

The UI files are in `src/StarterPlayer/StarterPlayerScripts/UI/`: `InventoryUI.luau` (wiring and controls), `InventoryState.luau`, `Theme.luau`, `Format.luau`, and the `Components/` folder (`InventoryButton`, `InventoryScreen`, `BlockTile`).