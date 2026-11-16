Blocks now cost coins. Placing one takes its price from the player's coins. If they can't afford it, nothing is placed and they get a notification like "You need 3 more coins to place Window." Passive income still works the same way: I didn't touch `CurrencyServerService`. StyLua passes on the changed files, but I haven't run a playtest or Script Analysis, so none of this has been tested in Studio.

**What changed:**
- **`Catalogs/BlockTypes.luau`**: each block type has a `Price` field: Brick 5, Dirt 1, Grass 2, Window 8, Wood 3.
- **`PlacementServerService.luau`**: there's a new `SetChargeCallback(callback)` that sets what placing a block costs. The charge runs only after every other check passes (valid cell, not occupied, within reach). That way a player is never charged for a block that then fails to place. If the charge fails, placement is refused and the reason goes out on the existing `PlacementRejected` event. The existing `_PlacementNotificationMediator` already turns that event into a notification, so I didn't need to change it.
- **New `Implementation/_PlacementCurrencyMediator.luau`** (marked server-only): it sets that callback to spend the coins with `CurrencyServerService:TrySpend` and builds the "need more coins" message.

The charge is in a separate mediator rather than in the placement code because `CurrencyServerService` already requires `PlacementServerService` to pay passive income. Having placement require currency back would create a circular dependency.

**Worth knowing:**
- **Passive income vs. price:** income is still one coin per placed block every 10 seconds. A 1-coin Dirt block now pays for itself in 10 seconds, while a Window takes 80. You may want to rebalance that later.
- **Existing rule break:** `CurrencyServerService` reaches into the placement system directly, which goes against the project's rule that systems connect only through mediators. I left it alone to keep passive income exactly as it is. Moving it into a mediator later would be a small change.
- **Blocked command:** my first attempt to list the repo layout and git status was blocked by the permission system, and I didn't retry it. I read the files directly instead.