I've added the hotbar. The type check, lint and format checks all pass, but I couldn't run it in Studio from here, so nobody has seen it on screen or tested it on a phone yet. I haven't committed anything.

**How it works**
- It shows the five blocks from `BlockTypes` in hotbar order. Each slot has a color swatch, and the Window swatch is see-through like the block. The selected block's name sits above the bar.
- The selected slot gets a white outline and a lighter background. Clicking or tapping a slot calls `BlockPlacer.setBlockType`.
- **Staying in sync:** the hotbar listens to `BlockPlacer.BlockTypeChanged`, so it follows the selection however it changes, number keys included. `BlockPlacer` is still the only place that holds the selection.
- **Clicks on the hotbar don't place blocks.** Roblox marks a click on a button as handled, and `BlockPlacer` already ignores handled input and taps on UI, so I didn't change it.
- **Phones:** on touch screens and small windows the slots shrink from 64 to 52 pixels, which is still big enough for a thumb. When Roblox's touch controls are showing, the bar sits between the thumbstick area and the jump button, so it doesn't land under either.
- **PC:** each slot shows its number key (1 to 5) in the corner. These are hidden on touch screens.
- On screens taller than 1080 pixels the whole HUD scales up so it doesn't look tiny.

**Files** (all in `src/StarterPlayer/StarterPlayerScripts/` unless noted)
- `Hotbar.luau`: the hotbar itself.
- `BlockHud.luau`: the on-screen HUD that connects the hotbar to `BlockPlacer` and positions it.
- `Screen.luau`: tracks screen size and whether touch is the main input, updating live.
- `Main.client.luau`: now builds the HUD before calling `BlockPlacer.start()`. It also turns on Vide's strict mode in Studio, which catches mistakes in UI code earlier.
- `src/ServerScriptService/Stories/`: a storybook and `Hotbar.story` for previewing the hotbar in UI Labs, with switches for the compact size and the key labels.

**Worth knowing**
- The new files follow the project's existing style (`local`, requires like `require(script.Parent.X)`, no `--!strict` header) rather than my usual style rules, so they match the code already there.
- The touch-control positions are hard-coded from Roblox's default controls. If you change movement mode or use custom controls, the bar may need moving.
- The UI Labs helper package isn't installed, so the story's switches may show up in a different order each reload. Adding that package would fix it.

**Please check in a playtest**
1. On PC, keys 1 to 5 move the highlight and the name. Clicking a slot selects it without placing a block.
2. In the device emulator on a small phone (667×375) and a tablet, the bar sits clear of the thumbstick and jump button, and tapping a slot selects without placing.
3. Switching devices during the playtest moves and resizes the bar to match.