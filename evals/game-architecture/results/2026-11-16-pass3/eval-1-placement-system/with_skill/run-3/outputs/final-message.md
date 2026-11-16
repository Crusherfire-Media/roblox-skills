I've added block placement as a new system at `Systems/Gameplay/BlockPlacementSystem`. The type check, selene and StyLua all pass. I haven't playtested it, because there's no Studio connection in this session, so clicking, tapping, the notification and the loader's startup log are all untested in-game.

**How it works**
- **Placing:** clicking with the mouse or tapping on a phone sends a request when the click hits the baseplate or a block someone placed. The target is the cell next to the face you clicked. Clicks on anything else, such as the SpawnLocation or another player, do nothing.
- **Selecting:** keys 1 to 5 pick Brick, Dirt, Grass, Window and Wood, in catalog order. Brick is selected at the start.
- **Server checks:** the server checks every request in this order:
  1. No more than 10 requests in any one-second window per player. Requests that get rejected also count toward the 10.
  2. The block type name exists in the catalog.
  3. The position is a real `Vector3`, with no NaN or infinite values. The server then snaps it to a cell itself rather than trusting the client.
  4. The block isn't below the top of the baseplate.
  5. The player has a character, and the cell is within 64 studs of it.
  6. The cell isn't already filled. A cell frees up again when its block is destroyed.
- **Too far:** the player gets a notification through the existing NotificationSystem. It shows at most once every 2 seconds, so clicking out of reach repeatedly doesn't pile up messages.

**Files** (all under `BlockPlacementSystem/`)
- `SystemPackage/` holds the game-independent part:
  - `BlockPlacementSharedService` holds the block types, grid size and floor.
  - `BlockPlacementServerService` (server only) does the checks and creates the blocks.
  - `BlockPlacementClientService` (client only) handles input.
  - Also: the `PlaceBlock` remote and the shared types.
- `Implementation/` holds this game's wiring:
  - `_BlockPlacementSetup` gives the system the `BlockTypes` catalog and `Workspace.Baseplate`.
  - `_BlockPlacementNotificationMediator` (server only) sends the too-far notification. The placement code never calls the notification system directly; it only reports why a request was rejected.

A review of the change found no blocking problems. I made the two small fixes it suggested: requests from a player who is leaving are now ignored, and only keys 1 to 5 select a block type.

**Decisions for you**
- **No block limit:** there's no cap on how many blocks exist, and blocks stay when their player leaves. At 10 a second, one player can add 600 blocks a minute. Should I add a per-player cap, or remove blocks when their player leaves?
- **Blocks can float:** a block doesn't need to touch anything, apart from the click having to land on the baseplate or a block. Blocks can also be placed where they overlap the SpawnLocation or a player.
- **No tests yet:** to test the server checks I'd need to make the check function public on the server service. Do you want that?
- **Possible problem in existing code:** the NotificationSystem's folder tints use the plain `[r, g, b]` form, which Rojo 7.6 and later rejects (this project uses 7.7.1). The new system's folders use the `{ "Color3": [...] }` form. I left NotificationSystem alone.

Nothing is committed.