I've rewritten loading and unloading in `src/ServerScriptService/Builds.server.luau` and written up the changes in `docs/perf/build-loading.md`. Nothing has been measured yet: there's no Studio connection here, so I couldn't playtest or take captures. The type checker, selene and stylua all pass. The "after" figures in the doc are estimates until someone takes a server capture.

**Cause:** each saved block was three instances (the `Part`, an `Owner` StringValue and a `PlacedAt` NumberValue). A 20,000-block build therefore created 60,000 instances in one frame, and each part was parented before its properties were set, which makes every property write more expensive. All 60,000 then reached every client at once, which is the `ProcessPackets` hitch. Leaving destroyed the whole build in one frame, which is the smaller freeze.

**What I changed:**
1. **One instance per block.** The owner and placed time are now attributes on the part: `OwnerId` (a number) and `PlacedAt`. Every block keeps its placed time, so the upcoming feature can read it with `GetAttribute("PlacedAt")`. This alone removes about two thirds of the instances and replicated data.
2. **Loading is spread across frames.** When a player joins, every cell of their saved build is reserved at once. The parts are then built in batches: at most 400 blocks per frame, shared by every plot that's loading, and fewer if the step has used 4 ms that frame.
3. **Each frame's batch is built unparented and added to the world in one go**, inside a `SavedBlocks` folder under the plot.
4. **Unloading is spread the same way.** Unloads run before loads each frame, so a departed player's plot is cleared before a new build starts in that slot.
5. **Placing and removing work as before.** Removal still checks the owner, now against the `OwnerId` attribute. Saved cells still can't be taken by someone else's placement while the build is loading.

**What players will notice:**
- A 20,000-block build appears from the bottom up over about a second (50 frames). On a busy server it can take 2 to 3 seconds.
- When several players join together, their builds load one after another. With 8 full builds, the last starts after about 7 seconds.
- A departed player's build disappears over about a second. During that second their cells are already free, so a new block can briefly overlap an old one.
- The server-wide freeze and rubber-banding on join and leave should be gone.

**Changes for other code:**
- Loaded blocks now sit one level down, in `SavedBlocks` folders, so code that reads a plot's blocks should use `GetDescendants()`.
- The `Owner` and `PlacedAt` child values are gone. Nothing in the repo read them.
- A player can now only remove blocks in their current plot. Otherwise, someone who rejoins while their old plot is still being cleared could free cells that already belong to another plot.

Spreading the load over time does change what players see. You asked me to fix the freeze and write down what players notice, so I made that change without checking with you first. The alternative that keeps builds appearing all at once (just cutting to one instance per block) would still freeze for hundreds of milliseconds.

**To check in Studio** (also listed in the doc):
- Take server captures on a 20,000-block join and on that player leaving. No frame should be over about 20 ms, and the build work should show under `Builds:Step`.
- Take a client capture during a join on a low-end phone. If `ProcessPackets` still spikes, lower `BLOCKS_PER_FRAME`.
- Have 8 players join at once, and check the server stays smooth and every build finishes.
- By hand: place and remove blocks while a build loads, and leave and rejoin mid-load.

Nothing is committed.