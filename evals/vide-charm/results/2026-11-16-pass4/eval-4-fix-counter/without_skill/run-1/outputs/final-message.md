I fixed all three bugs, plus one more I found, in `PlacedBlocks.luau` and `BuildHud.luau`. I haven't run anything in Studio or ran any linter, so please test it there.

**1. "Blocks placed" stuck at 0** (`PlacedBlocks.luau`)
The code was changing the history table directly and then passing the same table back to the setter. Charm treats stored values as read-only, which explains both things you saw:
- **In Studio**, Charm locks stored tables, so `table.insert` threw "attempt to modify a readonly table".
- **On live servers** nothing is locked, but Charm only notices a change when it gets a different table. It got the same one back, so the count never updated.

Placing a block now builds a new copy of the history list, and Clear sets a fresh empty `{}` instead of emptying the old table. Each action's two updates (history and last block) are now grouped with `Charm.batch`, so nothing ever sees one updated without the other.

**2. "Last:" always "none"** (`BuildHud.luau`)
The label read `PlacedBlocks.getLastPlaced()` straight from inside a Vide text function. Vide doesn't watch Charm values, so the label only ever showed the starting value. It now goes through `VideCharm.useSignalState`, the same bridge the count label already uses.

**3. One extra click each time you toggle with H** (`BuildHud.luau`)
`Charm.subscribe` returns a function that stops the subscription, and the code never called it. Each time `show` rebuilt the HUD, another sound subscription was added and the old ones kept running. It's now wrapped in `Vide.cleanup(...)`, so it stops when the HUD is hidden.

**4. Extra bug: no click for the same block twice in a row**
The sound was tied to the last block type. Placing the same type twice doesn't change that value, so the second placement was silent. The sound now plays whenever the count goes up. That matches the "click plays each time a block lands" comment in the file, and pressing Clear (which lowers the count) doesn't click.

The HUD's layout, look and Clear button are unchanged.