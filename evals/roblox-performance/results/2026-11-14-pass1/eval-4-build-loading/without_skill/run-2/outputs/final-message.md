I've rewritten loading and unloading in `src/ServerScriptService/Builds.server.luau` and written up the changes in `docs/perf/build-loading.md`. None of this has been run in Studio or profiled. StyLua and selene pass, but the type checker had no Roblox definitions file here, so types weren't checked. A new MicroProfiler capture with a 20,000-block build is the real test.

**What was causing the freeze:** a 20,000-block save made 60,000 instances in one frame, because each block was a Part plus an `Owner` StringValue and a `PlacedAt` NumberValue. Each part was also parented before its properties were set. All of it then reached clients in one burst, which is the ProcessPackets hitch. Leaving did the same in reverse: it read 60,000 children and destroyed them in one frame.

**What changed:**
- **Spread over frames:** loading and unloading now go through one shared queue. Each frame it does at most 2 ms of server work or 250 blocks, whichever comes first. The limit is shared, so 8 players joining together cost no more per frame than one. Unloads go first in the queue.
- **One instance per block:** owner and placed time are now kept in server-side tables instead of child instances. Every block still records its placed time: loaded blocks keep the time from the save, and new blocks get `os.time()`.
- **Cheaper block creation:** blocks are copied from one ready-made part per block type, then positioned, then parented. Each one reaches clients once, already finished.
- **Placing and removing:** placing works exactly as before. Removal still checks the owner (now from the server table) and reach, and blocks the script didn't create can't be removed.
- **Plot slots:** a leaving player's slot stays reserved until their blocks are gone, so a new build can't land in cells that are still taken. Someone joining while all 8 slots are busy now waits for one to free up instead of getting "no free plot". If a player leaves mid-load, the rest of their load is cancelled.

**What players will notice:**
- No server-wide freeze or rubber-banding when a big build loads or unloads.
- A 20,000-block build takes about 1.5 s to appear and fills in from the ground up. When several players join at once, builds load one after another, so the last one can take several seconds.
- A build takes about a second to disappear after its owner leaves.
- Client hitches should be much smaller.

**Decisions for you:**
- **Owner and placed time can't be read by clients any more.** Nothing on the client read them, but if the placed-time feature needs them there, you'd add a remote that returns the time on request, or put it back as a part attribute. The attribute is simpler, but it adds data that has to reach every client for every block.
- **Players can place blocks while their build is still loading.** If they fill a cell their save hasn't reached yet, the saved block is skipped. Loading already skipped taken cells before; it's just more likely now that loading takes longer.
- **Joining a full server is unchanged.** A new player still downloads every existing plot during join, up to 7 × 20,000 parts. Turning on `StreamingEnabled` would send clients only nearby plots and help with that. I didn't change it because it affects the whole game and should be tested separately.

Nothing is committed.