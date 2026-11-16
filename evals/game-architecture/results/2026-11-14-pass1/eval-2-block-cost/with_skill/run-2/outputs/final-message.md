Blocks now cost coins: Brick 5, Dirt 1, Grass 2, Window 8, Wood 3. I haven't playtested it, so I haven't seen it work in game. StyLua, selene and luau-lsp all pass on the changed files.

**How it works**
- **Prices** are a new `Price` field on each entry in `Modules/Catalogs/BlockTypes.luau`.
- **Placement** (`PlacementServerService.luau`) has a new `SetChargeCallback`. The placement code doesn't know about coins; it runs the callback once a request has passed every other check (valid block type, rate limit, empty cell, in reach). If the callback returns a reason, nothing is placed and the existing rejection event fires.
- **Charging the player** happens in a new file, `PlacementSystem/Implementation/_PlacementCurrencyMediator.luau`, which connects placement to the coin system. It calls the existing `CurrencyServerService:TrySpend` with the block's price, which takes the coins only if the player has enough. Otherwise the player gets "You need 3 more coins to place Window." That message goes through the existing notification connection, the same way "too far away" does. The mediator is set to run on the server only, so it isn't copied to clients.
- **Coins are only taken for blocks that actually get placed.** The charge is the last check, so a request refused for any other reason costs nothing. Nothing happens between taking the coins and placing the block, so two requests can't both claim the same cell.

**Passive income** is untouched: `CurrencyServerService` still pays one coin per placed block every 10 seconds, and failed placements don't count toward it.

**Notes**
- Players start with 50 coins, so they can't afford a block until income comes in.
- The hotbar doesn't show prices yet.
- One existing issue I left alone: `CurrencyServerService` requires `PlacementServerService` directly to count blocks for passive income. The project's architecture rules say systems should connect through a mediator instead. It works fine now, but I can move it into a mediator if you want.
- Some commands were blocked because this session can't show approval prompts. I couldn't run the linters with exit-code output or view `git diff`, so I used direct file edits instead. Nothing was skipped because of this.

To test: start a playtest, place blocks until your coins run out, check that the notification appears and no block is placed, then wait for income and check that placing works again.