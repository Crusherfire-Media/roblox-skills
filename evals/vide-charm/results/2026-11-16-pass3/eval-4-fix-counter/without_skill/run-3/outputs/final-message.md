I fixed all three bugs, plus one more I found along the way. Nothing was run: I couldn't open Studio or play the game from here, so please test it in Studio.

**"Blocks placed" stuck at 0** (`PlacedBlocks.luau`)
The code was changing the history table in place and then passing the same table back to the setter. Charm stores tables as read-only in Studio, which caused the "attempt to modify a readonly table" error. On live servers the tables aren't read-only, but Charm saw the same table come back, decided nothing had changed, and never updated the count.
- Each placement now copies the history and adds the new block to the copy (`table.clone` + `table.insert`).
- `clear()` now just sets it to a new empty table `{}`.

**"Last:" always "none"**
- `getLastPlaced` was its own signal kept in step by hand. It's now worked out from the history (the last entry), so it can't drift out of sync with the count.
- The real cause was in `BuildHud.luau`: the label read the Charm signal directly inside a Vide text function. Vide doesn't track Charm signals, so the label never updated. It now goes through `VideCharm.useSignalState`, the same way the count label already did.

**Extra click each time you toggle with H**
Pressing H to hide the HUD removes it, and showing it builds it again. Each rebuild started a new sound listener with `Charm.subscribe`, and nothing ever stopped the old ones, so they piled up. It's now wrapped in `Vide.cleanup(...)`, so the listener stops when the HUD is hidden.

**Extra bug:** the click listened for changes to the last block type, so placing the same type twice in a row made no sound. It now listens to the count and clicks whenever the count goes up, so every placement clicks and pressing Clear stays silent.

The HUD's layout, text and Clear button are unchanged. `Main.client.luau` didn't need any changes.