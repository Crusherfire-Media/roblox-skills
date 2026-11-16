Players can now remove their own blocks: right-click a block on PC, or long-press it on a phone or tablet. luau-lsp, selene and stylua all pass. I haven't tested it in Studio, so nobody has tried it in a real game yet.

**Server** (`src/ServerScriptService/BlockPlacement.server.luau`)
- There's a new `RemoveBlock` RemoteEvent next to `PlaceBlock`. The client sends the block part it wants gone.
- When a block is placed, the server saves the placer's UserId and the block's grid cell in a table only the server can see. Clients can't change it.
- Before removing a block, the server checks:
  - **Ownership:** it must be a block from this system, and the sender's UserId must match the saved owner.
  - **Rate:** the same 0.1s minimum gap as placing. Placing and removing share one timer, so switching between them can't get round the limit.
  - **Reach:** the same 64-stud limit from the character to the block.
- A removed block frees its grid cell, so something can be built there again.
- I moved the rate and character checks into two small functions that both actions use, so placing and removing can't drift apart.
- Ownership goes by UserId, so a player who leaves and rejoins can still remove the blocks they placed before.

**Client** (`src/StarterPlayer/StarterPlayerScripts/BlockPlacer.luau`)
- **PC:** holding the right mouse button and dragging turns the camera in Roblox. So a block is only removed on release, and only if the mouse moved 4 pixels or less while the button was down. Turning the camera won't delete blocks by accident.
- **Phone or tablet:** a long press removes the block under the finger. Taps still place blocks as before.
- The client only sends the request if the press lands on a block. The server still makes the real decision.
- `setEnabled(false)` now turns off removing as well as placing, and its doc comment says so.

**Worth checking in Studio:**
- The right-click handler skips presses that Roblox marks as already used by the game. I expect the default camera to leave right-click alone, but if right-click does nothing in a playtest, that's the first place to look.
- Long-pressing someone else's block does nothing and gives no feedback.

I needed to regenerate `sourcemap.json` before luau-lsp would pass, because the old one couldn't resolve existing requires. My first try ran all the checks in one command, and that was blocked because this session can't approve commands. Running each check on its own worked. Nothing is committed.