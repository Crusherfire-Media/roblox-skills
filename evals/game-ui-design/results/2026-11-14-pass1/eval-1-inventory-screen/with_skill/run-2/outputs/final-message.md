I've built the inventory screen with Vide, started it from `Main.client.luau`, and written the design note at `docs/inventory-screen.md`. Nothing has run in Studio yet: lint and formatting pass, but two of the new files never got type-checked and the layout hasn't been looked at on any device.

**How it works**
- **HUD button:** shows the colour and name of the block in use. On phones it sits on the right edge halfway down, on tablets a bit lower, and on PC and Xbox at the bottom middle. It shows a `B` key badge on keyboard and the Y button icon on a controller. It stays out of the thumbstick and jump corners and out from under the Roblox top bar.
- **Panel:** a "Blocks" title, the player's level, one status line and a close button, above a 5×2 grid with a tile for every block type. Each tile shows a colour square, the name and the count (`x48`, or `1.2K` for big numbers). Locked tiles show a padlock and `Level 6`; the block in use gets a gold border and a `Using` tag, so nothing relies on colour alone. Phones get a smaller layout that fits a 667×375 screen at about 98% size.
- **Picking:** tapping, clicking, or pressing A on a tile picks that block and closes the panel, so it's one press from opening back to building. Pressing a locked tile makes it shake and the status line says "Ice unlocks at level 4".
- **Closing:** on touch, tap the X or the dimmed area. On keyboard, press B again. On controller, press B or Y. Opening by key or controller puts focus on the block in use, and closing puts focus back where it was.
- **While open:** Roblox's touch thumbstick and jump button are hidden, and clicks in the world don't place blocks.
- **Settings:** the screen follows the player's Reduced Motion and Background Transparency settings and reacts live when they switch input type or device.

**One change outside the UI:** the number keys 1–0 in `BlockPlacer` could pick locked blocks, which the panel says you can't. They now skip locked ones.

**Not checked**
- **Type check:** luau-lsp couldn't open `Components/InventoryPanel.luau` and `Components/InventoryButton.luau`. Their full paths in this sandbox are just over Windows' path-length limit; in your normal checkout they should be fine. Every other file type-checks clean. I tried copying the project to a shorter path to check them, but that needed an approval this session couldn't give, so run the README checks once on your machine.
- **Studio:** I couldn't reach Studio, so the stories haven't been mounted and no layout has been measured. To check:
  1. Open the stories under `Stories/Inventory` in UI Labs: `InventoryPanel`, `InventoryButton`, `BlockTile`. Their controls cover locked, empty, very large counts, long names, and the phone layout.
  2. Look at a playtest in the Device Emulator on a small phone, a tablet, 1080p and Xbox, with Roblox's text size set to Largest. Long block names may get cut off with "…" there.
  3. In the Controller Emulator, check that B actually closes the panel. Roblox's own B handling might run first.
  4. Check whether arrow keys and Enter move between tiles on keyboard. If not, the number keys still work.

**Decisions you may want to change**
- **Closing after a pick:** picking closes the panel straight away. Kids may want it to stay open to compare blocks; the note lists this as a playtest question.
- **Empty blocks:** blocks with 0 count can still be picked, and the server doesn't check counts yet.
- **B key:** I chose B to open and close, so nothing else in the game should use it.
- **Bottom-middle button:** on PC and Xbox it could clash with Roblox's backpack bar if the game ever gives players tools.
- **Analytics:** the note suggests events to log, but none are added in code.

I didn't commit anything.