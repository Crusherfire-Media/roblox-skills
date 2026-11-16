I fixed all three bugs in `PlacedBlocks.luau` and `BuildHud.luau`. `Main.client.luau` didn't need changes. I couldn't run StyLua, selene or luau-lsp because this session can't approve shell commands, so the changes are untested. I only checked them by reading.

**"Blocks placed" stuck at 0.** `onBlockPlaced` and `clear()` changed the history table in place and then set it again. Charm locks stored tables in Studio, which caused the readonly error. On live servers it notices a change only when the value is a new table, so setting the same one again did nothing. Placing a block now copies the list, adds the new block and stores the copy. `clear()` stores a new empty list.

**"Last:" always "none".** The label's text read the Charm value directly, so it showed only the starting value. Vide only redraws for its own state, not Charm's. The HUD now passes the value through `VideCharm.useSignalState` (the bridge it already used for the count). Also, the last block type is now worked out from the history instead of kept in a second signal. That way the two can't disagree and `clear()` has only one thing to reset.

**Extra click after each hide/show.** Every time the HUD was shown, it started a new `Charm.subscribe` listener, and hiding never stopped it. That's why each H toggle added one more click. The listener is now wrapped in Vide's `cleanup(...)`, so it stops when the HUD hides.

**Also fixed:**
- **Click sound.** It played when the last block type changed, so placing the same type twice in a row made no sound. It now plays when the count goes up, so every placement clicks and Clear stays silent.
- **Hidden HUD.** The HUD now makes no sound while it's hidden. That follows from tying the listener to the HUD; tell me if you want the click even when it's hidden.

The HUD looks and works as before.

**What to check in a playtest:**
1. Place blocks: the count goes up and "Last:" shows the type, with one click per block, including repeats of the same type.
2. Press Clear: the count goes back to 0 and "Last:" shows "none", with no click.
3. Toggle H several times, then place a block: you should hear one click.

**Not changed:**
- The project has no UI Labs storybook, so I didn't add a story for `BuildHud`.
- `BuildHud` loads game state and plays sound directly. To give it a story, it would need to be split into a display component that takes plain inputs, plus a small wrapper that connects it to the game.