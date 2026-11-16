I've added block placement as a new system, `Systems/Gameplay/BlockPlacementSystem`, laid out the same way as `NotificationSystem`. I haven't run it in Studio and the specs haven't been run, so nothing has been tested in play yet. Selene and stylua pass, and luau-lsp reports no errors except one environment problem, covered below.

**What I added**
- **`SystemPackage/BlockPlacementClientService`** (client only): left-click, or a tap on a phone, sends a ray from the camera. If it hits the baseplate or a placed block, the client works out the grid cell next to the face it hit and asks the server for a block there. Keys 1–5 pick the block type in `BlockTypes.List` order, and Brick is selected at the start. Taps only count as placements, not drags that move the camera or thumbstick. Keys and clicks are ignored while the player is typing in chat.
- **`SystemPackage/BlockPlacementServerService`** (server only): handles placement requests, keeps its own record of which cells are filled, and puts blocks in `Workspace.PlacedBlocks`. If something else removes a block, its cell becomes free again.
- **`Implementation/BlockPlacementRules`** (server only): all the request checks, with no game state, so specs can test them directly. In order:
  1. **Rate limit:** at most 10 requests per player per second.
  2. **Block type:** must be a name from the catalog.
  3. **Position:** must be a Vector3 with finite coordinates inside the world limits. The server snaps it to a grid cell itself.
  4. **Height:** the cell can't go below the baseplate top, which is read from `Workspace.Baseplate`.
  5. **Filled cell:** the cell must be empty.
  6. **Reach:** the player needs a living character, and the cell centre must be within 64 studs of it.

  If the spot is too far, the player gets a notification through `NotificationServerService`, at most once a second so spam-clicking doesn't pile them up. All other rejections are silent.
- **`BlockPlacementNetwork`**: one `PlaceBlock` RemoteEvent.
- **`BlockPlacementConstants`**: names both sides use (the placed-blocks folder, the block-type attribute and the baseplate).
- **`Grid.toCellIndex`**: a small helper added to the existing Grid utility.
- **`Tests/Specs/BlockPlacementRules.spec.luau`**: Jest specs for each check and for the rate window. Specs only run in Studio.

**Decisions for you**
- **Rate limit counts every request, not just successful placements.** This stops junk requests from getting through faster than real ones. A real player can't click 10 times a second anyway, but say if you want it to count only placements.
- **The server doesn't check that a block is touching something.** Someone with a modified client could place floating blocks, as long as they pass all the checks above. It's a short addition to `BlockPlacementRules` if you want it.
- **Only blocks from this system count as filling a cell.** A player could place a block overlapping the SpawnLocation or another part in the world.

**luau-lsp problem:** luau-lsp can't follow the spec's `@game/...` require of `BlockPlacementRules`, so it reports "Unknown require". I tested this with a temporary file (now deleted): the existing `NotificationServerService` fails the same way. luau-lsp breaks on Windows paths over 260 characters, and this project sits in a very deep temp folder, so this is a tooling limit rather than a code problem. Because of it, types across modules couldn't be fully checked here; running luau-lsp from a shorter path should clear it.

Two commands were blocked by the permission system: a file listing and a cleanup command. Neither affected the result.