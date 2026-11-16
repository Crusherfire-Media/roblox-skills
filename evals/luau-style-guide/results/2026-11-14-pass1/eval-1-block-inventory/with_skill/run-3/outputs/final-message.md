I've written `src/ServerScriptService/BlockInventory.luau`. StyLua, selene and luau-lsp all pass on it with no errors. I haven't run it in Studio and wrote no Jest spec for it, so it's untested in play. Nothing else was changed, and nothing is committed.

**What placement can call**
- `BlockInventory:TakeBlock(player, blockType)` takes one block when a player places one. It returns `true, nil` on success. On failure it returns `false` and a reason:
  - `"NotLoaded"`: the player's counts haven't loaded yet, or the player has left.
  - `"OutOfBlocks"`: they have none of that type left.
- `BlockInventory:ReturnBlock(player, blockType)` gives one block back when a player removes one. It fails with `"NotLoaded"`, or with `"AtLimit"` if they already hold 99 of that type.
- `BlockInventory:GrantBlocks(player, blockType, amount)` is for the daily reward and admin commands. It ignores the 99 cap. It fails only with `"NotLoaded"`, and errors if `amount` isn't a whole number of 1 or more.
- `BlockInventory:GetCount(player, blockType)` is for the UI. It returns the count, or `nil` if counts aren't loaded yet or the player has left.

The reasons are exported as the types `TakeFailure`, `ReturnFailure` and `GrantFailure`.

**How it behaves**
- **On join:** it loads the player's counts from the "BlockInventory" DataStore under `player_<UserId>`. New players, and players whose load fails, get 20 of each type; a failed load also logs a warning.
- **Bad or partial saved data:** any saved count that isn't a whole number of 0 or more is replaced with 20. So is any type missing from the save, which means a block type added later starts at 20 for existing players. Saved counts above 99 are kept.
- **On leave:** counts are dropped. If a player leaves while their load is still running, the result is thrown away, so it can't come back as a leftover entry.
- **When it starts tracking:** it starts when it's first required, including players who joined before that. It connects nothing when required outside a running game.

**Things the next changes need to handle**
- **Saving:** a player whose load failed is playing on the default 20s. If the save change writes those back, it will overwrite their real saved data. Saving needs to skip those players, or retry the load first.
- **Block type from the remote:** placement must check it with `BlockTypes.isBlockType` before calling these functions. Passing an unknown type raises an error rather than returning a failure.
- **Removing at the cap:** when `ReturnBlock` fails with `"AtLimit"`, placement has to decide whether the block is still removed without a refund or the removal is refused. I didn't make that choice for it.

Two of my commands were denied because this session can't approve permission prompts. One read files outside the project folder; the other ran all the checks as a single command. I ran each check separately instead, so nothing was skipped.