Players can now remove blocks they placed. I haven't run or tested any of it: my first shell command was blocked for needing approval, so I couldn't run a type-checker, linter or Studio session. The changes below were written by reading the code only.

**Server (`BlockPlacement.server.luau`)**
- There's a new `RemoveBlock` remote. The client sends it the block it wants removed.
- **Owner only:** when a block is placed, the server records who placed it (by user ID) and which grid cell it fills. A remove request is ignored unless the block is one the server placed and the requester is its owner. Each block also carries an `OwnerUserId` attribute, but the server never trusts that; the client uses it only to skip requests that would be refused anyway.
- **Same checks as placing:** a removal must be within the same 64-stud reach of the player's character, and the same 0.1-second rate limit applies. I shared that one limit between placing and removing, so a player can't double their speed by alternating the two. That slightly changes placing: a place right after a remove can now be refused.
- When a block is removed, its cell is freed so something can be placed there again. This also happens if a block is destroyed some other way.

**Client (`BlockPlacer.luau`)**
- **PC:** a quick right-click removes a block. In Roblox, holding right-click and dragging turns the camera, so removal only happens if the button is released within 0.3 seconds and the mouse moved no more than 6 pixels. You can change these via `RIGHT_CLICK_MAX_DURATION` and `RIGHT_CLICK_MAX_MOVE`.
- **Phone or tablet:** a one-finger long-press removes a block.
- Clicking other players' blocks or anything that isn't a placed block does nothing. `setEnabled(false)` now turns off removing as well as placing.

**Worth checking in Studio:**
- Right-dragging the camera should not remove blocks.
- A long-press on a phone should not also place a block.
- You should not be able to remove another player's block.

One more thing: ownership is stored by user ID, so a player who leaves and rejoins the same server can still remove blocks they placed earlier.