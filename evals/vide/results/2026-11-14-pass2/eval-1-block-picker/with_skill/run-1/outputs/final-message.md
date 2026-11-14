I've added the hotbar. Static checks pass: luau-lsp reports 0 errors and 0 warnings, and selene and stylua are clean. I haven't been able to run it, because no Studio connection is available here and the story check and playtest need one.

**How it behaves**
- Five slots sit along the bottom centre, one per block in `BlockTypes.List`, in the same order. Each slot shows a colour swatch and the block's name (the Window swatch is see-through, like the block).
- The selected slot is brighter and has a white outline.
- Clicking or tapping a slot selects that block. The tap doesn't also place a block, because BlockPlacer already skips input that the UI has handled.
- The hotbar follows the number keys: it listens to `BlockPlacer.BlockTypeChanged`, so the selection lives in one place.
- Small 1 to 5 key labels show in the slot corners on PC. They're hidden when touch is the main input, and they switch live if that changes.
- Slots are 64 pixels, comfortably big enough for a thumb. The whole UI grows on screens bigger than 1080p and keeps its size on phones.

**Files**
- `Hotbar.luau`: the hotbar itself. It only draws what it's given, so it doesn't depend on BlockPlacer.
- `HotbarScreen.luau`: builds the on-screen hotbar and keeps it in sync with BlockPlacer.
- `Screen.luau`: tracks screen size and whether the player is on touch, so the layout reacts when either changes.
- `Main.client.luau`: shows the hotbar before `BlockPlacer.start()`, which waits for the server. I also switched this file to the style the new files use, turned on Vide's strict mode in Studio (this is the project's first Vide entry point), and added `--!strict`.
- `src/ServerScriptService/Stories/`: a storybook and `Hotbar.story` with two controls, ShowKeyHints and LongNames. The project doesn't have the UI Labs utility package, so the controls are plain values. That means UI Labs can't group or order them, and the two may swap places between reloads.

**Please check in Studio**
1. Open `Hotbar.story` in UI Labs. Click the slots, then turn on LongNames: long names should get cut off with an ellipsis inside the slot rather than spilling out.
2. Playtest on PC. Press 1 to 5 and click slots; the outline should follow both, and the blocks you place should match.
3. Emulate a small phone (667 by 375). The hotbar should sit between the thumbstick and the jump button, and tapping a slot should select without placing a block. One thing to watch: the left slots fall inside the area where the thumbstick appears. I haven't checked whether a tap there reaches the slot or starts the thumbstick. If it starts the thumbstick, the hotbar needs to move or shrink on touch.

Nothing is committed.