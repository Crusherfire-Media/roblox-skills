I rewrote `BlockInfo.client.luau` so its per-frame cost no longer grows with the number of blocks, and wrote the report at `docs/perf/block-info.md`. StyLua, selene and luau-lsp all pass, but I couldn't run anything in Studio, so the speed-up still needs measuring there.

**What was costing time:** every frame, the script called `blocksFolder:GetChildren()` three times. Each call builds a new table with one entry per block, so at 6,000 blocks that's about 18,000 table slots created and thrown away each frame. That's almost certainly the GC label you see right after the script. On top of that it recounted every block by type, and it looped over every block again to find the one under the mouse. All of this happened every frame, so it got slower as builds grew.

**What I changed:**
- **Counts:** they're now kept up to date when blocks are added or removed, and counted once at startup. Nothing loops over the blocks each frame any more.
- **Hover:** after the raycast, a small search around the hit point (`GetPartBoundsInRadius`) returns just the few nearby blocks. The same rule as before then picks the one whose center is nearest the hit point and within 4 studs.
- **Smaller fixes:** the raycast settings are created once instead of every frame. The label text is only rebuilt when the counts or the hovered block change, and it's only written when it's actually different.

Each frame is now one raycast, one small search, and a few comparisons, with almost no garbage, so the cost should be about the same at 60,000 blocks as at 6,000.

**What players see** stays the same. There are three edge cases where it could differ, none of which comes up with how blocks are placed today:
- A block's type is read when it's placed, so a block renamed afterwards wouldn't move to its new count. The server never renames blocks.
- The nearby-block search skips blocks with `CanQuery` off or in a non-default collision group. Placed blocks use the defaults.
- If two blocks are exactly the same distance from the hit point, the highlight could pick the other one.

**To check in Studio** (the report has the full list):
1. **Same build in the MicroProfiler:** `Script_BlockInfo` should drop well below its current 2.5 ms, and the GC label after it should mostly disappear.
2. **A much bigger build** (30,000+ blocks): the script's time should stay about flat.
3. **Phone:** compare FPS against the 35 you had before.
4. **Behaviour:**
   - Counts update when you place and remove blocks.
   - Counts are right when you join a server that already has a build.
   - The highlight still works on faces, on edges, and on the baseplate right next to a block.
   - Hovering still works after you respawn.

Nothing is committed yet.