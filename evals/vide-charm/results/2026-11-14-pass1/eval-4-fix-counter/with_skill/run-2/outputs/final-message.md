I fixed all three problems, plus one more I found along the way, in `PlacedBlocks.luau` and `BuildHud.luau`. I couldn't run any checks: the command that runs StyLua, selene and luau-lsp was blocked, since this session can't approve tool prompts. I haven't tested it in Studio either, so it needs a playtest.

**PlacedBlocks.luau**
- **Count stuck at 0:** `onBlockPlaced` and `clear` were changing the history table in place and then setting the same table back. Charm stores tables read-only in Studio, which is the "attempt to modify a readonly table" error. On live servers the table isn't locked, but Charm sees the same table, assumes nothing changed, and tells no one. Placing a block now copies the list and sets the new copy, and `clear` sets a fresh `{}`.
- Both functions now wrap their two writes in `Charm.batch`, so the HUD updates once per change instead of twice.

**BuildHud.luau**
- **"Last:" always "none":** the label read `PlacedBlocks.getLastPlaced()` directly. Vide doesn't notice changes to Charm values, so the label kept its first value. It now goes through `VideCharm.useSignalState`, the same way the count label already did.
- **Extra click after each hide/show:** each time H showed the HUD, it started a new sound listener with `Charm.subscribe`, and hiding it never stopped the old ones. The listener is now wrapped in Vide's `cleanup`, so it stops when the HUD hides.
- **Extra fix:** the click listened for changes to the last block type, so placing the same type twice in a row stayed silent. It now listens to the count and clicks whenever the count goes up. Pressing Clear stays silent.

The HUD's layout, text and Clear button work as before. Nothing is committed.

**To check in a playtest:**
- The count goes up and "Last:" updates with each block.
- Two blocks of the same type in a row click twice.
- After hiding and showing with H a few times, each placement still clicks once.
- Clear resets both lines to 0 / none.
- No readonly error in the Output.