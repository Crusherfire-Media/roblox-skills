I wrote the server script at `src/ServerScriptService/Placement.server.luau`. I haven't run, built or type-checked it: my one shell command was blocked, because this session can't approve commands and so they're denied automatically. Please run `rojo build` and play-test it in Studio.

**What it does:**
- **Setup:** it creates the `PlaceBlock` and `RemoveBlock` RemoteEvents in ReplicatedStorage and a `PlacedBlocks` folder in Workspace.
- **Placing:** each request goes through the 0.1 s throttle, then the 150-block cap, then `PlacementRules.validate`. The part is built at the snapped centre using the colour, material and transparency from `BlockTypes.STYLES`. Rejected requests are logged with `warn`, using the reason `validate` returns.
- **Throttle:** only requests that get past it reset the 0.1 s timer. If ignored requests also reset it, a client firing every 0.05 s would be blocked forever. Requests turned away by the cap or by validation still count toward the timer.
- **Ownership:** the server keeps its own record of who owns each block. `RemoveBlock` checks that the argument really is a part and that the record lists the requesting player as its owner before destroying it.
- **Attributes for the client:** each block also gets `OwnerUserId` and `BlockType` attributes for the client to read later, for example to highlight a player's own blocks. The server never uses them to decide anything.
- **Block counts:** a block is taken off its owner's count however it gets destroyed, so the 150 cap stays accurate even if something other than `RemoveBlock` deletes a block.
- **Leaving:** when a player leaves, all their blocks are destroyed and their tracking data is cleared.

I left `Main.server.luau` as it was.