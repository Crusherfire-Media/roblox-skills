I fixed all three problems in `PlacedBlocks.luau` and `BuildHud.luau`, plus two other Charm mistakes I found. I couldn't run anything to check it: my formatter and lint step was blocked by the permission check, and I haven't played it in Studio. Please run `stylua` and `selene` on those two files.

**1. "Blocks placed" stuck at 0** (`PlacedBlocks.luau`)
Placing a block added to the history table in place and then stored the same table again. Charm only notices a change when it gets a different table, so the count never updated. In Studio, Charm also locks stored tables, which is where the "readonly table" error came from; live servers skip that lock, so it just failed silently. Placing a block now copies the history, adds the new entry and stores the copy. `clear()` stores a new empty table instead of emptying the old one.

**2. "Last:" always showing "none"** (`BuildHud.luau`)
The label read the last-placed value straight from Charm, and the UI library only updates labels for values it tracks itself, so the label kept its first value. It now goes through `useSignalState`, the bridge the count label already used.

**3. One extra click each time you toggle the HUD with H** (`BuildHud.luau`)
The HUD started a Charm listener for the sound every time it was shown, and nothing stopped it when the HUD was hidden, so listeners piled up. It's now wrapped in `cleanup(...)`, so it stops when the HUD hides.

**Also fixed:**
- **Same block twice made no sound.** The click listened for a change in the last block type, so placing the same type twice in a row stayed silent. It now listens to the block count and clicks whenever the count goes up. Pressing Clear drops the count, so it doesn't click.
- **Two updates per placement.** Placing a block and pressing Clear each change two values, which made the HUD update twice. Both now go through `Charm.batch`, so it updates once.

The HUD's layout, look and Clear button are unchanged.

Two things I noticed but didn't change:
- **No UI Labs stories:** the project has none set up, so I didn't add one for the HUD.
- **Vide strict mode is off:** `Main.client.luau` doesn't set `Vide.strict = RunService:IsStudio()`, which would catch mistakes like these in Studio sooner.