I rewrote loading and unloading in `src/ServerScriptService/Builds.server.luau`, so a big build no longer goes in or out in one frame. I also wrote up the changes in `docs/perf/build-loading.md`. The project's checks pass (selene, stylua, luau-lsp), but I haven't run it in Studio or taken a new MicroProfiler capture. The real frame times still need checking on a live 8-player server.

**Why it froze:** each block was three instances (the Part plus `Owner` and `PlacedAt` value objects), and its properties were set after it was already in the world. A 20,000-block build meant 60,000 instances created in one frame, then sent to every client at once, which is the client hitch you saw. Leaving destroyed all 60,000 in one frame too.

**What changed:**
- **One instance per block.** Owner, placed time and grid cell now live in a table on the server instead of in value objects on the Part. Every block still keeps its placed time.
- **Faster part creation.** Each block is copied from a ready-made part for its block type, and is only added to the world after its properties are set.
- **Loading is spread over frames.** Each frame the server spends at most 3 ms on build work and creates at most 200 parts, and that limit is shared by all players. First it claims all of the save's cells (about 4 frames for a full save), then it creates the parts. Eight players joining at once cost no more per frame than one; their builds just queue.
- **Unloading is spread over frames too.** Up to 1,000 blocks are removed per frame, and unloads run before loads. A plot slot stays taken until its old build is fully gone, so a new build can't load on top of it. On a full server, someone joining at that moment waits for the slot.
- **Placing and removing work as before.** Removal still only works on your own blocks; it now checks the owner in the server table, which also rejects anything that isn't a plot block. Placing is unchanged apart from how the part is created.

**What players will notice:**
- A full build appears over about 1.7 seconds, bottom layer first, instead of freezing everyone for 2 seconds. If several players join together, their builds load one after another, so the last one can take several seconds to appear.
- A leaving player's build disappears over about a third of a second.
- In the first few frames of a load, a block someone places into a cell the save hasn't claimed yet stays, and that saved block is skipped. Overlapping cells already worked this way before.

**For your placed-time feature:** owner and placed time are no longer on the Part, so the client can't see them right now. If the feature needs placed time on the client, add it as an attribute when the part is created, not as a value object again; an attribute adds a few bytes per block, where a value object is a whole extra instance. Turning on `Workspace.StreamingEnabled` would also cut what each client has to receive.

To confirm the fix, take a new server capture with several full-save players joining and leaving. No `Script_Builds` frame should go much past 3 ms, and client `ProcessPackets` should stay smooth while builds load. If clients still hitch, lower `MAX_CREATES_PER_FRAME`; it and the other limits are at the top of the script. Nothing is committed.