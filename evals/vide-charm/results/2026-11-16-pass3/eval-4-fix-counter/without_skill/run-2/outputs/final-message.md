I've fixed all three problems in `PlacedBlocks.luau` and `BuildHud.luau`. `Main.client.luau` didn't need changes. I haven't run it in Studio, so please check it there. I checked the fixes against the Charm 0.11.1 and vide-charm source in `roblox_packages`.

**"Blocks placed" stuck at 0.** `onBlockPlaced` was adding the new block to the existing history table and then setting that same table back into the signal.
- **Studio:** Charm freezes stored tables there, so changing it raised "attempt to modify a readonly table".
- **Live servers:** tables aren't frozen, so the change went through. But the signal got the same table back, and Charm only reacts when it gets a different table, so the count never updated.

Now each placement copies the history into a new table with the block added (`PlacedBlocks.luau:26`). `clear()` sets a new empty table instead of emptying the old one, which had the same problem.

**"Last:" always "none".** That label called `PlacedBlocks.getLastPlaced()` directly. Vide can't tell when a Charm value changes, so the label was drawn once and never redrawn. It now reads from `VideCharm.useSignalState`, the same way the count already did.

**Extra click each time you toggle with H.** `Charm.subscribe` returns a function that stops the subscription, and it was never called. Each time you showed the HUD, another listener was added while the old ones stayed, so you heard one more click each time. It's now wrapped in `Vide.cleanup(...)`, so hiding the HUD stops it.

**Other Charm fixes:**
- **Click when placing the same block twice:** the click listened to "last placed", which doesn't change when you place the same block type twice in a row, so there was no click. It now plays whenever the count goes up, which matches the "plays each time a block lands" comment and still stays silent on Clear.
- **Grouped updates:** placing and clearing each change two values. They're now grouped with `Charm.batch`, so listeners run once with both values set instead of seeing a half-updated state in between.

The HUD's layout, look, Clear button and H toggle are unchanged.