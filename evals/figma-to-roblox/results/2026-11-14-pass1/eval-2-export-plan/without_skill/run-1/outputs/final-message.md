I wrote `docs/figma/export-plan.md`. It covers all 16 visuals on the page; the `Note` layers and the page background aren't exported. No code was written.

**Build from Roblox UI objects (5):** keyboard prompts, Card / Ribbon, Profile Card, Glass Card and Progress Bar. For each one the doc lists the objects and property values: colours converted to RGB, Builder Sans weights, `UICorner`/`UIStroke` settings.

**Export from Figma (11 entries):**
- **Four sprite sheets**, grouped by when the images appear on screen:
  - HUD icons, 272×204, exported white so they can be tinted per state
  - Xbox prompts, 336×168
  - PlayStation prompts, 336×168
  - Touch prompts, 400×100

  The controller and touch prompts each get their own sheet so a player only downloads the set for their device.
- **Standalone images:** ornate panel (9-slice, 224×224), empty slot (256×256), dot-grid tile (48×48), legendary badge (128×128), logo (1024×448) and glow (200×200).
- **Item portraits:** one 256×256 file per item, not a sheet. There are 120+, more come every update, and only one shows at a time, so a sheet would mean downloading 15 unused portraits to show one.

**How the sizes work:**
- `Screen.luau` scales UI from 1x up to 2x, so images are exported at 2x the Figma size and drawn at the Figma size.
- Every image is 1024 px or smaller, because Roblox shrinks anything larger.
- Each sheet cell has 2 px of transparent space on every side, so neighbouring icons don't bleed in when the engine scales them down.
- Each sheet is laid out as a 1x Figma frame that the artist exports at 2x. The doc gives the exact `ImageRectOffset` and `ImageRectSize` for every piece.

**Where the plan departs from the design:**
- **Glass Card:** the background blur is dropped, because Roblox can't blur what's behind UI.
- **Logo:** a 2x export would be over the 1024 px limit, so it's about 1.45x and will look slightly soft on 4K screens.
- **Empty slot:** its dashed border scales with the player's slot-size setting, so the line gets a bit thinner at 80 and thicker at 128.

These three are listed under "Open questions" in the doc for the designer to sign off.

Two things I couldn't check here:
- On the keyboard prompts, Figma puts the stroke inside the 40 px key. The doc uses `UIStroke.BorderStrokePosition = Inner` for that and gives a fallback in case your Studio version doesn't have that property.
- The doc asks you to confirm in Studio's device emulator that the 2 px stroke grows with the UIScale at 4K.