I wrote the server side in `src/ServerScriptService/Placement.server.luau`. I haven't run it in Studio or put it through a type checker or linter, because shell commands in this session need approval and nobody could approve them.

**What it does:**
- **Remotes:** it creates `PlaceBlock` and `RemoveBlock` RemoteEvents in ReplicatedStorage, and a `PlacedBlocks` folder in Workspace.
- **Placing:** a request first has to pass three checks: the player is still in the game, the 0.1 s throttle, and the 150-block cap. Then it goes to `PlacementRules.validate` with the player's character and the `PlacedBlocks` folder. If that passes, it builds an anchored 4-stud part at the snapped position using the color, material and transparency from `BlockTypes.STYLES`. Rejected requests are logged with `warn` along with the reason.
- **Throttle:** the 0.1 s gap is measured from the last request that got past the throttle, even if it then failed validation or hit the cap. Requests the throttle drops don't reset the timer, so a client spamming the remote still gets one request through every 0.1 s.
- **Ownership:** the server keeps its own table of which player owns each part. `RemoveBlock` ignores anything that isn't a `BasePart` the sender owns, so a client can't delete the Baseplate or other players' blocks. Each part also gets `BlockType` and `OwnerUserId` attributes for the client UI to read later, but the server never trusts them.
- **Leaving:** `PlayerRemoving` destroys all the player's blocks and clears their entries in every table. It also handles players who joined before the script started.

**Things to know:**
- Blocks are only tracked when they're removed through the script. If something else destroys a placed block (another script, or you in Studio), the owner's count won't go down. That could matter later; a `Destroying` handler would fix it.
- I didn't change the existing `Main.server.luau`.