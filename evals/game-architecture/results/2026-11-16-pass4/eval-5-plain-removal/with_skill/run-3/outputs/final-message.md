Players can now remove blocks they placed: right-click on PC, long-press on a phone or tablet. The server only removes a block if the player who asks is the one who placed it, and it runs the same reach and rate checks as placing. StyLua, selene and luau-lsp all pass. I haven't run it in Studio, so the input handling hasn't been tried in a real game yet.

**Server (`BlockPlacement.server.luau`)**
- There's a new `RemoveBlock` remote. The client sends the block it wants removed.
- The server keeps its own list of placed blocks, recording who placed each one and which grid cell it fills. A removal request is checked against that list, so anything that isn't a placed block, or belongs to someone else, is ignored.
- Placing and removing share one reach check (64 studs) and one rate limit (0.1 s). The limit covers both actions together, so switching between placing and removing doesn't let anyone go faster.
- Removing a block frees its grid cell, so something can be placed there again.

**Client (`BlockPlacer.luau`)**
- **Right-click:** holding the right mouse button also turns the camera. To stop camera turns from deleting blocks, a right-click only counts if the mouse moves less than 4 pixels while the button is held, and the block is removed when the button is released.
- **Long-press:** removes the block at the start of a one-finger long press. Ordinary taps still place blocks.
- The client only sends a request when the player is pointing at one of their own blocks. Each placed block carries an `OwnerUserId` attribute for this, but the server never relies on it.
- `setEnabled(false)` now turns off removing as well as placing.

**Decision for you:** ownership is tied to the player's UserId, so someone who leaves and rejoins can still remove the blocks they placed before. If blocks should only be removable during the session they were placed in, I can tie ownership to that session instead.