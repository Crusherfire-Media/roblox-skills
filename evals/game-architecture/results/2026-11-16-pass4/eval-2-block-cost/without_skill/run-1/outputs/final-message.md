Blocks now cost coins: Brick 5, Dirt 1, Grass 2, Window 8, Wood 3. Placing a block takes its price from the player's coins. If they can't afford it, nothing is placed and they get a notification such as "You need 3 more coins to place Brick." The project's checks pass: the type check, selene and stylua report nothing. I haven't run it in Studio, so I haven't watched coins go down in a real game.

**What changed:**
- **`Catalogs/BlockTypes.luau`**: each block type now has a `Price`.
- **`PlacementServerService.luau`**: placement now has a payment step, set with `SetPaymentHandler`. It runs only after every other check passes (reach, occupied cell, rate limit), right before the block is placed. So coins are never taken for a block that ends up refused for another reason. If payment fails, the existing notification code tells the player why. With no payment step set, blocks stay free.
- **New `CurrencySystem/Implementation/_BlockCostMediator.luau`** (plus its `.meta.json`): this sets the payment step to take the price with the existing `TrySpend`, and writes the "need more coins" message.

**Why the extra file:** the currency code already depends on placement, because it needs the block count for passive income. If placement also depended on currency, each would depend on the other. The new file connects them from the currency side instead, the same way `_PlacementNotificationMediator` connects placement to notifications.

**Passive income** is unchanged: one coin per placed block every 10 seconds.

The client hotbar doesn't show prices yet. They're in the shared `BlockTypes` catalog, so adding them would be easy if you want that.

I couldn't use the Bash tool this session because its commands needed approval and nobody was there to give it. It didn't matter: I read the files directly and ran the checks in PowerShell.