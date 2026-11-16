I've fixed all three bugs, plus two other Charm problems I found along the way. I couldn't format, lint or playtest anything: running StyLua and selene needed an approval that nobody in this session can give. I checked line lengths by hand instead, so please playtest in Studio before relying on it.

**PlacedBlocks.luau**
- **"Blocks placed" stuck at 0:** placing a block added it to the existing list in place and then stored that same list again. Charm only notices a change when it gets a different table, so nothing updated. In Studio, Charm also locks every stored table, which is why you saw "attempt to modify a readonly table"; on live servers it just fails silently. A placement now stores a copy of the list with the new block added, and Clear stores a fresh empty list.
- **"Last" and the list could disagree:** the last block placed used to be a separate value that had to be updated alongside the list. It's now worked out from the list itself (its final entry), so the two always match, and Clear resets both at once.

**BuildHud.luau**
- **"Last:" always said "none":** the label read the Charm value directly, and Vide only redraws for its own sources, so it only ever showed the starting value. It now goes through `useSignalState`, the same way the count label already did.
- **One extra click each time you toggled with H:** each time the HUD was shown it started a new listener for the click sound, and hiding the HUD never stopped the old ones. The listener is now registered with Vide's `cleanup`, so it stops when the HUD hides.
- **Missing click:** the click was tied to "last placed" changing, so placing the same block type twice in a row didn't click the second time. It now plays whenever the count goes up. Pressing Clear doesn't click, same as before.

The HUD's look and layout are unchanged. `Main.client.luau` needed no edits.

To check in a playtest:
1. Place a few blocks. The count should go up with no readonly error, "Last:" should update, and each placement should click, including the same type twice in a row.
2. Press H several times and place a block. It should click exactly once.
3. Press Clear. It should show 0 and "Last: none".

There's no UI Labs story for the HUD. Adding one would mean splitting BuildHud into a display-only part and a part that reads PlacedBlocks, which I left alone since it's outside this fix.