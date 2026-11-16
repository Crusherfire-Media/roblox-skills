The panel is rewritten, but I haven't run it in Studio, so the frame-rate gain hasn't been measured yet. StyLua and selene pass. A full type check wasn't useful here because the Roblox type definitions aren't available locally. All the changes are in `PlacedList.luau`; `Main.client.luau` is unchanged.

**What was wrong:** every placed block had its own row of 7 GUI objects and its own Heartbeat connection, and each row rewrote its age label every frame, even with the panel closed. That's where your ~2,000 connections and ~14,000 objects came from. Each new block also made the list compare every entry and re-lay out every row, which caused the hitch.

**What I changed:**
1. **One clock, only while open.** The panel has a single shared clock with one Heartbeat connection. It connects when you open the panel and disconnects when you close it, so a closed panel does no per-frame work.
2. **Age labels only update when the text changes.** That's about once a second instead of every frame. The text and timing look the same as before.
3. **Only visible rows exist.** The list keeps about 9 reusable rows, enough to fill the visible area plus one. When you scroll or a block is added, those rows switch to different blocks and move into place, so no GUI objects are created while scrolling. The scrollable area is still sized for the full list (same total height as before), so the scrollbar looks and behaves the same.
4. **No rows while closed.** Opening the panel builds the ~9 rows once.

The panel shows the same thing as before: the header with the total count, newest first, and the same row look, position text and "N s ago" / "N min ago" ages. However many blocks there are, it should now use about 70 GUI objects and 1 connection when open, and about 15 objects and no connections when closed.

`docs/perf/placed-list.md` covers the changes and how to check them in Studio:
- A server command-bar snippet that adds 3,000 entries to the panel through the `BlockPlaced` remote. I checked it against `BlockPlacement.server.luau`. It only fills the panel; no parts get built.
- What to compare against the old version: FPS with the panel closed, the Script Profiler, how many rows are under `PlacedListGui.PlacedList.Rows`, and smoothness when scrolling and placing.

`Main.client.luau` still copies the whole list each time a block is placed. That's microseconds at a few thousand blocks, so I left it alone.

I couldn't run the git commands to check the repo state because they needed approval that this session can't grant. That didn't affect the edits, and I haven't committed anything.