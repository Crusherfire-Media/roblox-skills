I rewrote `BlockInfo.client.luau` so its per-frame work no longer grows with the size of the build. The report is in `docs/perf/block-info.md`. I couldn't reach Studio, so there's no "after" number yet. The before/after capture is the first thing for you to check.

**What was costing time.** On every frame, the script:
- called `Blocks:GetChildren()` three times. At 6,000 blocks that makes about 150 KB of throwaway arrays per frame, which is the GC label you see right after the script.
- read `.Name` on every block to count the types.
- checked the distance to every block to find the one under the mouse.
- rebuilt the panel text and set it again, even when nothing had changed.

The first three grow with block count. By straight-line estimate, 50,000 blocks would cost about 20 ms per frame on your PC.

**What I changed:**
- **Counts and the total** are counted once at startup. After that they update when a block is added or removed, instead of being recounted every frame.
- **Hover** now uses a lookup table of blocks by grid cell. After the raycast, it checks at most 27 nearby cells, however big the build is. The rule is the same as before (nearest block center within 4 studs of the hit point), so hovering the ground right next to a block still highlights it.
- **The panel text and the highlight** are only updated when a count or the hovered block changes. The raycast settings are now created once.
- **Profiler label:** the per-frame work now shows as `BlockInfo:Step` in the MicroProfiler.

Players should see exactly what they saw before. There are two edge cases that the current server code never triggers: renaming a placed block, or moving one. Any future feature that does either needs to update the new lookup tables too. The report explains this.

The project checks pass: StyLua, Selene and luau-lsp. luau-lsp caught one type error on the first run, which I fixed.

**What to check in Studio (details in the report):**
1. Take a client MicroProfiler capture on the same build of about 6,000 blocks. `BlockInfo:Step` should be far below your 2.5 ms baseline, and the GC label should mostly be gone.
2. Repeat at about 12,000 and 30,000 blocks. `BlockInfo:Step` should stay about the same.
3. Test by hand, since no spec covers this script:
   - The counts are correct when you join a server that already has a build.
   - The ground next to a block still highlights that block.
   - Hovering still ignores your character after you respawn.
   - Window blocks highlight like the others.
4. Check FPS on your phone with a published build. That's the result that confirms the fix. If the phone is still slow, the next likely cost is rendering thousands of parts, which this script doesn't control.

I haven't committed anything.