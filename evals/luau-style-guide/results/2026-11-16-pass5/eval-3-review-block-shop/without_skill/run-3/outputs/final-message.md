I've written the review to `docs/review.md` and haven't changed the script. Before you build more on it, I'd fix the first two findings, because they let a player cheat the shop:

1. **Nothing checks what the client sends.** If a client sends "not a number" (NaN) as the amount, it passes the `amt < 1 or amt > MAX_PURCHASE` check and writes a corrupted coin balance to the DataStore. A position made of NaN also gets past every placement check. A bad block type or a missing part just crashes the handler. The fix is to treat incoming values as unknown and check them first; `BlockTypes.isBlockType` already exists for this and isn't used.
2. **Buying several times at once gives extra blocks.** `getCoins` waits on the DataStore, so if a player fires `BuyBlocks` several times in a row, every request sees the same balance. They pay once and get the blocks several times. Keeping the balance in memory and checking and deducting it without waiting closes this.

The rest, in order:

3. DataStore calls have no error handling, run on every purchase, overwrite blindly, and nothing saves when the server shuts down.
4. When a player removes a block whose owner has left, the block goes into the remover's stock, so abandoned blocks become free inventory.
5. Bought blocks only live in memory and are discarded when the player leaves, though the coins stay spent. Also, if a player leaves mid-purchase the handler errors after the coins are already deducted.
6. Placed blocks are never cleaned up.
7. Players can't turn receipts off: `GetAttribute(...) or true` is always true.
8. The ownership check compares names and uses the text `"nil"` to mean "owner has left". Comparing user IDs would be simpler and safer.
9. There's no rate limiting, and each failed placement prints a warning on the server, so a looping client can flood the log.
10. The price table repeats the block list without its types, there's a cast that hides the missing checks, and refunds look up the block type from the part's name.
11. Smaller tidy-ups: add `--!strict`, simplify the `placeBlock` parameters, and use full names instead of `plr`/`bt`/`amt`.

The linter and formatter pass, and the type checker only flags the missing return value in `getOwnerName` (finding 8). Everything else came from reading the code. Running the type checker also rebuilt `sourcemap.json`, which came out the same as before.

One decision affects how findings 3, 5 and 6 get fixed: should bought blocks and placed builds be saved between sessions?