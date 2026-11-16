I wrote `src/ServerScriptService/BlockInventory.luau`. StyLua, selene and luau-lsp all pass with no errors. Nothing has run it in a live server yet, and nothing requires it yet. I haven't committed it.

**What placement will call:**

| Method | Returns | Fails when |
|---|---|---|
| `BlockInventory:TakeBlock(player, blockType)` | `success, failureReason?` | `"NotLoaded"` (counts not loaded yet, or the player left), `"OutOfBlocks"` |
| `BlockInventory:ReturnBlock(player, blockType)` | `success, failureReason?` | `"NotLoaded"`, `"AtMaximum"` (already holding 99) |
| `BlockInventory:GrantBlocks(player, blockType, amount)` | `success, failureReason?` | `"NotLoaded"`. Can go past 99, for the daily reward and admin commands |
| `BlockInventory:GetCount(player, blockType)` | `number?` | Gives `nil` until the player's counts have loaded |

The failure reasons are exported as the types `TakeFailure`, `ReturnFailure` and `GrantFailure`, so placement can turn each one into a message for the player.

**How it behaves:**
- **Loading:** reads `player_<UserId>` from the "BlockInventory" DataStore. If the load fails, the saved data isn't a table, or a type's count isn't a whole number of 0 or more, that type starts at 20. If a block type is added later, existing players get 20 of it. Saved counts above 99 are kept, since rewards are allowed to go past the cap.
- **Leaving:** a player who leaves while their load is still running gets nothing stored, so no counts are left behind for a player who is gone. Leaving also clears their counts.
- **Bad block types:** a block type that isn't in `BlockTypes` raises an error rather than returning a reason. Placement should check the remote's argument with `BlockTypes.isBlockType` before calling in.
- **Edit mode:** the module only connects to player join and leave events while the game is running. That way, requiring it from tests or the command bar doesn't leave connections behind.

**Decisions for you:**
- **Removing a block at 99:** `ReturnBlock` returns `"AtMaximum"` and gives nothing back. Placement has to choose between blocking the removal and letting the block disappear.
- **Saving after a failed load:** right now a player whose load failed looks the same as a new player. When saving is added, it should skip players whose load failed. Otherwise a DataStore outage would overwrite their real counts with the defaults. I can track that flag now if you'd like.