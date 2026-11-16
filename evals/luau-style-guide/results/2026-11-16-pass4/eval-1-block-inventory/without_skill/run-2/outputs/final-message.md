I added `src/ServerScriptService/BlockInventory.luau`. StyLua and Selene both pass on it. I haven't run it in Studio and there are no tests for it yet. It isn't connected to placement or anything else yet.

**What placement will call:**
- **`takeBlock(player, blockType)`**: takes one block. Returns `true`, or `false` plus a reason.
- **`returnBlock(player, blockType)`**: gives one back. Fails with `"Full"` if the player already has 99 or more.
- **`grantBlocks(player, blockType, amount)`**: for the daily reward and admin commands. It isn't limited to 99. `amount` has to be a positive whole number, or it fails with `"InvalidAmount"`.
- **`getCount(player, blockType)`**: for the UI. Returns `nil` if the player's counts aren't loaded or the block type isn't valid.
- **`isLoaded(player)`**, plus `MaxCount` (99) and `StartingCount` (20).

The failure reasons are an exported `FailureReason` type:
- `"NotLoaded"`: the player's counts are still loading, or the player has left.
- `"InvalidBlockType"`: not one of the five types. The block type is checked when the function runs, because the placement remote passes along whatever the client sends.
- `"OutOfBlocks"`: the player has none of that type left.
- `"Full"`: the player already has 99 or more of that type.

**Loading and leaving:**
- When a player joins, their counts load from the `"BlockInventory"` store under `player_<UserId>`. New players get 20 of each type. If the load fails, it logs a warning and the player gets 20 of each.
- A block type missing from the saved table gets 20, so new players aren't the only ones covered. Bad saved values (not a number, NaN, infinite) also become 20, and negative ones become 0.
- If a player leaves while their load is still running, the result is thrown away. Leaving drops their counts.
- Players who were already in the server when the module is first required also get their counts loaded.

**Behaviour to check:**
- **Removing a block at 99:** if a player removes a placed block while holding 99 or more of that type, the block isn't returned. That's how I read the 99 cap. If you'd rather it go back anyway, `returnBlock` is the only thing to change.
- **For the saving change:** players whose load failed get the default 20 of each, and nothing currently marks them as different from a real save. Saving those defaults would overwrite their real data. The saving change should skip players whose load failed. That means tracking a flag per player, which I left out since nothing uses it yet.