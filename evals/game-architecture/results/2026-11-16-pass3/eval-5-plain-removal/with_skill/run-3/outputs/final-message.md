Players can now remove blocks they placed: right-click on PC, or long-press on a phone or tablet. luau-lsp, selene and stylua all pass, and a review found no problems. I haven't playtested it, though, so there are two input behaviors to check in Studio (below).

**Server** (`src/ServerScriptService/BlockPlacement.server.luau`)
- There's a new `RemoveBlock` remote. The client sends the block it wants gone.
- The server only accepts blocks it placed itself, and only from the same player. It checks this against its own record of who placed each block, not anything the client could change.
- Removing runs the same reach check (64 studs) and rate limit (0.1 s) as placing. The two share one timer, so switching between placing and removing can't get around the limit.
- Removing a block frees its grid cell, so something can be built there again.
- Each block has an `OwnerUserId` attribute. The client uses it to skip asking about other players' blocks, but the server never trusts it.

**Client** (`src/StarterPlayer/StarterPlayerScripts/BlockPlacer.luau`)
- **Right-click:** removal happens when the button is released, and only if the mouse barely moved (4 px or less) while it was held. Holding the right button and dragging turns the camera, and without this check every camera turn over a block would delete it.
- **Long-press:** removes the block under the finger when the press is recognized. Touches on UI are ignored.
- `setEnabled(false)` now turns off removing as well as placing.

**To test in Studio**
- **Right-click on PC:** removal needs the default camera script to pass right-clicks through to game scripts. If it doesn't, right-click will do nothing.
- **Long-press on a phone:** check that a long press doesn't also count as a tap. If it did, it would place a new block next to the one being removed.

There are no automated tests. The rules live in a server Script, which tests can't reach, and tests can't run in this project without Studio. Covering removal with tests would first mean moving those checks into a module.

Nothing is committed.