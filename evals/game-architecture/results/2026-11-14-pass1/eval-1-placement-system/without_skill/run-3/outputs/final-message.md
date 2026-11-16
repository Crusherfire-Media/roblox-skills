Block placement is added as a new system, `Systems/Building/PlacementSystem`. It's laid out like `NotificationSystem` and Module Loader picks it up without any changes to the two Main scripts. I haven't run it in Studio, and the new Jest spec hasn't been run either: specs only run in Studio, which this project can't reach. selene and stylua pass. The luau-lsp type check is clean except for two errors in the new spec, explained below.

**Files (all under `SystemPackage/`):**
- **`PlacementNetwork`**: the `PlaceBlock` remote (sends a block type name and a cell position) and the name of the `Workspace.Blocks` folder. It's shared by the server and the phone/PC client.
- **`PlacementClientService`** (client only):
  - Keys 1–5 choose `BlockTypes.List[1..5]`.
  - A left click places a block. On a phone, a touch counts as a tap if it lasts under 0.3 s and moves under 10 px, so dragging the camera doesn't place blocks.
  - It works out which spot was clicked, but only the baseplate and placed blocks count. The new block goes in the grid cell next to the clicked block face, or on top of the baseplate.
  - The client doesn't check distance itself, so the server can be the one to say "too far".
- **`PlacementServerService`** (server only) checks every request in this order:
  1. **Rate limit:** at most 10 requests per player in any one-second window. Rejected and invalid requests count too, so spam is cheap to turn away.
  2. **Block type:** must be a string that exists in `BlockTypes.ByName`.
  3. **Position:**
     - It must be a `Vector3` with no NaN or infinite values.
     - It must be within the baseplate's edges and no more than 1024 studs above it.
     - The server snaps it to the grid itself instead of trusting the client's cell.
  4. **Not below the baseplate:** the block's bottom must be at or above the baseplate's top.
  5. **Distance:** within 64 studs of the `HumanoidRootPart`. If it's too far, the player gets the message "That spot is too far away. Move closer to place a block." through `NotificationServerService`, at most once a second.
  6. **Cell is empty:** the server keeps a list of filled cells. A cell frees itself if its block is ever destroyed.

  The new block is an anchored 4-stud part in `Workspace.Blocks`, with `BlockType` and `PlacedByUserId` attributes.
- **`PlacementRules`** (server only): the checks as plain functions. `Tests/Specs/PlacementRules.spec.luau` covers them.

**The two remaining type errors:** luau-lsp says the spec's `PlacementRules` require is unknown, and then that the `WorldBounds` type is unknown. The file path it reports is correct, but it starts with a broken `\?\`, and the full path is longer than 260 characters. That points to a Windows long-path limit in luau-lsp, not a problem in the code. The other modules require `PlacementRules` from the same deep folder and type-check cleanly. I tried to confirm this by checking a copy at a short path, but that command needed approval this session can't give, so it's not proven. Running the check from a shorter project path should settle it.

**Choices you may want to change:**
- The rate limit counts every request, not just successful placements.
- The 1024-stud height cap is my own addition, as part of the position check.
- A block can be placed where a player or the SpawnLocation is standing, since you didn't ask for that check.
- I added an empty `Implementation` folder to match `NotificationSystem`. Delete it if you don't want it.

Nothing is committed.