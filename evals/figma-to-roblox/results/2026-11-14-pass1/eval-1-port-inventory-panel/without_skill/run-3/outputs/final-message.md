I've built the inventory panel as Vide UI, opened it from `Main.client.luau`, and written `docs/figma/inventory-assets.md`. The type checker, selene and stylua all pass. Nothing has run in Studio, so I haven't seen it on screen, and I haven't committed anything.

**Files**
- `UI/InventoryPanel.luau`: the panel, built at the Figma sizes (720 × 380, centred). It has the header, the slot grid, and the footer with the selected block's name and the Equip button.
- `UI/InventorySlot.luau`: the Slot component with its Default, Selected and Locked states, using the real counts and unlock levels from `BlockInventory`. It updates when `BlockInventory.Changed` fires.
- `UI/InventoryStyle.luau`: the Figma colours and Builder Sans fonts, the placeholder asset ids (`rbxassetid://0`), and two small helpers for text shadows and icons.
- `UI/Screen.luau`: I split out `scaleFor()` and `viewportSize()` so the panel can reuse them. `uiScale()` behaves the same as before.

**How it behaves**
- Clicking an unlocked slot selects it: the slot gets the gold highlight and its name shows in the footer. Equip then calls `BlockPlacer.setBlockType`. Locked slots can't be selected.
- Each time the panel opens, the selection starts on the block currently in use. If the number keys change the block while the panel is open, the selection follows.
- The panel starts open. The close button hides it and **E** toggles it. That key is my choice, and phones have no way to reopen the panel yet.
- I added a scale that shrinks the panel on screens too small for it. Without it, a 380 px panel doesn't fit a landscape phone, because `Screen.luau` never scales below 1.
- Until art is uploaded, each slot shows a rounded square in the block's colour and the icons show text symbols, so the panel is usable for testing now. The shadow, glow and hex pattern are simply hidden until their ids are filled in.

**Uploaded images** (the doc gives sizes and step-by-step Figma export instructions; all are exported at 2× because the UI scales up to 2× on 4K screens):
- **Panel drop shadow:** a 9-slice image stretched around the panel.
- **Hex pattern:** one tileable 112 × 192 image instead of 41 separate hexagons, clipped to the panel's rounded corners.
- **Selected-slot glow.**
- **Close and lock icons.**
- **Ten block art images,** with the drop shadow baked into the image because Roblox can't put a shadow on an image.

Everything else (gradients, strokes, rounded corners, text shadows, the button's inner shadow) is built from UI objects.

**Where it differs from the design**
- **Background blur:** Roblox can't blur what's behind a single panel, only the whole 3D view, so the panel is just the 92% fill.
- **Title letter spacing:** Roblox has no letter-spacing setting, so the title is about 16 px narrower.
- **Count text shadow:** the 2 px blur is dropped; the shadow is a hard offset copy.

**Decisions for you**
- **Highlight meaning:** Figma describes the Selected state as "the block the player builds with," but your request has a selection step before Equip. I made the gold highlight follow the clicked slot. Nothing separately marks the block in use once you click away from it; if you want that, the design needs a state for it.
- **Shadow images:** the Roblox type definitions include a `UIShadow` class, which could replace the shadow and glow images. I couldn't confirm it works in live games, so I used images.
- **Locked blocks:** the number keys in `BlockPlacer` can still choose a locked block, such as key 8 for Ice. The panel then highlights it, but Equip does nothing.

Two commands were blocked by permissions: a file listing (I used file search instead) and the stylua auto-format. I made the two formatting fixes by hand, and the formatting check now passes.