I've written the export plan to `docs/figma/export-plan.md`. It covers all 16 visuals on the page; the designer's Note layers are treated as instructions, not art. It has a summary table up front and a checklist for the artist at the end.

**The main rule:** `Screen.luau` scales the UI from 1x at 1080p up to 2x at 4K, and never below 1x. So every image is exported at 2x its Figma size, and everything in Roblox is still sized at the 1x Figma size. The only exception is Glow: it's pure blur, so 1x is enough.

**Built from Roblox UI objects (no art needed):**
- **Keyboard key prompts:** Figma draws their border inside the box but Roblox draws it outside, so the frames are 4 px smaller to keep the same outer size.
- **"NEW" ribbon:** Roblox rounds all four corners or none, so two small filler squares cover the two corners that should be square.
- **Progress bar.**
- **Profile card:** the avatar isn't exported. It's the player's headshot, loaded in game, as the designer's note says.
- **Glass card:** without its background blur (see below).

**Exported images:**
- **Sprite sheets:**
  - HUD icons: 280×208, 64 px cells. They're exported white and tinted in game, and each icon's starting colour is listed.
  - Xbox and PlayStation prompts: one 344×168 sheet each. They're separate because only one is ever on screen.
  - Touch prompts: 408×96.
- **Single images:**
  - **Ornate panel:** a 224×224 image that stretches without stretching its corner decorations, as the designer asked.
  - **Empty slot:** 256×256, because Roblox can't draw dashed outlines.
  - **Dot grid:** one 48×48 tile that Roblox repeats across the screen.
  - **Legendary badge:** 128×128, because Roblox can't do its diamond-shaped gradient.
  - **Glow:** 192×192.
- **Logo:** at 2x it's wider than Roblox's 1024 px image limit. It's cut into left and right halves stacked on one 704×1024 sheet, and drawn as two images side by side.
- **Item portraits:** one 256×256 file each, not a sheet. Only one is shown at a time and more are added every update, so a sheet would make players download all of them to see one.

**Decisions for you or the designer:**
1. **Glass card blur:** Roblox can't blur what's behind a menu panel. The only substitute blurs the whole 3D view while the menu is open.
2. **Empty slot border:** the slot image is scaled evenly to keep the dashes even, so the border is about 1.7 px thick at slot size 80 and 2.7 px at 128. A fixed 2 px border would need a separate export for each slot size.
3. **Logo size:** the export file says the logo is 240 px tall, but its two parts only fill 200 px of that. The artist should check nothing hidden sits in the extra space before exporting.
4. **Missing portraits:** only 6 of the 120 portraits are on the page. The rest follow the same spec, but the artist will need the source images.

I haven't checked the plan against a real Figma export or uploaded anything to Roblox. Two Roblox details are worth confirming the first time you build: Roblox drawing borders outside the frame, and the logo's estimated size including its glow.

I also tried one shell command to list the repo files, and it was blocked because this session can't approve it. I read the same files with the file tools instead, so the plan isn't affected.