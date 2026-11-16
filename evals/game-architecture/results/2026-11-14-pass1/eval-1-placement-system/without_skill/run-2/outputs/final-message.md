I've added block placement as a new system at `src/ServerScriptService/Modules/Systems/Gameplay/PlacementSystem/`, laid out like NotificationSystem. I haven't run it in Studio, and the new spec hasn't run either, since specs only run in Studio. Nothing is committed.

**How it works**
- **Client** (`PlacementClientService`):
  - Keys 1 to 5 pick the block type in BlockTypes catalog order. Brick is selected at the start.
  - A click or a phone tap casts a ray that ignores your own character. If it hits the baseplate or a placed block, it moves half a block out from the face you hit, snaps that point to the grid, and sends the block type name and cell to the server.
  - Clicks on UI and typing in chat are ignored.
- **Server** (`PlacementServerService`): checks every request with `PlacementRules`, then creates an anchored 4-stud part in a new `Workspace.PlacedBlocks` folder. It keeps a map of which cells are filled, and a cell is freed again if its block is destroyed.
- **Server checks** (`Implementation/PlacementRules.luau`), in this order:
  1. No more than 10 accepted placements in any 1-second window, per player.
  2. The block type is a string that exists in the catalog.
  3. The position is a Vector3 with no NaN or infinite parts. This needs its own check because NaN would slip past the distance check.
  4. The server snaps the position to a cell itself rather than trusting the client's cell.
  5. The block's bottom isn't below the top of the baseplate, which is read from `Workspace.Baseplate` when the server starts.
  6. The cell isn't already filled.
  7. The player has a character, and the cell is within 64 studs of its HumanoidRootPart.
- **"Too far" notice**: only a too-far request gets a reply, through `NotificationServerService`. Notices to the same player are limited to one per second so spam-clicking doesn't stack them up. Other rejected requests are dropped without a message.
- **Hiding server code**: `PlacementServerService` and `PlacementRules` are moved out of clients' reach, the same way NotificationServerService is.
- **Test**: `Tests/Specs/PlacementRules.spec.luau` covers each rejection reason, the rate-limit window and cell keys.

**Checks**
- `selene` and `stylua --check` pass.
- `luau-lsp analyze` reports two errors, both in the new spec: it can't find the `PlacementRules` module when the spec requires it. This comes from where the project is sitting, not from the code. The project is in a very deep temp folder, which pushes some file paths past Windows' 260-character limit, and the checker then can't resolve requires of those files. A test file requiring the existing `NotificationServerService` fails the same way. I tried to re-run the check from a copy at a short path, but that command needed approval, which isn't available in this session. Running the check from a shorter folder should clear these two errors.

**Choices you may want to change**
- Keys 6 to 9 are also mapped, but they do nothing until the catalog has more than five types.
- The ray reaches 1000 studs. Only the server's 64-stud check limits where blocks can actually go.
- A tap position is converted to a ray with `ViewportPointToRay`. If taps land a little off on a real phone, this conversion is the first thing to check.

I left a throwaway test file in `Tests/Specs` while chasing the checker problem and deleted it afterwards.