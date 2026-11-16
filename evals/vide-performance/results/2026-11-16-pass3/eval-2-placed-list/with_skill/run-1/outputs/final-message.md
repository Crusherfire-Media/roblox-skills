I've rewritten the placed blocks panel so its cost no longer grows with the number of blocks. I haven't run or measured it in Studio, though: I can't reach Studio from here. The StyLua, selene and luau-lsp checks all pass.

**What changed** (all in `PlacedList.luau`; `Main.client.luau` and the panel's props are untouched):
- **11 rows instead of one per block.** The panel now keeps just enough rows to fill its scroll window, plus one spare above and below, and refills them from the scroll position. The panel goes from about 14,000 GUI objects at 2,000 blocks to about 82, and that number stays the same as blocks are added. Scrolling down one row refills one row, and placing a block refills all 11. Before, every placement moved all 2,000 rows.
- **Scroll height comes from the block count.** There's no list layout to measure anymore, so the canvas height is now worked out from the number of blocks. It's the same height the old layout produced, so the scroll bar and scroll range look the same.
- **One clock that only runs while the panel is open.** This replaces the 2,000 Heartbeat connections. Each "N s ago" label is now only rewritten when its text changes, about once a second.

What the panel shows is meant to be the same: newest block on top, the header count, colors, positions, the ticking ages, and the scroll position staying put when a block is added.

**One limit:** the row count is worked out from the panel's fixed 360 × 420 size. If you make the panel taller or put a `UIScale` above it, the row count needs updating. The note says how.

**Also added:** a UI Labs story at `src/ServerScriptService/Stories/PlacedList.story.luau`, with a block count slider (0 to 5,000) and an open/closed toggle, plus a storybook file next to it. It lets you look at the panel with thousands of rows without placing any blocks. I couldn't open it here, so it's untested.

**Checking it in Studio:** `docs/perf/placed-list.md` covers what changed and the steps:
1. Fill the list with 2,000 blocks from a short command-bar loop.
2. Count the panel's GUI objects (about 14,000 before, under 100 after).
3. Run the Script Profiler with the panel closed: nothing should come from PlacedList.
4. Compare FPS and the MicroProfiler's UI layout time while scrolling and placing blocks.
5. Check by eye that the panel looks the same, including that no rows go blank at the top or bottom edge when you drag the scroll bar fast.

Two things to check yourself in Studio: whether the frame rate is back to 60 at 2,000 or more blocks, and whether fast scrolling ever shows a blank row at the edges. The spare rows are there to cover the one-frame delay before rows refill, but I couldn't test it.

Nothing is committed.