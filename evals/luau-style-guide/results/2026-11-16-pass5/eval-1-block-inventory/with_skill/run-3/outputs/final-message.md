I've written `src/ServerScriptService/BlockInventory.luau`. luau-lsp, selene and `stylua --check` all pass on it. It hasn't been run in Studio, and nothing requires it yet.

**What placement and other scripts call** (all methods, e.g. `BlockInventory:TakeBlock(player, blockType)`):

| Method | Returns | Notes |
|---|---|---|
| `TakeBlock(player, blockType)` | `success, reason?` | The reason is `"NotLoaded"` or `"OutOfBlocks"` |
| `ReturnBlock(player, blockType)` | `success, reason?` | The reason is `"NotLoaded"` or `"AtLimit"` (already holding 99) |
| `GiveBlocks(player, blockType, amount)` | `boolean` | For the daily reward and admin commands; can go past 99. Returns false if counts aren't loaded. Errors if `amount` isn't a positive whole number |
| `GetCount(player, blockType)` | `number?` | `nil` if counts aren't loaded, so the UI can tell "not loaded" apart from 0 |

The reason types (`TakeFailure`, `ReturnFailure`) are exported so placement can turn each one into a message for the player.

**Loading and leaving:**
- When a player joins, their counts load from `"BlockInventory"` / `player_<UserId>`. If there's no saved data or the load fails, they start with 20 of each type. If the load fails, it also prints a warning.
- Saved values are checked one type at a time. Any block type that's missing or has a bad value (not a whole number, negative, NaN) gets 20, so block types added later work for existing players. Saved counts over 99 are kept.
- If a player leaves while their load is still running, the result is thrown away rather than stored for someone who's gone.
- Players already in the server when the module is first required get loaded too, since placement will require it after the server starts.
- Counts are dropped when the player leaves.

**Calls from the remote:** calls for players who haven't loaded yet or who just left return `false, "NotLoaded"` and don't error. The methods take a `BlockType`, so placement should still check the client's value with `BlockTypes.isBlockType` before passing it in.

**Decision for you:** when a removal would take a player past 99, `ReturnBlock` refuses with `"AtLimit"` and the block isn't given back. Placement needs to decide whether to still remove the placed block (the player loses it) or block the removal. Say if you'd rather it behave differently.

**Before saving goes in:** a player whose load failed gets the default counts, and saving those on leave would overwrite their real data. The saving change should only save players whose load succeeded, which means recording that at load time.