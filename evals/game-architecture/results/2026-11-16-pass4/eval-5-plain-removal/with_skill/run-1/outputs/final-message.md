Players can now remove blocks they placed. On PC they right-click the block, and on a phone or tablet they long-press it. The server only removes a block if that player placed it, and removal goes through the same reach and rate checks as placing. StyLua, luau-lsp and selene all pass on both files. I haven't run it in Studio, so it's untested in an actual game.

**Server (`BlockPlacement.server.luau`)**
- There's a new `RemoveBlock` RemoteEvent that takes the block the player wants removed.
- When a block is placed, the server records who placed it and which grid cell it fills. That record is only on the server, so a client can't fake ownership.
- Removal is rejected unless the argument is a block in that record, the player's UserId matches the placer, the 64-stud reach check passes against the block's cell, and the rate limit allows it. If all of that passes, the cell is freed and the block is destroyed.
- I moved the reach and rate checks into helpers that placing and removing both use.

**Client (`BlockPlacer.luau`)**
- **Right-click:** removal happens when the button is released, and only if the mouse moved 4 pixels or less while it was held. Holding right-click and dragging turns the camera, so without this, turning the camera would delete whatever block was under the cursor.
- **Long-press:** handled with `TouchLongPress`. It ignores multi-finger touches and touches the UI already handled.
- Both only fire for parts in `Workspace.Blocks`. Placing and removing share the raycast code.
- `setEnabled(false)` now stops removing as well as placing.

**Choices you may want to change:**
1. **Owner is stored by UserId:** someone who leaves and rejoins the same server can still remove their old blocks. Blocks aren't saved between servers, so ownership doesn't carry over either.
2. **One shared rate limit:** placing and removing count against the same 0.1-second limit, so switching between them is no faster than doing either alone. Separate limits would allow up to 20 actions a second in total.
3. **Other players' blocks:** right-clicking someone else's block sends the request, the server quietly rejects it, and the player sees nothing happen. There's no "not your block" message yet.

I haven't committed anything.