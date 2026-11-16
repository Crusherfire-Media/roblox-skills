I rewrote the placed blocks panel so its cost no longer grows with the number of blocks. I haven't run it in Studio, so the gains below are worked out from the code, not measured.

**What changed** (only `src/StarterPlayer/StarterPlayerScripts/PlacedList.luau`; `Main.client.luau` and the panel's inputs are the same):
1. **A fixed set of 10 rows instead of one row per block.** That is enough to fill the 362 px scroll area plus a spare. As you scroll, each row is moved to its place and shows the block at that position. Scrolling by one row only refills one row. At 2,000 blocks the panel goes from about 14,000 GUI objects to 75.
2. **The scroll height is calculated from the block count.** I removed the `UIListLayout` and automatic canvas sizing and set `CanvasSize` to `count * 48 - 4`. That is the height the old layout produced, so the scroll range is the same.
3. **One clock instead of 2,000.** A single `PreRender` connection updates the time, and only while the panel is open. With the panel closed there are now no per-frame connections, where before there were 2,000 taking about 10 ms a frame. Each row's "s ago" label is only rewritten when its text changes, about once a second.

The panel should look and behave the same: newest first, same text and colors, ages counting up. A new block still pushes the list down one row if you're scrolled. Row frames are still named `Row<Id>` after the block they're currently showing.

**Checks:**
- StyLua and selene: both pass on the new file.
- Type check: not done. `luau-lsp` has no Roblox type definitions on this machine.
- Story: none written. The project has no UI Labs setup.

**The note** is in `docs/perf/placed-list.md`. It explains what was slow and what changed, and gives the Studio steps to measure before and after on the same workload:
- A Command Bar snippet that adds 2,000 entries to the panel without placing any parts.
- The GUI object count: about 14,000 before, 75 after.
- Script Profiler and FPS readings with the panel closed and open.
- MicroProfiler checks for scrolling and for the hitch on each new block.
- A final pass to check the panel still looks right.

To get the "before" numbers, run the same steps on the previous commit. Nothing is committed yet.