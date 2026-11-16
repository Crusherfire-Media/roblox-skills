Loading and unloading in `src/ServerScriptService/Builds.server.luau` no longer happen in a single frame. I haven't profiled this in a live server yet; formatting (`stylua`), lint (`selene`) and type checks (`luau-lsp analyze`) all pass.

**What was causing the freeze**
- **All in one frame:** the whole saved build (up to 20,000 blocks) was created in one loop, and the whole plot was destroyed in one go when its owner left.
- **Three instances per block:** each block was a Part plus an `Owner` StringValue and a `PlacedAt` NumberValue. That's 60,000 instances for a big build.
- **Parts parented before setup:** parts were put in the world first and had their properties set afterwards.
- **Clients got everything at once:** the client `ProcessPackets` hitch came from all 60,000 instances arriving in one burst.

**What I changed**
- **Spread over frames:** joining and leaving now queue a job. A `Heartbeat` worker advances these jobs with a shared limit of 4 ms and 500 blocks per frame (`FRAME_BUDGET`, `MAX_BLOCKS_PER_FRAME`). The limit is shared, so 8 players joining at once costs no more per frame than one. Clients get builds as a steady stream.
- **One instance per block:** each part's placed time is now a `PlacedAt` attribute with the same Unix-seconds value. The `Owner` value is gone; the server tracks which blocks are in each plot.
- **Faster part creation:** each block is cloned from a template for its type, with its position and attribute set before it's parented.
- **Placing** has the same checks and behaviour as before.
- **Removing** still only works on your own blocks. The check is now "this part is in your plot". Blocks only ever go into their owner's plot, so it allows and rejects the same blocks as before.
- **Edge cases:** if someone leaves mid-load, the load stops and what was already built is cleared. A plot slot stays taken until its old blocks are fully gone. If all 8 slots are taken because someone's plot is still clearing, a joining player now waits for a slot. Before, they got no plot at all.

**What players will notice**
- No more server-wide freeze or rubber-banding when big builds load or unload.
- Builds appear from the ground up. A 20,000-block build should take roughly 0.7 to 3 seconds; that's my estimate, not a measurement. Several big builds joining together load one after another, so the last one can take several seconds.
- A leaving player's build disappears over a similar short time instead of vanishing at once.
- While their build is loading, the owner can already place blocks. If they place one in a cell the saved build hasn't reached yet, that saved block is skipped. This follows the existing rule that a saved block never overwrites an occupied cell.

**Before the placed-time feature:** read `block:GetAttribute("PlacedAt")`. It works on both server and client, but the old NumberValue children no longer exist.

Turning on `StreamingEnabled` would cut client load further, since clients would only receive plots near them. It also changes what players see, so I've only suggested it. To confirm the fix, take a MicroProfiler capture while a 20,000-block player joins and leaves: `Script_Builds` should stay around 4 ms per frame with no long frame. All of this is written up in `docs/perf/build-loading.md`.

Nothing is committed.