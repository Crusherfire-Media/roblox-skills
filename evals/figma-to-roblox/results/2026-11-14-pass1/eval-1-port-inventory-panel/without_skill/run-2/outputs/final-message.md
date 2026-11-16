The inventory panel is built in Vide and shows when the game starts. All four checks in the README pass: type check, selene and stylua report no errors (stylua reformatted two files first). I haven't run it in Studio, so I haven't seen it on screen yet.

**Files**
- `UI/InventoryPanel.luau`: the panel itself (header, slot grid, footer).
- `UI/InventorySlot.luau`: the Slot component with its three states: Default, Selected and Locked.
- `UI/InventoryStyle.luau`: the Figma colors, Builder Sans Medium/Bold/ExtraBold, and the placeholder asset ids.
- `UI/ShadowedText.luau`: a text label with a hard drop shadow.
- `docs/figma/inventory-assets.md`: the list of images to export.
- `Main.client.luau`: mounts the panel.

**How it behaves**
- **Slots:** there is one slot for each of the ten `BlockTypes`, in order. Counts and locks come from `BlockInventory` and update when its `Changed` event fires. Locked slots show the lock icon and "Lv N", dim the art to 40%, and can't be clicked.
- **Selecting and equipping:** clicking a slot selects it and puts its name in the footer. Equip calls `BlockPlacer.setBlockType`. If the number keys change the block, the panel's selection follows.
- **Opening and closing:** the panel is open when the game starts. The close button hides it, and **E** toggles it. The design has no open button, so mobile players can't reopen it once closed. Tell me if you want a different key or the panel closed at start.
- **Respawn fix:** I set `ResetOnSpawn = false` on `GameGui`. Without it, Roblox deletes the GUI when the player respawns, and this script never runs again to rebuild it.

**Images instead of UI objects** (details in the doc):
- the panel's drop shadow (9-slice)
- the selected slot's gold glow (9-slice)
- the hexagon pattern, with the panel's rounded corners baked in
- the close and lock icons
- the ten block art images, with their drop shadow baked in

Roblox does have a shadow object (`UIShadow`), but it is still in beta and not live in games, so the shadows are images ([API docs](https://create.roblox.com/docs/reference/engine/classes/UIShadow), [release notes 717](https://devforum.roblox.com/t/release-notes-for-717/4579703)). Everything else is built from UI objects, including the Equip button's inner bottom shadow and the inside and outside strokes. The strokes use `UIStroke.BorderStrokePosition`, which is in the project's type definitions.

**Where it differs from the design**
- **Background blur:** Roblox can only blur the whole screen, not just the area behind a panel, so the blur is left out. The panel is 92% opaque, so it barely shows anyway.
- **Title letter spacing:** text labels have no letter-spacing setting, so the +2 spacing is dropped.
- **Count text shadow:** it has no blur, because Roblox can't blur text. The title's shadow has no blur in Figma either, so it matches exactly.
- **Panel height:** the height (380) is worked out from two rows of six slots. If you add an eleventh-to-thirteenth block type, it still fits in two rows; a fourteenth adds a row, and the hexagon image would need exporting again at the new height.

Nothing is committed.