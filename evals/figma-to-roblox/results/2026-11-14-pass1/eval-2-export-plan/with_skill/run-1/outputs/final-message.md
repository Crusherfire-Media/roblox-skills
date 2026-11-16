I've written the export plan to `docs/figma/export-plan.md`. Every visual on the page is in it, and nothing has been committed.

**How sizes were set:** the Figma page is 1920×1080, so 1 Figma pixel is 1 Roblox pixel at 1080p. `Screen.luau` scales the UI up to at most 2×, so every image is exported at 2× its on-screen size. Sprite sheets use equal cells with a 4px transparent border around each piece, and the doc gives each piece's exact `ImageRectOffset` and `ImageRectSize`.

**Built from Roblox UI objects (nothing to export):**
- **Keyboard prompts:** plain boxes with a rounded corner, a stroke and a text label. They are not images, so new keys cost nothing.
- **Profile card:** the avatar photo in Figma is a placeholder. It becomes the player's headshot, requested at 352px so it stays sharp at 2×.
- **Glass card:** Roblox can't blur what's behind one panel, so I used a darker, more solid fill instead.
- **Progress bar:** two rounded bars, with the fill width following quest progress.
- **Text** in the ribbon and card titles stays as real text so it can be translated.

**Exported as images:**

| What | Upload |
|---|---|
| 12 HUD icons | One white sheet, 288×216, 72px cells, coloured in game; the design colours are listed |
| Xbox, PlayStation, touch prompts | Three separate sheets (a player only ever sees one device's set): 352×176, 352×176, 416×104 |
| Ornate panel | 256×256 9-slice (corners don't stretch), `SliceCenter (96,96,160,160)`, `SliceScale 0.5` |
| Ribbon (different radius on each corner) | 96×96 white 9-slice, coloured in game |
| Dot grid | 48×48 tile, repeated every 24px, `ImageTransparency 0.95` |
| Legendary badge (diamond gradient Roblox can't draw) | 128×128 |
| Glow (blurred circle) | 360×360 white, coloured in game |
| Item portraits | One 256×256 image each, square; the 12px rounding is done in Roblox |

**Decisions the artist or designer should check:**
- **Logo:** at 2× it would be 1408×512, over Roblox's 1024px limit. I split it into two 704×512 halves placed side by side. If a seam shows where they meet, the fallback is a single 1024×373 image that's slightly soft on 4K.
- **Logo and glow sizes:** the Figma file doesn't record how far the glow and blur reach, so I estimated those export frames (704×256 and 180×180). The doc asks the artist to make them bigger if the glow gets cut off.
- **Empty slot:** this is one image that scales with the slot size setting, so its dashed stroke goes from 1.67px at 80 to 2.67px at 128. A 9-slice would keep the stroke at 2px but stretch the dashes, and I judged that looked worse. Worth a quick look from the designer.
- **Dot grid at larger screens:** I'm not sure the tile spacing grows with the UI scale. The checks after upload include confirming this.

I couldn't run a script to parse the Figma JSON (the permission was denied), so I read the file directly instead.