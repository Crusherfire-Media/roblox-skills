I wrote the module at `src/ServerScriptService/BlockInventory.luau`. StyLua, selene and luau-lsp all pass on it with no errors or warnings. Nothing has tested it in a running game yet.

**What it gives placement and the other scripts**
- **`BlockInventory:TakeBlock(player, blockType)`** returns `true` if a block was taken. If not, it returns `false` and a reason: `"OutOfBlocks"` or `"NotLoaded"`.
- **`BlockInventory:ReturnBlock(player, blockType)`** adds one back. It refuses with `"AtLimit"` when the player already has 99 or more of that type, and the count stays the same. It can also return `"NotLoaded"`.
- **`BlockInventory:GrantBlocks(player, blockType, amount)`** is for the daily reward and admin commands, and it ignores the 99 limit. It returns `"NotLoaded"` if the player's counts aren't there.
- **`BlockInventory:GetCount(player, blockType)`** returns the count, or `nil` if the player's counts haven't loaded yet or the player has left.

**How it behaves**
- **Loading:** when a player joins, it reads key `player_<UserId>` from the `"BlockInventory"` DataStore. New players get 20 of each type, and so do players whose load fails; a failed load also prints a warning.
- **Bad saved data:** any type missing from the save, or saved as something other than a whole number of 0 or more, also starts at 20. Saved counts above 99 are kept.
- **Not loaded or already left:** placement just gets `"NotLoaded"` back. If a player leaves while their load is still running, the result is thrown away instead of being stored.
- **On leave:** the player's counts are dropped.
- **Bad arguments:** an unknown block type, or a grant amount that isn't a positive whole number, raises an error. Because of that, placement should check the type sent by the client with `BlockTypes.isBlockType` before calling these.
- **Edit mode:** it only connects to players joining and leaving when the game is actually running. Specs or the command bar can require it without leaving connections behind.

**Decisions for you**
- **Returns at the limit:** when a return hits the 99 limit, the removed block is lost. Placement can still remove it from the world, and the reason tells it what to say to the player.
- **Saving:** a failed load leaves the player on the default 20s. When you add saving, it should probably skip those players, or their real saved counts will be overwritten. Right now the module doesn't record whether a load failed, so the saving change will need to add that.