I wrote the server side in `src/ServerScriptService/Placement.server.luau`. The README's checks all pass: `selene`, `stylua --check` and `luau-lsp analyze` with a freshly generated sourcemap. I haven't run it in Studio, so it hasn't been tested with real players yet.

**What it does**
- **Startup:** creates the `PlaceBlock` and `RemoveBlock` RemoteEvents in `ReplicatedStorage` and the `PlacedBlocks` folder in Workspace.
- **PlaceBlock `(blockType, position)`:**
  1. Ignores requests from a player who has already left.
  2. Applies the 0.1 s throttle.
  3. Checks the 150-block cap.
  4. Runs `PlacementRules.validate` using the player's character and the `PlacedBlocks` folder.
  5. Builds a 4-stud anchored part at the snapped center, styled from `BlockTypes.STYLES`.

  Rejected placements print a `warn` with the reason from `PlacementRules`.
- **Who owns what:** a server-side table maps each part to its owner. Each part also gets `BlockType` and `OwnerUserId` attributes so the client can read them later. The server only trusts its own table, never the attributes.
- **RemoveBlock `(part)`:** only removes the part if the table says the sender owns it. That also rejects the Baseplate and anything else the script didn't place.
- **PlayerRemoving:** destroys the player's blocks and clears their entries in the owner, cap and throttle tables.

**Decision for you**
- **How the throttle counts time:** the 0.1 s is measured from the last request that got through the throttle, not from every request. A client that spams still gets about 10 attempts per second instead of being locked out. If you want to measure from every request instead, that means one line moves above the check.
- **Cap and throttle rejections are silent:** they don't print a warning, so spam doesn't flood the log. The downside is that a player at the cap gets no message on either side. When you build the UI, you may want a way to tell them.

Running the type check rewrote `sourcemap.json`. Check whether it shows up as changed in git before you commit.