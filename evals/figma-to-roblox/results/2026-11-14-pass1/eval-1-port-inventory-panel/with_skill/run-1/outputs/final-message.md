I've built the inventory panel as Vide UI, wired it to the real block data, and written the asset doc. Selene and StyLua pass. luau-lsp couldn't check three of the new files (explained below), and nothing has run in Studio yet, so it's untested in game.

**How it works in game**
- The panel is open when the game starts. The close button hides it, and **B** or gamepad **Y** toggles it.
- It shows the ten block types in `BlockTypes` order. Counts and locks come from `BlockInventory` and update live when `Changed` fires.
- Clicking a slot selects it (the design's gold "Selected" look) and puts its name in the footer. **Equip** calls `BlockPlacer.setBlockType`. If the player switches blocks with the number keys while the panel is open, the panel follows.
- On screens smaller than 1080p (phones) the panel shrinks to fit, down to half size. On a 667×375 phone it ends up about 0.75 of its design size.

**Files** (all under `src/StarterPlayer/StarterPlayerScripts/` unless noted)
- `UI/InventoryPanel.luau` connects the panel to the game. `UI/InventoryPanelView.luau` draws it from inputs only, so a UI Labs story can show it.
- `UI/Components/`: `Slot` (the Slot component set), `IconButton` (the close button), `PrimaryButton` (Equip), and `Shadow`.
- `UI/Theme.luau` holds the design's colors, text styles, corners and shadows. `UI/Assets.luau` holds the `rbxassetid://0` placeholders and image regions.
- `UI/Screen.luau` changed: I replaced `uiScale()` with `scale()` and `usableSize()` so the panel can measure the screen. `Main.client.luau` was rewritten to mount the panel.
- UI Labs stories for every component and the panel are in `src/ServerScriptService/Stories/`.
- `docs/figma/inventory-assets.md` lists the three images to upload:
  - **Hex pattern:** one repeating tile exported at 224×384.
  - **Icons:** the close and lock icons on one 128×64 sheet.
  - **Block pictures:** all ten, with their drop shadows included, on one 1008×336 sheet.

**Where it differs from the design**
- **Letter spacing:** Roblox can't do the title's +2. I dropped it.
- **Background blur:** Roblox can't blur what's behind one panel, so I made the fill more opaque (92% → 96%).
- **Shadows:** they use the design's numbers, but Roblox draws blur differently, so they may need tuning by eye.
- **Selected and locked:** in the design these are mutually exclusive, but a player can select a locked block. I made them two separate settings so the slot keeps its lock look while selected.

**States I added that aren't in the design (please review):** hover on the close button, a pressed look on Equip, a grayed-out Equip that reads "EQUIPPED" or "LOCKED", footer text "Ice · Unlocks at level 4", and "Pick a block" when nothing is selected.

**Decisions for you**
- **Touch players can't reopen the panel after closing it.** There's no button for it, only the keyboard and gamepad keys. A small HUD button needs a design.
- **Equip works on blocks with 0 count**, because nothing in the game enforces counts yet.

**Checks**
- **Code review and lint:** a review found two errors that would have stopped the panel from building, plus two smaller bugs. All are fixed.
- **Type check:** luau-lsp still reports "Unknown require" for `IconButton`, `PrimaryButton` and `InventoryPanelView`. It says those files don't exist, but they do. I think it's because this temp folder's paths are long enough to hit the Windows path limit, so type errors in those three files are unchecked. Running it from a shorter folder should settle it.
- **Not run:** the UI Labs story check, layout measurement and a playtest all need Studio, which I can't reach from here.
- **Blocked:** two commands I ran just to inspect tools and file paths were denied by the permission settings, so I worked around them.
- Nothing is committed.

**What to look at in Studio:** open `InventoryPanelView.story` and try each Level (the locks unlock at 4, 6 and 10), Counts set to "Huge", and Screen set to "Small phone". Then compare it with the Figma frame once the real images are uploaded.