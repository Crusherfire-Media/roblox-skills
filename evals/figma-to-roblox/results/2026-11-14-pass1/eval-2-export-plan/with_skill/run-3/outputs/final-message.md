I wrote the export plan to `docs/figma/export-plan.md`. It covers every visual on the HUD Kit page and says for each whether we build it from Roblox UI objects or export it as an image. No code was written.

**How images are sized:** the page is 1920×1080, so Figma pixels equal our 1080p sizes. `Screen.luau` scales the UI up to 2x on 4K, so every image is exported at 2x its Figma size.

**Sprite sheets.** Pieces are grouped by when they appear on screen. Each piece sits in a regular grid cell with a 4 px transparent margin, and the plan gives every piece's offset and size on its sheet:

| Sheet | Size | Cell | What's on it |
|---|---|---|---|
| `HudIcons` | 288×216 | 72 | The 12 currency/stat icons, exported in white and colored in game. The designer's colors are listed. |
| `PromptsXbox` | 352×176 | 88 | 8 buttons in their own colors |
| `PromptsPlayStation` | 352×176 | 88 | 8 buttons in their own colors |
| `PromptsTouch` | 208×208 | 104 | 4 gestures, in white |

**Stretchable images (9-slice):**
- **Ornate panel:** 224×224. The corner flourishes keep their size from 240×160 up to 960×640.
- **Empty slot:** 192×192. Roblox can't draw dashed outlines, so this one is an image.
- **Ribbon shape:** 96×96, exported in white. It has a different corner radius on each corner, which Roblox can't round natively.

**Pattern:** the dot grid is one 48×48 tile, repeated every 24 px and drawn at 95% transparency.

**Single images:**
- **Legendary badge:** 128×128. Its diamond gradient has no Roblox equivalent.
- **Glow:** 360×360, exported in white.
- **Item portraits:** 256×256 each, uploaded one per image, with the rounded corners added in game. A sheet would load all 120 portraits to show one, and would need re-uploading every update.
- **Logo:** the glow pushes it to 1408×512 at 2x, which is over Roblox's 1024 px limit. It's split into two 704×512 halves.

**Built from Roblox UI objects:**
- the keyboard keys (any new key binding needs no new art)
- the "NEW" ribbon text
- the profile card, where the avatar is the player's own headshot, not the placeholder photo
- the glass card
- the progress bar

The plan also covers alpha bleed (removing the dark fringe Roblox adds around soft edges), where to keep the exported files, and what to check after upload at 1080p, at 4K and on a real phone.

**Four things need the designer's sign-off:**
1. **Slot dashes stretch.** The slot resizes from 80 to 128 px, so the dashes along each side end up about 0.8x to 1.4x their designed length. The corner radius and 2 px stroke stay exact.
2. **The glass card's blur can't be reproduced.** Roblox can't blur what's behind one frame, so I used a darker, more opaque fill instead. The color I picked is a starting value for the designer to approve.
3. **The logo split.** Two halves keep it sharp on 4K. The alternative is one 1024-wide image that looks slightly soft on 4K.
4. **Xbox bumper and trigger shapes.** The design draws them as circles, unlike the real controller's shapes.