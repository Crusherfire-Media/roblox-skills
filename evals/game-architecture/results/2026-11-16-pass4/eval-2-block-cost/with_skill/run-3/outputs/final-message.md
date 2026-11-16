Blocks now cost coins. If a player can't afford a block, nothing is placed and they get a notification like "You need 3 more coins to place Window." I ran StyLua on the changed files, but I haven't run anything in Studio, so this still needs a playtest.

**Changes:**
- **`Catalogs/BlockTypes.luau`**: each block type has a `Price` field: Brick 5, Dirt 1, Grass 2, Window 8, Wood 3.
- **`PlacementServerService.luau`**: added `SetChargeHandler(handler)`, a hook another module can set to charge for blocks. The handler runs after every other check (valid type, cooldown, free cell, in reach). That way a placement refused for any other reason never takes coins. If the handler returns false with a message, the message is sent through the existing `PlacementRejected` event, which already shows notifications to the player.
- **New `PlacementSystem/Implementation/_PlacementCurrencyMediator.luau`** (server-only): sets that hook to call the existing `CurrencyServerService:TrySpend` with the block's price. If the player can't pay, it works out how many coins they're short for the message.

The placement code itself still knows nothing about coins; the new mediator is the only part that connects the two. This matches how placement is already linked to notifications.

**Passive income** is unchanged. `CurrencyServerService` wasn't edited, so players still earn 1 coin per placed block every 10 seconds, starting from 50 coins.

**Playtest checklist:**
- Placing a block drops Coins by its price.
- Spending down to 0 coins and trying a block you can't afford places nothing and shows the notification.
- Income still arrives every 10 seconds.
- The output log has no `>> Failed` or `Skipping :Start()` lines mentioning `_PlacementCurrencyMediator`.

**Possible follow-up (not changed):** `CurrencyServerService` loads `PlacementServerService` directly to count blocks for passive income. That ties the coin code to the placement code, which the project's rules ask to avoid. It works fine, so I left it alone. If you want it cleaned up, the block-count lookup could move into the new mediator, with income behaving the same.