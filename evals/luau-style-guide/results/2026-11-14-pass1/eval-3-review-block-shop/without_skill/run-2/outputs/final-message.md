I wrote the review to `docs/review.md` and left the script untouched. There are 11 findings, ordered by impact. For each one I give the lines, what's wrong and what to do instead, and I end with a suggested order of work. This was a read-only review: I didn't run the game or any of the checks.

**The ones that matter most:**
1. **Players can spend the same coins more than once.** The buy handler reads the balance from the DataStore, which pauses the handler. A client that fires `BuyBlocks` many times at once gets many handlers that all see the same balance. They pay once and get every purchase.
2. **DataStore calls aren't protected and run on every purchase.** A failed or throttled call breaks the handler halfway. One client spamming purchases can use up the request budget for the whole server. And if a player leaves while the handler is waiting, they're charged and get no blocks.
3. **Bought blocks are never saved.** Coins are saved but stock only lives in memory, so blocks a player bought but didn't place are lost when they leave.
4. **Nothing checks what the client sends.** The worst case is an amount of `NaN`: it passes the range check, and the player's stock then never runs out, so they can place unlimited blocks. Fractional amounts, `NaN` positions and non-Instance parts also get through.
5. **Clearing someone else's abandoned block gives the block to whoever cleared it.** That's a free source of blocks. Owners are also matched by turning the name into a string and comparing it with `"nil"`, which breaks for a player whose username is literally `nil`.

**Smaller items:**
- **Receipts can't be turned off:** `ShowReceipts = false` is ignored because of the `or` default.
- **Missing player data:** stock isn't set up for players already in the server when the script starts, and handlers error when it's missing.
- **Unanchored blocks:** clients can take control of their physics and move them.
- **Log spam:** clients can trigger the `warn` and `print` lines as often as they like.
- **Prices:** the price list is a second list of block types that can fall out of sync with `BlockTypes`.
- **Style cleanup:** no `--!strict`, short names like `plr` and `bt`, and two boolean parameters in a row.

Finding 1 needs more than a patch. My main recommendation is a player-data module that loads coins and stock once when a player joins, keeps them in memory, and saves both under one key. That fixes findings 1, 2, 3 and 7 together, so it's worth doing before you build more on this script.