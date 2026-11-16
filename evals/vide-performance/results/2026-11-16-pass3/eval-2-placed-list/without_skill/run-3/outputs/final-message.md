I rewrote the placed blocks panel so its cost stays about the same at any number of blocks, and wrote the note at `docs/perf/placed-list.md`. I haven't run it in Studio, so the FPS gain isn't measured yet. The note gives the steps to check it.

**What changed**

- **One clock instead of 2,000.** Every row used to run its own Heartbeat connection, even with the panel closed. Now one shared clock runs, and only while the panel is open. Each "x s ago" label is only rewritten when its text actually changes, about once a second.
- **Only on-screen rows exist.** The panel now builds just the rows you can see, plus 2 extra above and below, placed on a scroll area sized for the full list. That's about 13 rows (~90 GUI objects) instead of ~14,000, whether there are 200 blocks or 5,000. When you scroll, rows that leave the view are reused for the ones coming in. While the panel is closed, no rows exist at all.
- **No full-list copy per block.** `Main.client.luau` used to copy the entire list every time a block was placed. It now adds the new block to the existing list. The panel still updates, because Vide (the UI library) refreshes when a list is set again even if it's the same list. This, plus the panel only building visible rows, is what should remove the hitch on each new block.

The panel shows the same thing as before: newest first, same layout, text and colors, same header count, and the same scroll length. One thing that differs if you look in the Explorer: only the visible rows are there as `Row<Id>` frames.

**Checks:** selene reports no issues, and the stylua format check passes after I applied its one line-wrap fix by hand. This session couldn't run the formatter itself or a type checker because commands needing approval were blocked. The code follows the Vide 0.4.1 source in `roblox_packages` (checked by reading it), but nothing has run in a live game yet.

**To check in Studio:** the note includes a command-bar snippet that adds 3,000 entries to the panel. Then:
- With the panel closed, the Script Profiler should show nothing per frame from PlacedList, and FPS should stay near 60.
- With it open (L), there should be one Heartbeat connection and about 13 `Row…` frames under `PlacedListGui > PlacedList > Rows`.
- Scrolling from top to bottom should be smooth with no blank rows.
- In the MicroProfiler, placing a block shouldn't cause a spike.

Nothing is committed.