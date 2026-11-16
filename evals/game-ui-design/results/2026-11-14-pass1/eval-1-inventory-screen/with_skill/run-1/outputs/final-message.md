I've built the inventory screen and written the design note. I couldn't open anything in Studio or a playtest, so nobody has seen it on screen yet. Also, three of the new files weren't type-checked (details below).

**How it works**
- **HUD button:** a "Blocks" button sits top right, below the Roblox top bar and away from the thumbstick and jump corners. It shows the block you're building with and how many you have, so players don't have to open the screen to check.
- **Opening and closing:**
  - Touch: tap the button to open; tap X or anywhere outside the panel to close.
  - Keyboard and mouse: click the button or press **B** to open; click X, click outside, or press **B** again to close.
  - Controller: **Y** opens and **B** closes.
  - Esc is left alone because Roblox uses it for its own menu.
- **The panel:** all ten blocks in a 5×2 grid, with no scrolling on any screen. Each tile shows a color swatch, the name and a count like "x48".
  - **Locked tiles** show a darkened swatch, a padlock and an "Lv 4" tag, so the state doesn't rely on color alone.
  - **The picked tile** gets a thick yellow outline and a "Picked" tag.
  - **A strip at the bottom** explains one block in short words, for example "Unlocks at level 4." or "Tap to build with it." It shows whichever block was last hovered, focused or tapped, so touch and controller players get the same information as mouse players.
- **Picking:** one tap, click or **A** picks a block, and the 1–0 number keys still work. Tapping a locked tile shakes it and the strip says which level unlocks it.
- **Controller focus:** it starts on the picked tile, can't leave the panel, and goes back to where it was when the screen closes.
- **While the screen is open:** Roblox's touch controls are hidden and block placing is off, so a tap outside the panel only closes it.
- **Player settings:** the screen follows Roblox's Reduced Motion setting (no slide or shake) and its Background Transparency setting.
- **Screen sizes:** phones get a compact layout that fits a 667×375 screen, and the UI grows on 1440p, 4K and TVs.

**Choices I made that you may want to change**
- **Number keys could pick locked blocks.** I added a lock check to the number keys in `BlockPlacer.luau`, so a locked block can't be picked either way.
- **Blocks you have none of can still be picked.** This matches how the number keys already behaved, and the strip says "Collect some!"
- **Picking keeps the screen open.** Whether it should close instead is listed in the note as a question for playtests.

**Checks**
- **luau-lsp:** no errors in the files it could read. It couldn't open `InventoryPanel.luau`, `InventoryMetrics.luau` or `BlocksButton.luau`. Their full paths in this temp folder are over Windows' path-length limit, and mapping a short drive letter needed an approval that wasn't available. Running the README's luau-lsp command from a shorter folder will cover them.
- **selene:** 0 warnings.
- **StyLua:** I formatted everything with it.
- **Not checked:** I couldn't run the UI Labs stories, a playtest, the Device Emulator or the Controller Emulator.

**What to look at in Studio**
- Open the `InventoryPanel` story in UI Labs. Try both layouts and all three inputs, and check the long-count and empty cases for text that gets cut off.
- In a playtest, check:
  - that the screen fits on a small phone;
  - that it holds up at the Largest text size;
  - that the **B** close runs before Roblox's own B leaves controller navigation.

  The docs don't say which one runs first.
- Two Roblox properties I couldn't test also drive the visuals. The hover and press look reads `GuiState`, and the outlines use `UIStroke.BorderStrokePosition`.

**Where things are**
- **UI code:** `src/StarterPlayer/StarterPlayerScripts/UI/`. `InventoryUI.luau` mounts the screen and connects it to the game, `InventoryState.luau` and `Screen.luau` hold the live state, and the view components are in `Components/`.
- **Startup:** `Main.client.luau` now calls `InventoryUI.start()` before `BlockPlacer.start()`.
- **Stories:** `src/ServerScriptService/Stories/`, which also gets a storybook module.
- **Design note:** `docs/inventory-screen.md`.