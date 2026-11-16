Blocks now cost coins: Brick 5, Dirt 1, Grass 2, Window 8, Wood 3. The server takes the price when a block is placed. If the player can't afford it, nothing is placed and they get a notification like "You need 3 more coins to place Window." I haven't run this in Studio, so it's untested. It needs a quick playtest to confirm.

**What changed**
- **`Catalogs/BlockTypes.luau`**: each block type now has a `Price`.
- **`PlacementServerService.luau`**: added `SetChargeCallback`, a way for other code to charge for each block. It runs only after every other check passes (valid spot, in reach, not too fast), so a refused placement never costs coins. If the charge fails, nothing is placed and the reason goes out through the existing `PlacementRejected` event. The existing notification mediator already shows that event to the player, so no new notification code was needed. With no callback set, blocks stay free.
- **New `PlacementSystem/Implementation/_PlacementCurrencyMediator.luau`** (server-only): connects placement to coins. It spends the price with the existing `TrySpend` and builds the "need more coins" message. Placement still doesn't depend on the coin system, so no circular dependency is added.

Passive income is unchanged: it still pays one coin per placed block every 10 seconds.

Two tool calls were blocked because this session can't approve permission prompts: a `git status`/file listing and a script to add the prices. I made the same changes with the file tools instead.

**To check in a playtest:** with the starting 50 coins, place a few Windows (8 each) until coins run low. Coins should drop by the right amount, the next placement should be refused with the notification, and passive income should keep paying.

**Suggestions:**
- The block picker doesn't show prices yet, so players only find out a block is too expensive when they're refused.
- `CurrencyServerService` reads the placed-block count directly from the placement code. It's harmless now, but a cleaner setup would have a mediator supply the income amount. I left it alone since you asked to keep passive income as it is.