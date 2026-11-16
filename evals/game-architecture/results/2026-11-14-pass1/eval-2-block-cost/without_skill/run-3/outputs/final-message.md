Blocks now cost coins: Brick 5, Dirt 1, Grass 2, Window 8, Wood 3. I couldn't run the project's checks (rojo sourcemap, luau-lsp, selene, stylua) because those commands needed approval this session can't give, and I haven't tested it in Studio, so none of this has been run.

**How it works**
- **Prices:** each block type in `Modules/Catalogs/BlockTypes.luau` now has a `Price`.
- **Charging:** placement now takes an optional charging function, set through a new `SetPaymentHandler`. It's called only after a placement has passed all the existing checks (rate limit, reach, cell free), just before the block is created. If it refuses, nothing is placed and the reason goes out through the existing `PlacementRejected` event. With no function set, placing stays free.
- **New file:** `CurrencySystem/Implementation/_BlockPriceMediator.luau` (plus its `.meta.json` so it stays server-only) supplies that function. It takes the price with the existing `TrySpend`.
- **Notification:** if the player can't afford the block, the existing placement notification shows e.g. "You need 3 more coins to place Brick."

I connected the two systems this way because the currency code already requires the placement code (for passive income). Having placement require currency directly would create a require cycle.

**Behaviour to know about**
- Coins are only taken when a block will definitely be placed. Clicks on an occupied cell or one out of reach cost nothing.
- Passive income is unchanged: still 1 coin per placed block every 10 seconds, and still 50 starting coins.