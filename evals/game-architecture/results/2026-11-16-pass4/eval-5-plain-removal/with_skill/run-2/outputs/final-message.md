I've added block removal: right-click a block on PC, or long-press it on a phone or tablet. Only the player who placed a block can remove it, and the server checks reach and rate before removing, as it does for placing. Formatting, lint and type checks all pass, but I haven't play-tested it in Studio. No spec covers it, and nothing is committed.

**Server (`src/ServerScriptService/BlockPlacement.server.luau`)**
- There's a new `RemoveBlock` remote. It takes the block to remove and treats it as untrusted input, as `PlaceBlock` does.
- The server keeps its own list of the blocks it placed, with each block's cell and owner. It decides ownership from that list, so a client can't remove someone else's block or anything else in the world.
- The reach check (64 studs from the character to the block's cell) is now a shared helper used by both placing and removing.
- **Rate limit:** placing and removing now share one 0.1-second limit per player. That way, switching between the two isn't faster than doing either one alone.
- **Owner is stored by user ID:** a player who leaves and rejoins can still remove their own blocks. I also put an `OwnerUserId` attribute on each block so the client knows which blocks are the player's. The server never trusts that attribute.

**Client (`src/StarterPlayer/StarterPlayerScripts/BlockPlacer.luau`)**
- **Right-click:** holding the right mouse button and dragging already turns the camera. To avoid removing a block every time someone turns the camera, a right press only counts as a removal if the mouse barely moved (6 pixels or less) before release.
- **Long-press:** this uses Roblox's built-in long-press event with one finger, and ignores presses on UI.
- The client only asks the server to remove a block in the `Blocks` folder that has the player's user ID. This just saves sending requests the server would refuse.
- `setEnabled(false)` now turns off removing as well as placing.

**Worth checking in a play test:**
- Right-clicking to remove while you're turning the camera.
- A long-press on touch screens. Roblox's default touch controls might also respond to it, for example by moving the camera.