I rewrote `BlockInfo.client.luau` so its per-frame cost no longer grows with the size of the build, and wrote the report in `docs/perf/block-info.md`. The type check, selene and StyLua all pass. I couldn't open Studio from here, so the speed-up is an estimate until you take a new capture.

**What was costing time:** every frame, the script copied the list of everything in the Blocks folder three times. At 6,000 blocks that's about 150 KB of throwaway data per frame, which is the GC label you see right after it. It also checked the distance to every block to find the one under the mouse, and rebuilt the panel text even when nothing had changed. All of that grows with the block count.

**What I changed:**
- **Counts:** the counts and total update only when a block is added or removed. The folder is read once, at startup.
- **Hover:** blocks are kept in a 4-stud grid. Finding the hovered block now checks the 27 cells around the point under the mouse instead of every block, and it finds the same block as before.
- **Panel:** the text and the highlight are only changed when a count or the hovered block changes.
- **Raycast settings:** created once and reused, instead of new ones every frame.

What remains each frame is one raycast and up to 27 table lookups, and that doesn't depend on how big the build is. I expect `Script_BlockInfo` to drop from about 2.5 ms to well under 0.1 ms, and the GC after it to go away while nothing changes.

**What players see** is the same panel and the same highlight, with three edge cases:
- If two blocks are exactly the same distance from the mouse point, which one gets highlighted may differ from before. Neither order was predictable to players.
- A newly placed block can show up in the counts up to one frame later.
- The script assumes a block keeps its name and position once placed. That's true today, since nothing renames or moves blocks. If you later add moving or retyping a block in place, remove it and place a new one instead, or the script will need updating.

**What to check in Studio** (the full list is in the report):
1. With the same 6,000-block build, camera and mouse position, take a new MicroProfiler capture. `Script_BlockInfo` should be tiny and the GC label after it gone from most frames.
2. Repeat at 12,000 or more blocks. The cost should stay about the same.
3. Run the hand checks in the report: counts, the highlight following the mouse, pointing at the sky, resetting your character, and joining a server that already has blocks.
4. Publish and check frame rate on the phone that ran at about 35 FPS. Studio can't show phone performance.

Nothing is committed yet.