I've rewritten `BlockInfo.client.luau` so its cost per frame stays the same however big a build gets, and the report is in `docs/perf/block-info.md`. I couldn't reach Studio from here, so I have no "after" timing yet. Your capture on the same 6,000-block build will give the real number.

**What was costing time:** every frame, the script called `Blocks:GetChildren()` three times. Each call builds a new 6,000-entry list, so that's about 18,000 entries of garbage per frame, which explains the GC label right after the script. It also checked the type and position of every block to find the one under the mouse. So the work grew with every block placed.

**What I changed:**
- **Block counts** are now kept as running totals, updated only when a block is added or removed.
- **Hover highlight:** blocks are now sorted into grid cells, so finding the block under the mouse only checks the 27 cells around the point the mouse hits. That's usually under 10 blocks instead of all 6,000. It picks the same block as before, including which one wins when two are exactly the same distance away.
- **The panel text** is rebuilt only when a count or the hovered block changes, and the raycast settings are reused instead of recreated every frame.

**What players see** should not change. Two things the new version relies on, both true in the current code:
- Blocks are never renamed or moved after they're placed. If you add either later, this script will need to track that too.
- A newly placed or removed block may show in the panel up to one frame later. That's because your place delivers these events slightly delayed (deferred mode).

**Checks:** the type check, linter and formatter all pass. I couldn't run the commands that check them all in one go because they needed an approval this session can't give, so I ran each one separately.

**What to check in Studio** (full steps are in the report):
1. With the same build, stand in the same spot, take a client MicroProfiler capture and look at `Script_BlockInfo`. It should be close to zero, and the GC label after it should be gone or much rarer.
2. Double the build and capture again. `Script_BlockInfo` should stay about the same.
3. By hand, check that the counts and total stay right after placing and removing blocks and after rejoining. Also check that the highlight still follows block faces, edges and corners.
4. Retest the build on the phone. If it's still below your target, the next bottleneck at large builds is probably rendering (lots of blocks, plus the see-through Window blocks), which this script doesn't control.

I haven't committed anything.