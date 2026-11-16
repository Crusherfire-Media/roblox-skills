I've built the inventory screen with Vide, started it from `Main.client.luau`, and written the design note at `docs/inventory-screen.md`. **None of it has been run or checked.** Shell commands were blocked in this session, so I couldn't run rojo sourcemap, luau-lsp, selene or stylua, or test in Studio. I checked Vide 0.4.1's source and the Roblox type definitions by hand as I wrote. On a final read-through I found and fixed one crash: the tile-size maths would have thrown on the first frame, before the grid had a size. Please run the four checks from the README and try it in Studio before relying on it.

**How it works**
- **Blocks button:** always on screen at the bottom centre, between the phone thumbstick and the jump button. It's 84 px and shows the block you're building with and how many you have left.
- **Panel:** opens over a dimmed background and stays inside the phone's safe area. At the top are "My Blocks", the player's level and a large ✕. Below that is a grid of all ten blocks.
- **Grid sizing:** the grid picks its columns and tile size from the space it has, so all ten blocks fit without scrolling on a landscape phone. On smaller screens it scrolls rather than shrinking tiles below a comfortable touch size.
- **Each tile:** shows the block's colour, name and count (or "None yet"). Locked blocks show 🔒 and "Level 4" in gold. Nothing depends on hovering, since phones can't hover. The block you're building with gets a green outline and a ✓; the tile under the mouse or controller cursor gets a white outline.
- **Picking:** choosing a usable block selects it and closes the screen, so it's one tap back to building. Locked or empty blocks stay open and show a short message in the footer, e.g. "Ice unlocks at level 4. Keep building!"
- **Controls by device:**

| | Touch | Mouse and keyboard | Controller |
|---|---|---|---|
| Open | Tap Blocks | Click Blocks or press B | Press Y |
| Close | Tap ✕ or outside the panel | ✕, click outside, or press B | Press B or Y |
| Pick | Tap a tile | Click a tile, or press 1–0 | D-pad or stick to move, A to pick |

- **Hints:** the on-screen hints switch to match the device the player last used: plain text on touch, key labels on keyboard, and Xbox or PlayStation button images on a controller.
- **Controller cursor:** it starts on the current block and can't leave the grid.
- **While the screen is open:** placing blocks is switched off, so a stray tap doesn't build behind the panel. The mouse is also freed in first person or shift lock.

**A change outside the UI folder:** I added `BlockPlacer.canBuildWith`, which allows a block only if it's unlocked and the player has at least one. The number keys now use it too. Before this, pressing 8 would select Ice even though the screen showed it as locked.

**Decisions for you:**
- **Empty blocks can't be picked.** I made blocks you have none of unpickable, like locked ones. If you'd rather allow them, change `canBuildWith` and `pick()` in `InventoryApp.luau`.
- **The server doesn't enforce any of this.** It doesn't check unlock levels or counts, and placing a block doesn't use one up, so these limits only exist on the client.
- **Escape doesn't close the screen,** because it still opens the Roblox menu.

The files are `UI/InventoryApp.luau` (state and controls), `UI/Theme.luau`, `UI/InputMode.luau`, and `UI/Components/` with `InventoryPanel`, `BlockTile`, `BlockSwatch`, `OpenButton` and `ButtonGlyph`.