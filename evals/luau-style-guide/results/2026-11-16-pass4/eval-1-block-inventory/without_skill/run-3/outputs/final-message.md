I've written `src/ServerScriptService/BlockInventory.luau`. It passes `stylua --check` and `selene` with no errors or warnings. I haven't run it in Studio and couldn't run a Luau type checker, so it's untested so far. Nothing else in the project requires it yet.

**What placement will call:**

| Function | Does | Returns |
|---|---|---|
| `take(player, blockType)` | Removes one block, for placing | `true`, or `false` plus `"NotLoaded"`, `"InvalidBlockType"` or `"OutOfBlocks"` |
| `giveBack(player, blockType)` | Adds one block back, for removing | `true`, or `false` plus `"NotLoaded"`, `"InvalidBlockType"` or `"AtLimit"` |
| `grant(player, blockType, amount)` | Gives blocks for the daily reward and admin commands, with no 99 limit | `true`, or `false` plus a reason (`"InvalidAmount"` if the amount isn't a positive whole number) |
| `getCount(player, blockType)` | Reads a count, for the UI | the count, or `nil` if not loaded or the type is invalid |
| `isLoaded(player)` | Says whether the player's counts have loaded | `true` / `false` |

The settings are `StartingCount = 20` and `MaxCount = 99`. The reasons are exported as the `FailReason` type.

**How it handles the cases you raised:**
- **Calls from the remote:** the block type comes from the client, so it's checked against `BlockTypes` before use. Any call for a player whose counts haven't loaded, or who has left, returns `"NotLoaded"` and changes nothing.
- **Leaving during a load:** the DataStore read pauses the script. If the player leaves before it finishes, their counts are thrown away instead of being kept forever.
- **Loading:** it tries the read 3 times, 1 second apart. If all fail, the player gets 20 of each. Bad saved values (negative, fractions, wrong type) are replaced with 20. So is any type missing from the save, such as a block type added later.
- **Setup:** the module connects its own join and leave handlers when first required. It also picks up players who joined before that.

**Decisions for you:**
- **The limit when picking blocks back up:** a player at or above 99, for example at 120 from a reward, can't get a block back by removing one. That block is simply lost. If you'd rather the removal still happen with no block returned, placement can do that when it sees `"AtLimit"`.
- **Saving:** each player has a flag recording whether their load failed. When you add saving, skip those players. Otherwise a temporary DataStore outage would overwrite their real counts with the starting 20.
- **UI updates:** there's no event when a count changes. The UI will need one later, and it's easy to add here.