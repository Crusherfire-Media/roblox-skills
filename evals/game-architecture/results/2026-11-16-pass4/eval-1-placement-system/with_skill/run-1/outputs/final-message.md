I've added block placement as a new system at `src/ServerScriptService/Modules/Systems/Gameplay/BlockPlacementSystem/`. It passes luau-lsp, selene and StyLua, but I haven't playtested it in Studio, so it hasn't been run in a game yet.

**How it works**
- **Placing:** clicking (or tapping on a phone) the baseplate or a placed block asks the server to place the selected block in the grid cell next to the face you hit. Phones only place on a tap, so dragging to turn the camera never places a block.
- **Choosing a block:** keys 1 to 5 select a block type in BlockTypes catalog order. Brick is selected at the start.
- **Server checks**, in this order. A failed check refuses the request:
  1. No more than 10 requests in any one-second window per player.
  2. The arguments are a string and a `Vector3` with no NaN or huge numbers.
  3. The block type exists in the catalog.
  4. The position is exactly the center of a grid cell.
  5. The block isn't below the top of the baseplate.
  6. The cell is within 64 studs of the character.
  7. The cell isn't filled.
- **Notification:** when a spot is too far away, the player gets "That spot is too far away." through the existing NotificationSystem. Other refusals are silent.

**Files**
- **`SystemPackage`** is the generic part:
  - `BlockPlacementSharedService` stores the settings (block types, block size and baseplate) that both server and client read.
  - `BlockPlacementServerService` does the checks and creates blocks in a `Workspace.PlacedBlocks` folder.
  - `BlockPlacementClientService` handles input.
  - `BlockPlacementNetwork` holds the `PlaceBlock` remote, and `BlockPlacementTypes` holds the shared types.
- **`Implementation`** holds the game-specific wiring:
  - `_BlockPlacementSetup` passes in the BlockTypes catalog and `Workspace.Baseplate`.
  - `_BlockPlacementNotificationMediator` sends the notification, so the two systems never require each other.

**Changes after the review subagent**
- **Rate limit:** the first version could let through about 19 placements in under a second. It now uses a strict one-second window.
- **Baseplate missing:** the server now refuses every request until the baseplate is set up, instead of skipping the floor check.
- **Filled cells:** besides placed blocks, "filled" now covers any part in the cell, such as the SpawnLocation or a player's character. This stops players from trapping themselves or others inside a block.
- **No character:** a player who is dead or respawning no longer gets the wrong "too far" message.

**Still open**
- **Phone taps:** the server side doesn't depend on it, but on phones a tap could place the block slightly off where the finger was. I'm not certain the tap position uses the coordinates the code assumes, so it's worth a quick test in Studio's phone emulator.
- **No block limit:** blocks can't be removed and there's no cap, so one player at 10 per second could add about 36,000 parts an hour. The task didn't ask for a cap, so I didn't add one.
- **Possible Rojo error in NotificationSystem:** its `init.meta.json` files write `IconTint` as a bare array. This project uses Rojo 7.7.1, and Rojo 7.6 and later reject that form. Generating the sourcemap worked, but `rojo serve` or `build` may fail on those files. I used the accepted form for the new folders and left NotificationSystem as it was.

**What you should check in a playtest:** the output log should have no `>> Failed` or `Skipping :Start()` lines for these modules. Watch `BlockPlacementTypes` in particular: it returns `nil`, and I haven't confirmed the Module Loader accepts that quietly.

Nothing is committed.