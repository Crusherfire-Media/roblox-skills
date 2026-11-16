I've added block placement as a new system at `Systems/Gameplay/BlockPlacementSystem`. None of it has been run: tool commands were blocked here, so I couldn't run luau-lsp, StyLua or Rojo myself, and there has been no playtest. A reviewer agent ran selene (clean) and StyLua, which flagged one line that I've since fixed. Its type check was blank only because the sourcemap is out of date, so the new files haven't been type-checked yet.

**How it plays**
- **Clicking:** a left click on the baseplate or a placed block requests a block in the cell next to the face you clicked. Clicks that land on UI are ignored, and so is anything else you hit, like another player.
- **Phones:** taps work the same way. Dragging to pan the camera doesn't place anything.
- **Choosing a block:** keys 1 to 5 pick Brick, Dirt, Grass, Window, Wood (the BlockTypes order). Brick is picked at the start. Keys pressed while typing in chat are ignored.

**What the server checks** on every request (`BlockPlacementServerService.luau`):
- **Rate limit:** at most 10 requests per player in any one second. This runs first and counts refused requests too, so spam is turned away cheaply.
- **Block type:** the name must be a string of sane length that exists in `BlockTypes.ByName`.
- **Position:** the coordinates must be real numbers (not NaN), no more than 100,000 studs from the origin, and on the 4-stud grid.
- **Below the baseplate:** the block's bottom can't be lower than the baseplate's top.
- **Filled cells:** a cell that already has a placed block is refused. The cell frees up again if that block is destroyed.
- **Distance:** the cell's center must be within 64 studs of the character. If the player has no character, the request is refused.
- **Too far:** if the spot is too far away, the player gets the notification "That spot is too far away to build." Other refusals are silent.

**Files**
- `SystemPackage`:
  - the shared grid rule (`BlockPlacementSharedService`).
  - the server service.
  - the client input service.
  - the network module with a `PlaceBlock` remote.
- `Implementation`:
  - `_BlockPlacementSetup` passes in the 64-stud reach and the 10-per-second limit, and uses `Workspace.Baseplate` as a clickable surface and as the floor.
  - `_BlockPlacementNotificationMediator` sends the "too far" notification, so the two systems never require each other.
- Server-only modules are flagged to stay on the server and the client service is flagged client-only; folder tints are set.
- Placed blocks go in a new `Workspace.PlacedBlocks` folder.

**Before you merge**
1. Run `rojo sourcemap ...`, then the README's luau-lsp, selene and StyLua commands. Then playtest and check the output has no `>> Failed` lines.
2. In the device emulator, tap the edge of a block. I couldn't confirm which screen coordinates Roblox gives for taps. If they're the other kind, phone taps will land about one top-bar height off; the fix is a one-word change in `BlockPlacementClientService.luau`.
3. The new code uses `const` and `--!strict`, as your style guide asks, but the existing modules use `local`. If the checks reject `const`, swap it back to `local`.

**Decisions for you**
- **Block limit:** nothing caps or clears placed blocks, so one player spam-clicking could fill the server over a long session. Do you want a limit per player or per server?
- **Tests:** there are no tests for the server checks yet, and the checks can only be reached through the remote. Adding a public method for the handler would let tests cover each check. Should I add the method and the tests?
- **Folder colors:** the existing NotificationSystem folders write their colors in a format the Rojo reference says Rojo 7.6+ rejects. I used the accepted format for the new folders and left the old ones alone.

Nothing is committed.