I've reskinned the hotbar to match the Figma design, and the notes are in `docs/figma/hotbar-notes.md`. Clicking or tapping a slot still selects it, and the number keys still work: they're handled in `BlockPlacer`, which I didn't touch. `Hotbar`'s props are unchanged too, so `Main.client.luau` needed no edits.

**Not tested in Studio.** There was no Studio connection, so I haven't run the hotbar or its story. Formatting, the type check and the linter all pass. With no screenshot, I checked the layout by working out the sizes and positions from the code and comparing them with the boxes in the JSON. They match: the bar sits at 594, 972 and is 732 × 84, with 64px slots, 40px swatches and 18px key badges.

**Changes:**
- **`UI/Hotbar.luau`**: rewritten to the new look.
  - Dark see-through bar with a faint top edge, and the block name in bold with an outline above it.
  - Each slot has a round number badge in the corner. The selected slot gets a yellow-to-orange outline.
  - Slots change color on hover and press, and a pressed slot shrinks from 64px to 60px without moving the slots next to it.
- **`UI/Theme.luau`** (new): the design's colors, fonts and sizes in one module.
- **`ServerScriptService/Stories/`** (new): a storybook and `Hotbar.story` for the UI Labs plugin, so you can preview the hotbar in Studio without starting a playtest.

**What Roblox can't reproduce exactly** (the notes have the details):
- **Font:** Roblox doesn't have Gilroy ExtraBold, so the block name uses Montserrat ExtraBold.
- **Letter spacing:** the design's -0.5px is dropped because Roblox text has no letter-spacing setting.
- **80% opacity on the whole hotbar:** I applied it to each layer separately instead. Layers now stack, so only about 4% of the world shows through a slot instead of 20%. Roblox's `CanvasGroup` would match exactly, but it renders the always-visible HUD to a texture that goes blurry on scaled screens.
- **Top-only edge line on the rounded bar:** I used an outline around the whole bar that fades out below the corners. It looks close to Figma's taper.
- **Smoothed slot corners:** plain rounded corners instead. Hard to see at 64px.

**Please check with the designer:**
- **States the design doesn't include:** a slot that is selected and also hovered or pressed keeps its outline and takes the hover or pressed color. Gamepad focus uses the hover look. The file has no animations, so state changes are instant.
- **No phone layout:** the new bar is 732px wide (the old one was 630). That's wider than many phones held sideways, and it can sit under the touch thumbstick and jump button.

**Look at in Studio:**
- In UI Labs, open "Game UI › Hotbar". Hover, hold and click slots, then check the selected outline's colors, the edge line where it fades at the corners, and how see-through the bar looks against the backdrop.
- In a playtest, press keys 1–0 and check that the block name updates.

The new files use `--!strict`, `const` and string requires, as the style guide asks. The older files in the repo use the earlier style, and StyLua, luau-lsp and selene all accepted the new one. `Main.client.luau` doesn't turn on `Vide.strict = RunService:IsStudio()`, which the Vide guidance recommends for development; I left it alone. Nothing is committed.