I added block placement as a new system at `src/ServerScriptService/Modules/Systems/Gameplay/BlockPlacementSystem`. StyLua and selene pass on it, but it hasn't been run in Studio or type-checked yet.

**How it works for players**
- **Clicking and tapping:** a mouse click or phone tap on the baseplate or a placed block asks the server to place a block in the cell next to the face that was hit. Phones use the tap-in-world event, so dragging to move the camera doesn't place anything.
- **Choosing a type:** keys 1 to 5 pick Brick, Dirt, Grass, Window and Wood, in `BlockTypes` order. Brick is selected when you join. The key list goes up to 9, but only keys that have a matching block type do anything.

**What the server checks on every request**
- The block type is a real name from the catalog.
- The position is a valid number sitting on the grid. Missing or infinite values are rejected.
- The cell isn't below the top of the baseplate. That height is worked out from the baseplate's own size and position, not typed in.
- The player hasn't placed 10 blocks in the last second. This is a sliding window, so no one-second stretch can ever hold more than 10.
- The player has a character and the cell centre is within 64 studs of it.
- The cell isn't already taken. When a placed block is destroyed, its cell frees up again.

When a spot is too far away, the player gets the notification "That spot is too far away to build." Other rejections are silent for now, but `OnPlacementRejected` passes a reason for each one, so you can add messages later. Placed blocks go into a `Workspace.PlacedBlocks` folder.

**Files**
- `SystemPackage/`: `BlockPlacementTypes`, `BlockPlacementNetwork` (one `PlaceBlock` remote), `BlockPlacementSharedService`, `BlockPlacementServerService` (server-only, all the checks) and `BlockPlacementClientService` (client-only, input).
- `Implementation/`:
  - `_BlockPlacementSetup` loads the `BlockTypes` catalog and block size on both server and client.
  - `_BlockPlacementServerSetup` marks the baseplate as buildable and sets the 64-stud and 10-per-second limits.
  - `_BlockPlacementNotificationMediator` sends the too-far notification through `NotificationServerService`, so neither system requires the other.

**Not verified yet**
- **Type check:** I tried to build the place with Rojo and type-check it with luau-lsp, but that command needed a permission approval this session can't give, so it was blocked.
- **Studio:** there's no Studio connection here. The relocation check and a playtest still need doing. In the playtest output, nothing about these modules should show up in `>> Failed` or `Skipping :Start()` lines. Then test clicking and tapping, a far-away spot (the notification should appear) and spam-clicking.

**Existing issue, not changed:** NotificationSystem's two `init.meta.json` files set `IconTint` as a bare array. Rojo 7.6 and later rejects that form (this project uses 7.7.1), so those folder tints may fail to sync. The new folders use the form Rojo accepts, `{ "Color3": [...] }`. I can fix the old two if you want.