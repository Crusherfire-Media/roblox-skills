I've reskinned the hotbar to match the design and written `docs/figma/hotbar-notes.md`. Type check (luau-lsp) and StyLua pass with no errors. Selene printed nothing, but my command to confirm its exit code was blocked by permissions, so I haven't confirmed it ran clean. Nothing has run in Studio or UI Labs, and with no screenshot I couldn't compare it to the design by eye.

**What changed**
- **`UI/Theme.luau`** (new): the colors and sizes from the design, kept in one place.
- **`UI/HotbarSlot.luau`** (new): one slot, matching the design's slot component. It has the dark rounded tile, the colored swatch, a round badge with the number key, and an orange-yellow gradient outline when selected. It also has the hover and pressed looks from the design. The pressed slot shrinks from 64 to 60 around its center, so the slots next to it don't move.
- **`UI/Hotbar.luau`**: restyled to the design's sizes and spacing (a 732×84 bar, 24 px from the bottom, the block name 8 px above it). The bar is 80% opaque and has a faint line along its top edge.
- **Stories** in `src/ServerScriptService/Stories/` for previewing in UI Labs: `UI/Hotbar.story` (click slots to select) and `UI/HotbarSlot.story`. You can switch the block, key, key badge and selected state live.

**Selection still works the same way.** Clicking or tapping a slot still calls `BlockPlacer.setBlockType`, and the number keys still go through `BlockPlacer`. I didn't touch `BlockPlacer` or `Main.client.luau`.

**What Roblox can't reproduce exactly** (details in the notes):
- **Font:** the design uses Gilroy ExtraBold, which Roblox doesn't ship. I used Montserrat ExtraBold, so names come out a little wider.
- **Letter spacing:** the design has -0.5 on the block name. Roblox has no letter spacing, so I left it out.
- **Outline on the block name:** Roblox has no inside/outside setting for text outlines, so its thickness may look slightly different.
- **80% opacity on the whole bar:** Roblox can't fade a group of frames together, so each layer is faded on its own. Where layers overlap, less of the game world shows through than in Figma. The exact alternative would redraw the whole bar on every hover or selection change.
- **Line on the top edge only:** Roblox outlines can't be set per side. I used a full outline that fades out below the top edge.
- **Smoothed slot corners:** these became plain rounded corners.

**Please review:**
- **Missing states:** the design doesn't show selected-and-hovered or selected-and-pressed. I gave those the hover or pressed look and kept the gradient outline.
- **Gamepad:** gamepad focus still uses Roblox's default highlight.
- **Phones:** the new bar is 732 px wide (the old one was 630). On phones that's most of the screen and it can sit under the jump button. A phone layout needs its own frame from the designer.

**What to check:**
1. In UI Labs, open `UI/Hotbar` and `UI/HotbarSlot`.
2. Hover and press a slot.
3. Select a few slots and watch the gradient outline.
4. In a playtest, press keys 1–0 and confirm the selection follows.

The notes list each element's expected position and size at 1920×1080 if you want to measure them.

Nothing is committed.