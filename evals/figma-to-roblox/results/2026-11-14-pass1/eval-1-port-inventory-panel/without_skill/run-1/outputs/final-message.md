I built the inventory panel as Vide UI and it now opens from `Main.client.luau`, but it hasn't been run in Studio yet. I wrote the export list in `docs/figma/inventory-assets.md`. Every asset id in the code is the placeholder `rbxassetid://0`.

**Checks:** stylua and selene pass. luau-lsp finds no errors, with one gap: it can't open `UI/InventoryAssets.luau`. In this temp folder that file's full path is just over Windows' 260-character limit, so code that uses it isn't fully type-checked. I wanted to check it under a shorter name, but renaming was blocked by permissions; it should check normally in your own copy of the repo. Rerunning the sourcemap step also updated `sourcemap.json` to include the new files.

**Files** (under `src/StarterPlayer/StarterPlayerScripts/UI/`):
- `InventoryPanel.luau`: the panel (node 12:340), 720 × 380 and centered.
- `InventorySlot.luau`: the Slot component (node 20:1) with its Default, Selected and Locked states.
- `InventoryStyle.luau`: colors, Builder Sans fonts, gradients, strokes and text shadows.
- `InventoryAssets.luau`: the placeholder ids, plus the 9-slice and tile sizes each image is drawn at.

**How it uses your data:**
- There's one slot per `BlockTypes.List` entry. Counts, locks and "Lv N" labels come from `BlockInventory` and update on `Changed`.
- Clicking an unlocked slot highlights it and puts its name in the footer. **Equip** calls `BlockPlacer.setBlockType`.
- The highlight starts on the current block type and follows it, so the number keys move it too.

**Images:** I turned six visuals into uploaded images; the doc gives sizes, 9-slice settings and Figma export steps for each:
1. The ten block pictures, with their drop shadow baked in.
2. The lock icon.
3. The close icon.
4. One repeating tile of the hexagon background pattern.
5. The panel's drop shadow.
6. The amber glow around the selected slot.

Everything else is built from UI objects: gradients, inner and outer strokes, rounded corners, the Equip button's inner shadow, and the text shadows. Until the images are uploaded, each block shows a square in its own color and the icons show text glyphs, so you can test it now.

**Things I added that aren't in the design:**
- The close button hides the panel and the **I** key toggles it. On phones there's no way to reopen it until there's a HUD button for it.
- The panel sinks clicks, so clicking it doesn't place a block behind it.

**Where it can't match Figma:**
- No background blur, because Roblox UI can't blur what's behind it.
- Text shadows are sharp, with no blur.
- The title has no +2 letter spacing, since Roblox text has no setting for it.
- The shadow shows faintly through the panel, which is 8% see-through.

**Two things to know:**
- `BlockPlacer`'s number keys can still select locked blocks. Only Equip checks locks.
- `Screen` never scales UI below 1×, so this 380-pixel-tall panel won't fit on a landscape phone.