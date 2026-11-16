I wrote `src/ServerScriptService/BlockInventory.luau`. It isn't wired into anything yet, and nothing has run it in Studio or a live server, so the DataStore loading and join/leave handling haven't been tested.

**Checks:** selene reports no issues, and the file is formatted with StyLua. I could only run luau-lsp without the Roblox type definitions. With those missing it can't recognise `game`, `Player`, `task` or `warn`, so it reports errors about them. It also flags one line that calls the DataStore, probably for the same reason. Once I'd fixed the one real type error it found, nothing else came up.

**What placement can call:**
- `take(player, blockType)` takes one block and returns `true`, or `false` plus a reason. Reasons are `"NotLoaded"` (still loading or already left), `"InvalidBlockType"` or `"OutOfBlocks"`. Nothing changes when it fails.
- `returnBlock(player, blockType)` gives one back, but won't go past 99. At 99 it returns `false, "AtLimit"` and the block is lost. If you'd rather it fail silently, placement can ignore that reason.
- `grant(player, blockType, amount)` is for the daily reward and admin commands and can go past 99. A zero, negative or fractional amount raises an error, since that would be a bug in the calling code rather than normal gameplay.
- `getCount(player, blockType)` returns the count, or `nil` if the player isn't loaded or the type isn't valid.
- `isLoaded(player)`, plus `MaxCount` and `StartingCount` for the UI.

**How it behaves:**
- **Remote calls:** every function accepts a block type straight from the client and checks it against `BlockTypes`. Calls for players who are still loading or have left return `"NotLoaded"` rather than erroring.
- **Loading:** it tries the DataStore up to 3 times. If all three fail, the player gets 20 of each type and a warning is logged. If the player leaves while their load is still running, the result is thrown away so their counts don't come back.
- **Saved data:** any block type that's missing or has a bad value starts at 20, so new block types reach existing players. Saved counts above 99 are kept, because grants can put them there.
- **Setup:** the join and leave handlers are connected the first time the module is required. Players who are already in the server when that happens get loaded then.

**Before you build on it:**
- **Rewards on join:** a daily reward given right when a player joins can arrive before their counts load, and `grant` will return `"NotLoaded"`. That code will need to wait for `isLoaded` first, or I can add a "loaded" signal.
- **Saving:** if a load fails, the player plays on 20 of each. When saving is added, it should not write those counts back over their real saved data.