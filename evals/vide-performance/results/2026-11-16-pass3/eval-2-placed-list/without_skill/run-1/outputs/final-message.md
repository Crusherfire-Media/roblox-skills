I rewrote the placed blocks panel so its cost no longer grows with the number of blocks, and wrote the note in `docs/perf/placed-list.md`. I haven't run it in Studio, so the frame rate gain still needs checking there. selene, stylua and luau-lsp all pass with no problems; my first run of all the checks together was blocked by a permission prompt, so I ran them one at a time. Nothing is committed.

The only code change is in `PlacedList.luau`:

- **Only on-screen rows exist.** The panel used to build 7 GUI objects for every block. Now it keeps about 10 rows, enough to fill the visible area plus one. Scrolling or placing a block just changes which block each row shows and where it sits. That takes the panel from about 14,000 GUI objects to about 80, however many blocks there are, and there's no re-layout of every row when a block is placed.
- **The scroll area is sized directly.** I removed the automatic list layout and set the scrollable height from the block count. It's the same height the layout produced, so the scroll bar and scroll range behave as before.
- **One timer, only while the panel is open.** The ~2,000 per-row Heartbeat connections are replaced by a single one that exists only while the panel is open, so the panel costs nothing per frame when closed. When you open it, the "x s ago" times refresh immediately.
- **Fewer label updates.** Each "x s ago" label is now only rewritten when its text actually changes, instead of every frame.

The panel shows exactly what it did before: the same header count, newest-first order, row content and styling. `Main.client.luau` didn't need any changes.

The note has the full Studio steps. In short:
1. Start a Play session and paste a one-line loop into the command bar to add 3,000 test entries to the list.
2. Count the panel's GUI objects; you should see about 80.
3. In the Script Profiler, PlacedList should use no Heartbeat time while the panel is closed and one connection while it's open.
4. Watch the frame rate in the MicroProfiler or render stats with the panel open and closed.
5. Scroll from top to bottom and place blocks by hand. Scrolling should be smooth and new blocks shouldn't cause a hitch.