I've fixed all three HUD bugs plus one more I found. I couldn't run any checks: the session blocked my command to run StyLua, Selene and luau-lsp because it needed approval and there was no one to grant it. I also couldn't playtest, so none of this has been run.

**`PlacedBlocks.luau`**
- **Count stuck at 0:** placements were added to the existing list in place. Charm only notices a change when it gets a new table, so the count never updated. In Studio, Charm locks stored tables, which is why you saw "attempt to modify a readonly table"; live servers don't lock them, so it just failed silently. A placement now copies the list, adds the block to the copy and stores that.
- **Clear button:** it had the same problem. It now stores a new empty list.
- **Grouped updates:** placing and clearing each change two values. Both changes now go out together (`Charm.batch`), so the HUD redraws once instead of twice.

**`BuildHud.luau`**
- **"Last:" always "none":** the label read the Charm value directly, and the UI library (Vide) doesn't track Charm values, so the label only ever showed the starting value. It now goes through `useSignalState` like the count does.
- **Extra click after each H toggle:** every time the HUD was shown, it added another sound listener and never removed the old ones. The listener is now removed when the HUD hides, so there's always just one.
- **Missing click (the extra bug):** the sound was triggered by the last block type changing, so placing the same type twice in a row only clicked once. It now plays whenever the count goes up. Clear doesn't click.

The layout, text and behavior are unchanged. To check in Studio: place a few blocks, including the same type twice in a row. The count should go up each time, "Last:" should show the type, there should be one click per block, and no readonly error. Then press H a few times and place again: still one click per block. Clear should reset to 0 and "none" without a click.