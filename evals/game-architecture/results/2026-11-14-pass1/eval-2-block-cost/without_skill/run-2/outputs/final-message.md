Blocks now cost coins: Brick 5, Dirt 1, Grass 2, Window 8, Wood 3. Placing a block takes its price from the player's coins. If they can't afford it, nothing is placed and they get a notification like "You need 3 more coins to place Brick." The project's checks pass (`luau-lsp analyze`, `selene` and `stylua --check`), but I couldn't play-test it in Studio.

**Changes**
- **`Catalogs/BlockTypes.luau`**: each block type now has a `Price` field.
- **`PlacementServerService.luau`**: added `SetApprover`. Once a placement request has passed all the existing checks (valid block, spot free, in reach, not too soon after the last one), the approver is asked right before the block is created. If it says no, nothing is placed. Placement still doesn't know anything about coins.
- **New `CurrencySystem/Implementation/_BlockPriceMediator.luau`** (plus its `.meta.json`, matching the existing mediator): the approver it sets uses the existing `TrySpend` to take the price, and sends the "need more coins" notification when the player is short.

The coin check lives in the currency side because currency already depends on placement for passive income. If placement checked coins itself, each would depend on the other. Coins are only taken for placements that will definitely happen, so a refused request (too far, spot taken, too soon) never costs anything.

Passive income is unchanged: it's still one coin per placed block every 10 seconds, and players still start with 50 coins.

One thing you might notice: refused requests don't count toward the 0.1-second limit between placements, so a broke player who clicks quickly gets one notification per click. "That spot is too far away" already works the same way. I can make refusals count toward that limit if you'd like fewer repeats.

Two commands that needed approval were blocked because this session can't show permission prompts. One was a first look at the git status and file list, which I did with the file search tools instead. The other was a one-shot script to add the prices, which I did as separate edits instead. Neither changed the result.