I rewrote `BlockInfo.client.luau` so its per-frame cost no longer grows with the number of blocks, and wrote the report at `docs/perf/block-info.md`. I couldn't reach Studio from here, so the "after" numbers haven't been measured yet. StyLua, selene and luau-lsp all pass.

**What was costing time:** every frame, the script went through every block three times. It called `GetChildren()` twice to count blocks and once more to find the hovered block, checking each block's distance to the mouse. Each `GetChildren()` call builds a new table holding all 6,000 blocks. That garbage is what triggers the GC label right after `Script_BlockInfo`. On top of that, it rebuilt the panel text and created new raycast settings every frame. The cost grew in step with build size, so a 20,000-block build would have cost about 8 ms a frame.

**What I changed:**
- **Counts:** they now update when a block is added to or removed from the folder, instead of being recounted every frame. The full list of blocks is read once, at startup.
- **Hover:** the raycast is unchanged, then `GetPartBoundsInRadius` around the hit point finds only the few blocks nearby. The same "nearest center within `HOVER_RADIUS`" rule picks between them, so the block that gets highlighted is the same as before.
- **Panel:** the text is only rebuilt when a count or the hovered block changes. The raycast and spatial-query settings are created once and reused.
- **Profiler label:** the per-frame handler now shows up as `BlockInfo:Step` in the MicroProfiler.

**What players see:** nothing changes: same text, same format, same highlight rules. Two edge cases can't happen with the current code:
- If two blocks are exactly the same distance from the mouse, either one may be picked.
- A block renamed after it was placed would stay counted under its old name. Nothing renames blocks today.

**What to check in Studio** (also in the report):
1. **Same build:** with the same ~6,000-block build and camera position, take a client MicroProfiler capture. `BlockInfo:Step` should take a small fraction of a millisecond, and the GC label after it should be gone or much rarer.
2. **Bigger build:** double the build to about 12,000 blocks. `BlockInfo:Step` should stay about the same.
3. **Behavior:**
   - The counts and `Total` go up correctly as you place blocks.
   - The highlight follows the mouse and clears when you point at the baseplate or the sky.
   - It still highlights a block when you point at the ground right next to it.
4. **Phone:** compare FPS on a published build against the 35 you saw before, since Studio can't show phone frame rate. If the phone is still slow, take a capture on the phone itself. With builds this large, the next cost is more likely rendering, especially the transparent Glass windows, than this script.

Nothing is committed.