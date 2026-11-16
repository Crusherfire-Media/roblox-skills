I fixed all three problems. The changes are in `PlacedBlocks.luau` and `BuildHud.luau`, and StyLua's formatting check passes. I haven't run it in Studio, so it's untested in-game.

**"Blocks placed" stuck at 0:** `onBlockPlaced` and `clear()` were changing the history table in place. Charm freezes tables stored in a signal when running in Studio, which is the "readonly table" error you saw. On live servers it doesn't freeze them, but it only notices a change when it gets a different table, so it never saw an update. Now each placement copies the history, adds the block and sets the new table, and `clear()` sets a fresh empty `{}`.

**"Last:" always "none":** the label read `PlacedBlocks.getLastPlaced()` directly inside its text function. Vide doesn't track Charm reads, so the label kept its first value forever. It now goes through `VideCharm.useSignalState`, the same way the count label already did. I also made `getLastPlaced` a computed value taken from the last entry in the history, instead of a second signal that had to be kept in step by hand.

**Extra click each time you toggle with H:** each time `show` rebuilt the HUD, `Charm.subscribe` added another listener, and nothing removed the old ones. The subscription is now wrapped in Vide's `cleanup`, so it ends when the HUD is hidden.

**Other Charm misuse I fixed:** the click sound listened to "last block type", so placing the same type twice in a row made no sound. It now plays whenever the count goes up. Placing still clicks every time, and pressing Clear stays silent.

To check in a playtest:
- Place a few blocks. The count should go up, "Last:" should show the type, and placing the same type twice should click both times.
- Press Clear. It should show 0 and "none", with no sound.
- Press H several times, then place a block. It should click exactly once, with no "readonly" error in the output.

Two gaps I left alone, since they're outside this fix:
- The HUD has no UI Labs story, and the project has no storybook to put one in.
- `Main.client.luau` doesn't turn on Vide's strict mode (`Vide.strict = RunService:IsStudio()`). It adds extra checks in Studio that help catch bugs like these.