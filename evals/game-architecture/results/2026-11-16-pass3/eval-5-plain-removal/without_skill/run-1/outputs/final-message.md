Players can now remove blocks they placed, by right-clicking on PC or long-pressing on a phone or tablet. The type check, selene and stylua all pass with no errors. I haven't run it in Studio, though, since this project can't reach Studio. So removal and the PC camera-drag handling haven't been seen working in a live game yet.

**Server** (`src/ServerScriptService/BlockPlacement.server.luau`)
- There's a new `RemoveBlock` remote that takes the block to remove.
- **Ownership:** when a block is placed, the server records who placed it (by their user ID) in its own table, and removal checks against that. Each block also gets an `OwnerUserId` attribute, but the client only uses it to skip blocks that aren't theirs. The server never trusts it. Any part that isn't a placed block is rejected, because it won't be in the table.
- **Reach and rate:** removal uses the same reach (64 studs) and rate (0.1s) checks as placing, now shared between the two. Placing and removing count against one shared timer, so switching between them doesn't let a player act twice as fast.
- **Freeing the cell:** a block's grid cell becomes free again however the block disappears, so the spot can be built on again.
- Because ownership is tied to the user ID, a player who leaves and rejoins can still remove their old blocks.

**Client** (`src/StarterPlayer/StarterPlayerScripts/BlockPlacer.luau`)
- **Right-click:** holding right-click and dragging turns the camera in Roblox, so removal only happens on a quick click (released within 0.4s, with the mouse moving 6px or less). The movement is measured from mouse deltas, because the camera holds the cursor still while you drag. Without this, turning the camera would delete blocks.
- **Long-press:** removal fires when a one-finger long press starts on a block, as long as the touch isn't on the UI.
- `setEnabled(false)` now turns off removing as well as placing.

Nothing has been committed.