I've written the export plan to `docs/figma/export-plan.md`. It covers all 18 visuals on the page; the designer's Note layers are skipped.

**Export scale:** `Screen.luau` scales the UI up to 2x (on 4K screens), so every image is exported at twice its 1080p size. The one exception is the logo (below). Art that the game recolors is exported in white and tinted in game.

**Sprite sheets (4):** these are split by when they show on screen, because a player only ever sees one device's prompts.

| Sheet | Contents | Sheet size | Cell size | Art size |
|---|---|---|---|---|
| HudIcons | 12 currency and stat icons, white | 288×216 | 72 | 64 |
| PromptsXbox | 8 buttons, full color | 352×176 | 88 | 80 |
| PromptsPlayStation | 8 buttons, full color | 352×176 | 88 | 80 |
| PromptsTouch | 4 gestures, white | 416×104 | 104 | 96 |

- The plan has a table for each sheet giving every piece's cell position, `ImageRectOffset` and `ImageRectSize`, plus the HUD icons' tint colors.
- Each matching Xbox and PlayStation button sits in the same cell, so switching controllers only means swapping the sheet's asset id.

**Single images:**
- **Ornate panel:** a 9-slice image, 224×224, with `SliceCenter` `Rect(96,96,128,128)`. The corner flourishes don't stretch.
- **Empty slot (dashed outline):** a 9-slice image, 192×192, white.
- **Ribbon:** a 9-slice shape, 96×96, white. Its corners have different radii, which `UICorner` can't draw. The "NEW" text stays a normal text label so it can be translated.
- **Dot grid:** one 48×48 tile, repeated every 24 pixels.
- **Other single images:** the Legendary badge (128×128; Roblox has no diamond gradient), the Glow (384×384) and one 256×256 image per item portrait. With 120+ portraits shown one at a time, a sheet doesn't make sense, and the rounded corners are added in game.

**Built from Roblox UI objects:**
- **Keyboard key prompts:** one component that takes the key's text, so rebinding a key needs no new art.
- **Profile card:** the avatar uses the player's live headshot, as the designer's note asks.
- **Glass card** and **progress bar**.

**Where it won't match the design (also listed at the end of the plan):**
- **Glass card blur:** Roblox can't blur what's behind a single frame. The plan uses a darker, more opaque fill instead.
- **Slot dashes:** because the slot size is a setting from 80 to 128, the dashes stretch from about 0.75× to 1.5× their designed length. The corners and line width stay exact. If the setting turns out to have fixed steps, exporting one image per step would keep the dashes exact.
- **Logo:** with its glow, a 2x export would be 1536×576, over Roblox's 1024-pixel limit. The plan exports it at 1024×384, which stays sharp up to 1440p and goes slightly soft on 4K. If that matters, the plan also describes exporting it as two halves instead.