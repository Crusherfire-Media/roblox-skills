Blocks now cost coins: Brick 5, Dirt 1, Grass 2, Window 8, Wood 3. StyLua and selene pass, but I haven't playtested it, because no Studio connection is set up in this session. A quick check would be to place blocks until you run out of coins, confirm the notification, and confirm passive income still pays.

**How it works**
- **Prices** are a new `Price` field on each entry in `Modules/Catalogs/BlockTypes.luau`.
- **Charging:** placement now has a payment step, `SetChargeForBlock`, in `PlacementServerService.luau`. It runs after all the other checks (valid spot, within reach, not placing too fast). That way the player is only charged for a block that will actually be placed.
- **The wiring** is in a new file, `PlacementSystem/Implementation/_PlacementCurrencyMediator.luau`. It takes the price from the player's coins with the existing `TrySpend`. If they can't afford it, nothing is placed and they get a notification like "You need 3 more coins to place Window." It's set to stay on the server.

**One change you didn't ask for**
The currency code used to require the placement code directly to count blocks for passive income. The project's architecture rules don't allow one system to require another, and placement now needs to reach currency too. So currency now takes its income amount from a function you hand it (`SetIncomeSource`), and the new file passes in the block count.

Passive income works exactly as before: 1 coin per placed block every 10 seconds, starting at 50 coins. If you'd prefer to keep the old direct require, it's easy to put back.

**Not changed**
- Players don't see prices anywhere yet. The prices are in the block list, so a hotbar label could show them later.
- The `Implementation` folders' `init.meta.json` files write `IconTint` as a bare array. Rojo 7.6 and later reject that form and expect `{ "Color3": [...] }`. It was already like this before my change and I left it alone.