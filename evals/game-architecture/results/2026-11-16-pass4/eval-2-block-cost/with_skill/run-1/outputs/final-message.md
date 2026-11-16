Blocks now cost coins: Brick 5, Dirt 1, Grass 2, Window 8, Wood 3. When a player places a block, its price is taken from their coins. If they can't afford it, nothing is placed and they get a notification like "You need 3 more coins to place Window." The type check, selene and stylua all pass. I couldn't run a playtest in Studio, so I haven't seen it work in the game yet.

**What changed**
- **`Catalogs/BlockTypes.luau`**: each block type now has a `Price` field holding its price.
- **`PlacementServerService.luau`**: new `SetPaymentHandler(handler)`. The payment check runs last, after the type, rate-limit, occupied-cell and reach checks. That way a player is never charged for a block that ends up not placed. If payment fails, the reason goes out through the existing `PlacementRejected` event, so the notification code you already have shows it unchanged.
- **New `PlacementSystem/Implementation/_PlacementCurrencyMediator.luau`** (server-only, with its own `.meta.json`): this connects placement to coins. It calls `CurrencyServerService:TrySpend` with the block's price and builds the "need more coins" message. Neither the placement code nor the currency code requires the other, so this adds no require loop.

**Passive income** is unchanged: `CurrencyServerService.luau` wasn't edited. Players still earn 1 coin per placed block every 10 seconds.

Blocking a placement because of coins doesn't start the 0.1-second cooldown, just as with the "too far away" message. So a player with too few coins who keeps clicking gets one notification per click.