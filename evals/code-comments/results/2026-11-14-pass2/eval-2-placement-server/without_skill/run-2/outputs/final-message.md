I wrote the server script at `src/ServerScriptService/Placement.server.luau`. I haven't run it or type-checked it: shell commands need approval and this session can't grant any, so it hasn't been tested in Studio.

**How it works**
- **Remotes and folder:** at startup it creates the `PlaceBlock` and `RemoveBlock` RemoteEvents in ReplicatedStorage and a `PlacedBlocks` folder in Workspace.
- **Placing:** each request goes through three checks in order:
  1. Requests less than 0.1 s after that player's last request are ignored.
  2. A player who already has 150 blocks is refused.
  3. `PlacementRules.validate` checks the block type, the position, reach and whether the cell is free. Rejected requests write a `warn` to the server log with the reason.

  If all three pass, the script builds an anchored part at the snapped grid position, using the color, material and transparency from `BlockTypes.STYLES`.
- **Removing:** the server keeps its own record of who owns each block, so a client can't fake ownership. `RemoveBlock` checks that the argument really is a part and that the player who sent it owns it.
- **Player leaves:** all of that player's blocks are destroyed and their count and cooldown entries are cleared.

**Decisions you may want to change**
- **How the cooldown counts:** the 0.1 s is measured from the last request that got past the cooldown, even if that request then failed validation. A client spamming faster than 0.1 s still gets about one attempt through every 0.1 s.
- **Count stays accurate:** a player's block count goes down whenever one of their blocks is destroyed for any reason, including by other scripts, so the 150 cap stays correct.
- **`OwnerUserId` attribute:** each block also gets this attribute so the client UI can show which blocks the player can remove. The server never uses it for permission checks.