I've added block placement as a new system at `src/ServerScriptService/Modules/Systems/Gameplay/BlockPlacementSystem/`. Luau analysis, selene and stylua all pass, but I couldn't run it in Studio from here, so nothing has been playtested yet. Nothing is committed: `git status` shows only the new folder.

**How it plays**
- **Choosing a block:** keys 1–5 pick the block type in the order of the `BlockTypes` catalog. Brick is selected at the start.
- **Placing:** clicking (or tapping) the baseplate or a placed block sends a request for the grid cell next to the face you clicked. Clicks on anything else, like the SpawnLocation, are ignored.
- **The server's checks**, in this order:
  1. No more than 10 requests per second per player. Every request counts toward this, including ones that get rejected, so spamming bad requests also hits the limit.
  2. The block type is real.
  3. The position is a real number on the grid.
  4. The cell is not below the top of the baseplate.
  5. The player has a character, and the cell is within 64 studs of it.
  6. The cell is empty.
- **Too far:** the player gets a notification through the existing NotificationSystem. Other rejections are silent for now.
- **Placed blocks** go into a `Workspace.PlacedBlocks` folder.

**Files**
- **`SystemPackage`**:
  - `BlockPlacementSharedService` holds the block types, block size, baseplate, and the grid math.
  - `BlockPlacementServerService` runs the server checks and only exists on the server.
  - `BlockPlacementClientService` handles input and only runs on the client.
  - The other two files define the `PlaceBlock` remote and shared types.
- **`Implementation`**:
  - `_BlockPlacementSetup` gives the system the `BlockTypes` catalog and the baseplate.
  - `_BlockPlacementNotificationMediator` sends the "too far" message.

**Review changes:** I had a reviewer go over the system, and it found no blockers. I made these changes from its findings:
- **Empty-cell check:** the server now also checks for any part already in the cell, not just blocks it placed. Without this, a block could go inside the spawn pad or on top of another player to trap them. This also means a block can't be placed where any character is standing, including the player's own.
- **Requires:** the two `Implementation` modules now load files from their own system by relative path.

**To check when you playtest**
- **Phone taps:** I'm not fully sure how Roblox measures tap positions on screen. The code follows Roblox's documented example, but if it's wrong, taps will land one top-bar height off. Tap near the top edge of a block's side face and check the new block goes beside it.
- **Touchscreen PCs:** one tap might count as both a tap and a click and send two requests. The server would reject the second because the cell is already filled, so it's harmless.

**Decision for you:** nothing limits how many blocks a player can place in total, and blocks stay after the player leaves. Staying under the rate limit, one player could still place about 36,000 parts an hour. Do you want a per-player cap, or cleanup when a player leaves?