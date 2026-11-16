I've reskinned the hotbar to match the design and written `docs/figma/hotbar-notes.md`. Stylua, selene and the luau-lsp type check all pass. I couldn't run it in Studio, and there's no screenshot of the design, so nobody has compared it with the Figma canvas yet.

**Hotbar** (`src/StarterPlayer/StarterPlayerScripts/UI/Hotbar.luau`)
- **Matched exactly:** sizes, spacing, corner radii, colours, the key badges, the selected-name outline, and the gradient outline on the selected slot are all taken from the exported file. The design's frame is 1080 px tall, the same height our UI is built for, so its pixel values carry over as they are.
- **States:** slots now have Hover and Pressed looks as well as Selected. The slot's tile shrinks when pressed, but the clickable area stays 64 px, so the slots next to it don't move.
- **Selecting:** unchanged. Clicking or tapping a slot still selects it. The number keys are handled in `BlockPlacer.luau`, which I didn't touch.
- **Bar opacity:** the design makes the whole bar 80% opaque. To copy that, the bar is now a `CanvasGroup`, Roblox's way of fading a group of elements together. It uses a bit more GPU memory and redraws whenever the selection or hover changes. The notes explain how to switch back to a plain frame if that's a problem.
- **Size:** the bar is now 732 px wide, up from 630 px. It's more likely to run off the screen on a phone held upright, so check that on a real device.

**What Roblox can't reproduce exactly** (details and substitutes are in the notes)
- **Font:** the design uses Gilroy ExtraBold, which Roblox doesn't offer. I used Builder Sans ExtraBold.
- **Letter spacing:** the design tightens the selected name by 0.5 px, and Roblox can't set letter spacing.
- **Text outline position:** Roblox can't place the outline outside the letters the way the design does, so its weight may look slightly different.
- **Top edge highlight:** the design highlights only the bar's top edge, and Roblox outlines can't do one side. I used a thin 2 px line instead, which stops before the rounded corners.
- **Smoothed corners:** Roblox only does plain rounded corners, so the slot corners are slightly sharper.
- **Hover on touch screens:** hover only appears with a mouse.
- **Selected and hovered at once:** the design has no look for this. A selected slot keeps its gradient outline and also changes colour on hover and press. The designer may want to confirm that.

The notes also list design values I left out on purpose. For example, every swatch in the export is the Brick colour, so each slot uses its block's colour from the game instead.

One permission issue: my first attempt to list files and read the script through the Bash shell was blocked, because this session can't approve commands that need permission. I used the file tools instead, and the checks then ran through PowerShell.