I've reskinned the hotbar to match the Figma design and written the notes in `docs/figma/hotbar-notes.md`. The type check, selene and stylua all pass (stylua reformatted one long line). I haven't run it in Studio, and with no screenshot nobody has compared the result to the Figma frame by eye.

**What changed in `Hotbar.luau`:**
- **Sizes and colors** now follow the design: a 732×84 bar with 10 px padding, 8 px gaps and corner radius 14, sitting 24 px from the bottom of the screen. Slots are 64×64 with radius 12, swatches 40×40 with radius 8, and each slot has a round 18 px badge for its number key.
- **Selected slot:** a 3 px orange-gold gradient outline.
- **Hover and Pressed states** use the design's fills. A pressed slot shrinks to 60 px, with a 36 px swatch, around its center. Each slot keeps a fixed 64×64 click area, so the row doesn't shift when you press one.
- **Bar opacity:** the 80% opacity applies to the whole bar at once, so the bar doesn't show through the slots.
- **Block name** above the bar has a 2 px dark outline.

**How it works:** the hotbar's inputs and outputs are unchanged, so `Main.client.luau` needed no edits. Clicking or tapping a slot still selects it. The number keys never lived in the hotbar; `BlockPlacer.luau` handles them, and the hotbar just shows the new selection.

**What Roblox can't match exactly** (each has its substitute in the notes):
- **Font:** Gilroy ExtraBold isn't available, so the name uses Builder Sans ExtraBold.
- **Letter spacing:** Roblox has no setting for the −0.5 px spacing, so text runs about 2 px wider.
- **Corners:** the design's smoothed corners become plain rounded corners.
- **Top edge of the bar:** the design has an outline on the top side only, which Roblox can't draw. I used a thin 2 px line along the top instead.
- **Name outline:** you can't choose where an outline sits on text, so its position may differ slightly from the design.

**Questions for the designer:**
- **Selected plus hover or pressed:** the design shows each state on its own, but in the game a slot can be selected and hovered at once. I applied the pointer state's fill and kept the gold outline on top. Should those combinations get their own variants?
- **Bar opacity:** this is the one place I chose accuracy over performance. The approach costs some memory and can look slightly soft on low-end devices. If that's a problem, the fallback is in the notes.

My first shell command to list the files was blocked by the permission system, so I used the file-search tools instead; nothing was skipped. I haven't committed anything.