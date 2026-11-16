Blocks now cost coins. When a player places a block, its price comes out of their coins. If they can't afford it, nothing is placed and they get a notification like "You need 3 more coins to place Window." I haven't tested this in a Studio playtest. StyLua and selene both pass on the changed modules.

**What changed**
- **`Catalogs/BlockTypes.luau`**: each block type has a `Price` (Brick 5, Dirt 1, Grass 2, Window 8, Wood 3).
- **`PlacementServerService.luau`**: there's a new `SetChargeHandler`. Placement asks it to take payment only after every other check passes (valid block, empty cell, within reach), so a rejected placement never costs coins. If the charge fails, the reason goes out through the existing `PlacementRejected` event. The existing notification mediator already shows those to the player, so I didn't need a new notification path.
- **New `PlacementSystem/Implementation/_PlacementCurrencyMediator.luau`** (server-only): this is the one place that connects placement to coins. It charges the block's price using the existing `TrySpend` and builds the "need more coins" message.

**Passive income**
`CurrencyServerService` used to load `PlacementServerService` directly to count blocks. That breaks the project's rule that one system's core code never loads another's, and it would have made the two systems depend on each other once placement needed coins. So `CurrencyServerService` now has a `SetIncomeSource` hook, and the new mediator sets it to the same block count. Payouts work exactly as before: one coin per placed block every 10 seconds.

**Two small behavior details**
- A refused purchase still counts toward the 0.1-second limit between placements, so a broke player clicking fast can't flood themselves with notifications.
- Placed blocks still earn 1 coin each as passive income, whatever their price. A Window (8 coins) now takes 80 seconds to pay for itself, and a Dirt block takes 10.

Two shell commands were blocked because this session can't approve them: `git status` and a Python script for the catalog edit. I made the edits by hand instead. One of those hand edits briefly added Grass's price twice; I found and fixed it, and the catalog now has exactly one price per block.