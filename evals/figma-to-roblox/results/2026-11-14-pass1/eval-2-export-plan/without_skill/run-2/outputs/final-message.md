I've written `docs/figma/export-plan.md`. It covers all 16 visuals on the HUD Kit frame. Five are built from Roblox UI objects and eleven are exported as images, on 4 sprite sheets plus single images. Nothing is committed.

**Export size.** `Screen.luau` scales the UI by at most 2x and never below 1x, so images are exported at **2x their Figma size**. In Roblox, each ImageLabel's `Size` uses the Figma (1x) size. A Roblox limit also applies: images over 1024 px on either side get scaled down on upload, so everything stays within 1024.

**Sprite sheets.** Images only share a sheet when they're on screen together:
- **`HudIcons`** (288×216): the 12 icons, 72 px cells. They're exported white and coloured in Roblox with `ImageColor3`, because the designer says they're tinted per state.
- **`PromptsXbox`** and **`PromptsPlayStation`** (352×176 each): one sheet per controller, because only one controller's prompts are ever shown. Both use the same layout, so switching controllers only means changing `Image`.
- **`PromptsTouch`** (416×104).

Every cell has a 4 px transparent border so neighbouring pieces don't bleed into each other. Each piece's `ImageRectOffset` is listed in the doc.

**Single images:**
- **Panel / Ornate**: a 224×224 9-slice (`SliceCenter = Rect(96,96,128,128)`, `SliceScale = 0.5`), so the corner flourishes don't stretch. Its Note layer sits inside the frame, so the artist has to hide it before exporting.
- **Dot grid**: one 48×48 tile repeated with `ScaleType.Tile`. The 5% opacity is set in Roblox, not baked into the PNG.
- **Slot / Empty**: 256×256, sized for the largest slot setting (128) and scaled evenly. A 9-slice would stretch the dashes unevenly.
- **Badge / Legendary**: 128×128. Roblox gradients can't do the diamond gradient.
- **Glow**: about 180×180 at 1x, since it's a blur.
- **Item portraits**: one 256×256 image per item, square, with a `UICorner` added in Roblox. No sheet, because only one shows at a time and the set grows every update.

**Built from UI objects:** keyboard prompts (one component that takes the label text), the ribbon, the profile card, the glass card and the progress bar. For the profile card, the avatar uses the player's live headshot, as the designer's note says. The ribbon is rounded on only two corners, which `UICorner` can't do, so two small square frames cover the other two corners.

**Things to check:**
- **Logo**: at 2x it would be about 1400 px wide, so the plan exports it at 1024 px wide, slightly below 2x.
- **`UIStroke.BorderStrokePosition`**: I named this property for the keyboard keys' inside stroke from memory and haven't checked it in Studio. The doc gives a fallback if it's missing: shrink each key frame by 4 px.

**Questions for the designer (listed in the doc):**
- **Slot stroke**: is it OK for it to scale with slot size (about 1.7–2.7 px)?
- **Glass card**: Roblox can't blur what's behind a UI element, so it will ship without the blur. Is a more opaque fill acceptable?
- **Logo bounds**: the JSON says 640×240, but its contents only cover 640×200. Is a layer missing?