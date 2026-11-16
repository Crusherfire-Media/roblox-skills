I wrote the review to `docs/review.md` and didn't change the script. It has 16 findings in four groups, from critical down to style. Each one says where it is, what's wrong and what to do instead, and the review ends with a suggested order for fixing them.

The four that matter most, because any client can exploit them or players lose progress:

1. **Free unlimited blocks:** if a client sends NaN (0/0) as the purchase amount, it passes the `amt < 1 or amt > MAX_PURCHASE` check, because every comparison with NaN is false. The player's stock then becomes NaN, and the stock check never stops them placing. Fractional amounts like 1.5 also get through.
2. **Coins can be spent twice:** each purchase reads the balance with `GetAsync`, waits, then writes it with `SetAsync`, so two purchases sent together both succeed for one payment. Neither call has error handling, and every purchase uses up DataStore requests. The fix is to keep coins in memory for the session and save them with `UpdateAsync`.
3. **Free blocks from players who left:** when anyone removes a block whose owner has left, that block is added to the remover's own stock.
4. **Bought blocks are lost on leave:** coins are saved, but the blocks they buy only exist until the player leaves.

Below those:
- Turning receipts off does nothing (`false or true` is `true`).
- Several handlers throw on bad input, or if a player leaves during a purchase, sometimes after the player has already been charged.
- Blocks that aren't anchored can be moved by clients.
- Clients can flood the server log.
- There's no rate limiting.
- There are typing and style items (no `--!strict`, abbreviated names, remotes created at runtime).

`selene` and `stylua` found nothing. `luau-lsp` found one real warning: `getOwnerName` can return nothing (line 56). It also reported unknown requires, but those come from `sourcemap.json` being out of date: it has no entries for `BlockTypes` or `PlacementRules`. I didn't regenerate it, because that rewrites a project file and this session can't approve commands. Run `rojo sourcemap` before trusting the type check.