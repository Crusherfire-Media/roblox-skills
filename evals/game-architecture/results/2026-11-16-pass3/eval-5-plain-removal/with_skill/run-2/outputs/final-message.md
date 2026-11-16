Players can now remove their own blocks by right-clicking on PC or long-pressing on a phone or tablet. StyLua, selene and luau-lsp all pass with no errors. I haven't tested it in Studio, and nothing is committed.

**Server** (`src/ServerScriptService/BlockPlacement.server.luau`)
- There's a new `RemoveBlock` remote. The client sends it the block it clicked.
- **Who placed it:** the server now records, for each block it places, the grid cell and the placer's UserId. A remove request goes through only if the block is in that record and the requester placed it. Anything else a client sends, like the baseplate or another player's block, is ignored.
- **Reach and rate:** removing uses the same reach check (64 studs) and the same 0.1s limit as placing. I pulled both checks into small helpers so placing and removing run the identical code.
- After a removal, the cell is free again for anyone to build in.

**Client** (`src/StarterPlayer/StarterPlayerScripts/BlockPlacer.luau`)
- **Right-click:** only a quick click removes a block (released within 0.3s, moved no more than 5 pixels). Holding the right mouse button also turns the camera, so without this, turning the camera while pointing at a block would delete it.
- **Long-press:** removes the block when the press starts, as long as it's one finger and not on top of the UI. A normal tap still places a block.
- It only asks the server when the ray actually hits a block in the `Blocks` folder.

**Decisions for you:**
- **One shared rate limit:** placing and removing count against the same 0.1s limit. Otherwise, alternating place and remove would let a player act twice as often. Separate limits are a small change if you'd rather have them.
- **Keyed by account:** ownership is tied to the player's UserId, so someone who leaves and rejoins can still remove their old blocks.
- **`setEnabled(false)` now blocks removing too:** I assumed that when something like an open menu turns building off, removing should be off as well.
- **No warning on others' blocks:** right-clicking someone else's block does nothing, with no message. If you want a message or a highlight on removable blocks, the client would need to know who owns each block, for example through an attribute on the part.