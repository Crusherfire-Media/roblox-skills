I've reskinned the hotbar in `src/StarterPlayer/StarterPlayerScripts/UI/Hotbar.luau` and written `docs/figma/hotbar-notes.md`. None of it has been run or checked: this session couldn't run commands, so I couldn't lint, format or open it in Studio. The changes aren't committed.

**What changed**
- **Measurements:** all sizes and colours come straight from the Figma export. Slots are 64×64 with 12px corners and 8px gaps, and the bar is 732×84 with 14px corners, 10px padding and a faint white line along the top. The bar now sits 24px above the bottom of the screen (it was 16), with the block name 8px above it.
- **Slot states:** slots now have the design's hover and pressed looks. The selected slot gets the 3px yellow-to-orange gradient border.
- **Pressed slots:** the visible slot shrinks to 60×60, but each slot keeps a fixed 64×64 space so its neighbours don't shift. An invisible 64×64 button sits on top, so a press near the edge still counts after the slot shrinks.
- **Number badge:** the key number now sits in an 18px dark circle.
- **Block name:** the name above the bar now has a 2px dark outline, and its width fits the text instead of a fixed 240px.
- **80% opacity:** the design fades the whole bar, swatches included, as one layer. That needs a `CanvasGroup`, which uses extra GPU memory and can look slightly soft. The notes describe a simpler fallback, which changes the look, so check with the designer before swapping.

**Behaviour:** clicking or tapping a slot still selects that block. The number keys still work, since `BlockPlacer.luau` handles them and I didn't touch it; the hotbar just shows whatever is selected.

**What Roblox can't match** (each is in the notes with what I used instead):
- **Font:** Gilroy ExtraBold isn't available in Roblox. I used Montserrat ExtraBold, which is slightly wider; Builder Sans ExtraBold is the other option if you want it to match the rest of the UI.
- **Letter spacing:** Roblox has no setting for the design's −0.5px letter spacing.
- **Top line:** Roblox can't put a border on just one side, so the bar's top line is a thin strip. It's cut off where the corners start rather than curving down into them.
- **Corner shape:** Roblox only draws round corners, not Figma's smoothed ones.
- **Gradient border:** it's stretched about 3px wider than in Figma, which isn't visible at this size.

**Decisions to confirm with the designer**
- The design doesn't show a selected slot being hovered or pressed. I kept the gradient border and still let the slot darken and shrink.
- On touch screens there's no hover, so slots only show the pressed look.

**To check in Studio:**
- **Hover and pressed looks:** they depend on a Roblox property (`GuiState`) sending change notifications. I believe it does but couldn't test it; if it doesn't, slots will never show those looks.
- **Gradient border:** confirm it fits inside the faded bar without being clipped.