I've reskinned the hotbar to match the Figma design and written `docs/figma/hotbar-notes.md`. The code passes the project's type checker, linter (selene) and formatter (StyLua). I couldn't run it in Studio and had no screenshot of the design, so nobody has seen it on screen yet.

**What changed** (all under `src/StarterPlayer/StarterPlayerScripts/UI/`)
- **`Theme.luau`** (new): every color, font, corner radius and outline width from the design, in one place.
- **`HotbarSlot.luau`** (new): the slot from the Figma component, with all four looks: default, hover, pressed and selected (the orange-to-yellow outline). Hover and press follow the mouse or finger. When pressed, the slot shrinks from 64 to 60 px inside its own space, so the other slots don't shift.
- **`Hotbar.luau`**: rebuilt from those slots, with sizes and positions taken from the design. The bar is 732×84, 24 px from the bottom, with the block name 8 px above it.
- **Selection still works the same way:** clicking or tapping a slot selects it. The number keys are handled in `BlockPlacer.luau`, which I didn't change. Nothing in `Main.client.luau` changed either.
- **Previews** (new): `src/ServerScriptService/Stories/` has UI Labs previews for the slot and the full hotbar, so you can check each look in Studio without playtesting. They haven't been opened in Studio yet.

**What Roblox can't match exactly** (each is explained in the notes)
- **Font:** the design uses Gilroy ExtraBold, which Roblox doesn't have, so I used Montserrat ExtraBold.
- **Letter spacing:** the -0.5 spacing on the block name is dropped, because Roblox text has no letter spacing.
- **Rounded corners:** Figma's smoothed corners became plain rounded corners.
- **Top highlight:** Roblox can't outline only one side, so the bar's top highlight is a thin line that stops where the corners start to curve.
- **80% see-through bar:** I applied the 80% to each part separately, which makes the slots noticeably less see-through than in Figma. Over a bright sky they come out up to about 30 color steps darker. Wrapping the bar in a `CanvasGroup` would match Figma exactly; the notes say how.

**Not shown in the design, so I made a call**
- A selected slot that's also hovered or pressed keeps its outline.
- State changes are instant, because the design has no animation.
- Window and Ice swatches stay solid even though those blocks are see-through in the game.

**Phones:** at 732 px wide the bar overlaps the thumbstick and jump button on phones held sideways. The old bar did too. Fixing it needs a phone version of the design.

Nothing is committed.