Blocks now cost coins: Brick 5, Dirt 1, Grass 2, Window 8, Wood 3. StyLua, selene and luau-lsp all pass with 0 errors and 0 warnings. I haven't run a playtest in Studio, so I haven't seen it working in the game yet.

**How it works**
1. **Prices:** each block type in `Catalogs/BlockTypes.luau` now has a `Price`. Since the catalog is shared, the client can also read prices if you later want to show them in a hotbar.
2. **Placement:** `PlacementServerService` has a new `SetChargeCallback`. It's called only after every other check has passed (block type, cooldown, open cell, distance). A request refused for any other reason costs nothing. If the charge fails, nothing is placed and the reason goes out through the existing `PlacementRejected` event. If no callback is set, placing is free, so the placement system still doesn't depend on the coin system.
3. **Connecting it to coins:** a new server-only module, `PlacementSystem/Implementation/_PlacementCurrencyMediator.luau`, takes the price with the existing `CurrencyServerService:TrySpend`. If the player can't afford it, it returns a message like "You need 3 more coins to place Brick." That message goes through the existing notification connection (`_PlacementNotificationMediator`), so it appears as a normal notification.

**Passive income:** `CurrencyServerService` is unchanged, so players still get 1 coin per placed block every 10 seconds. Only blocks that were actually paid for and placed count.

**One thing I left alone:** `CurrencyServerService` (part of the coin system's core) still loads `PlacementServerService` directly to count blocks for income. The project's architecture rules say systems should be connected through a separate linking module instead. It works today, and moving it would have meant changing the income code you asked me to keep as is. I can move it into a linking module like the new one if you want.

Earlier, a Bash command was denied because the command text couldn't be checked automatically. I used the built-in search tools for the same lookups, so nothing was skipped. Nothing is committed.