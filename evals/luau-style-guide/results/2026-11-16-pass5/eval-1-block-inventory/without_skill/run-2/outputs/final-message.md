I've written the block inventory module at `src/ServerScriptService/BlockInventory.luau`. It isn't wired into anything yet; requiring it is enough to start tracking. The type checker, selene and stylua all pass with no issues. I couldn't run it in Studio, so the join, load and leave paths haven't been run.

**What placement and the other systems call**

| Function | Use |
|---|---|
| `take(player, blockType)` → `(ok, reason?)` | Placing a block. Fails with `"NoneLeft"` when the player is out of that type. |
| `giveBack(player, blockType)` → `(ok, reason?)` | Removing a block. Fails with `"AtLimit"` when the player already has 99 of that type. |
| `grant(player, blockType, amount)` → `(ok, reason?)` | Daily reward and admin commands. There's no 99 limit; `amount` must be a whole number above 0, otherwise it fails with `"InvalidAmount"`. |
| `getCount(player, blockType)` → `number?` | For the UI. Returns `nil` if the player's counts aren't loaded yet or the type is unknown. |
| `isLoaded(player)` → `boolean` | Whether the player's counts have loaded. |

The failure reasons are exported as the type `BlockInventory.Failure`. Two more apply to `take`, `giveBack` and `grant`: `"NotLoaded"` and `"UnknownBlockType"`.

**Remote calls and timing**
- For a player who hasn't loaded yet or has already left, the changing functions return `false, "NotLoaded"` and `getCount` returns `nil`. Nothing errors.
- Block type and amount are typed `unknown`, so you can pass the raw values from the remote; the module checks them itself.
- Counts are stored per `Player` object, so if a load finishes after the player has left, its result is thrown away. If a player rejoins quickly, an old load can't overwrite their new counts.

**Loading**
- Counts load from the `"BlockInventory"` DataStore under `player_<UserId>`. A failed read is retried up to 3 times, one second apart, before the player falls back to 20 of each type.
- When saved data has a type that's missing or a bad value, that type gets 20 and the other saved counts are kept. Saved counts above 99 are kept, since grants can legitimately put players there.
- If the DataStore itself can't be opened (for example in Studio without API access), it warns and everyone starts with 20 of each.
- Players already in the server when the module is first required are loaded too.

**Decisions for you**
- **Removing at 99:** I read the 99 limit as also stopping refunds, so `giveBack` refuses and the player gets nothing back for that block. Placement decides whether to still remove the block, or you can change `giveBack` to refund past 99 instead.
- **Untyped counts:** inside the module, counts are keyed by plain `string` rather than the `BlockType` union. Importing the union from `BlockTypes.luau` caused type errors in this setup. Only valid type names are ever stored.

**Before saving is added:** a player whose load failed is on the default 20 of each, not their real counts. If that gets saved, it overwrites their real data. The saving change needs to remember which players loaded successfully and skip the rest; this module doesn't record that yet.