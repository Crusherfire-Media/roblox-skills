I wrote the inventory module at `src/ServerScriptService/BlockInventory.luau`. Selene reports no errors or warnings, and StyLua's format check passes. I didn't run a Luau type check because I couldn't find a type checker to run, and nothing has been tested in Studio. Two commands were blocked because they needed approval: an early one to list the project files, and running StyLua to rewrite the file. I read the files with other tools and applied StyLua's formatting by hand.

**What placement and other code can call:**
- `take(player, blockType)` takes one block when a player places one. It returns `true`, or `false` plus a reason: `"NotLoaded"`, `"UnknownBlockType"` or `"OutOfBlocks"`.
- `giveBack(player, blockType)` gives one block back when a player removes one. It refuses with `"AtLimit"` if they already have 99 or more of that type.
- `grant(player, blockType, amount)` is for the daily reward and admin commands. It can go past 99. It refuses with `"InvalidAmount"` unless the amount is a positive whole number.
- `getCount(player, blockType)` returns the count for the UI, or `nil` if the player's counts aren't loaded or the type isn't valid.
- `isLoaded(player)` says whether a player's counts are ready.
- The reasons are exported as a `FailureReason` type so placement can turn each one into a message.

**Remote calls for players who aren't loaded or have left:** every call fails with `"NotLoaded"` rather than erroring. If a player leaves while their DataStore read is still running, the result is thrown away. Counts are stored per player session, so a slow load can't end up in the counts of someone who rejoined quickly. Block type names are checked when the call arrives, since they come from the client.

**Loading:**
- If the DataStore read fails, it retries up to 3 times, then starts the player with 20 of each.
- Saved data is checked: a missing or broken count, or a block type added after the player last played, starts at 20.
- Saved counts above 99 are kept.

**Decisions for you:**
- **Removing a block at 99:** `giveBack` refuses and the player doesn't get the block back. Placement decides whether to remove the block anyway and let that one go, or block the removal.
- **Grants before loading:** `grant` also fails with `"NotLoaded"`. The daily reward should wait until `isLoaded` is true, or it should retry.
- **Saving later:** a player whose load failed has the default 20s in memory. If those were saved, they would overwrite the player's real saved counts. `wasLoadedFromStore(player)` returns `false` in that case so the save change can skip those players.

The module starts handling joins and leaves the first time something requires it, and it also loads anyone already in the server. Nothing requires it yet, so it won't run until placement does.