I've added `tools/profiling/memory.luau`, but I haven't run it. LibMP.luau isn't in the repo and I don't have a dump, and shell commands needed approval, which isn't available in this session. I wrote the counter calls from LibMP's public API reference, so a mismatch with your copy of LibMP is the most likely thing to break. Please run it once on a real dump.

**What it prints** (`lute memory.luau <dump.gprx> [topN]`):
1. The frame range and the path of the memory counter it found.
2. **Each subsystem** (each direct child of `memory`, such as `memory/Luau`), sorted by how much it grew from first to last. For each one you get first, last and peak values, and the frame where it peaked. Any subsystem with no samples is listed by name at the end.
3. **The topN counters that grew most** (default 10), with full paths like `memory/Luau/...`, plus their first, last and peak values and peak frame.

**Frame names** are `id/abs t=X.XXs`, the same `id/abs` style `overview.luau` uses:
- `id` is the LibMP frame ID, for use in your other scripts.
- `abs` is the absolute frame ID, and `t=` is seconds into the dump, for finding the spot in the MicroProfiler UI.

The docs don't say which number the UI shows, so check that `abs` or `t=` lines up when you open the dump.

**Choices I made:**
- **Finding the memory counter:** it uses the highest-level counter named `memory`. If the dump has none, it prints a note that memory profiling may have been off and exits.
- **Growth:** it is last sample minus first sample, so a counter that spiked and came back down won't rank high, but its peak still shows.
- **What "individual counters" means:** I took it as the lowest-level counters (ones with no children), at any depth under `memory`, so subsystem totals don't crowd out the real culprits.
- **Units:** values are printed exactly as stored. The docs don't say whether memory counters are in bytes or MB, so check the first run and add a conversion if you want one.

Sources:
- [Introducing LibMP: the MicroProfiler API (DevForum)](https://devforum.roblox.com/t/studio-beta-introducing-libmp-the-microprofiler-api/4703136)
- [LibMP API reference](https://raw.githubusercontent.com/Roblox/libmp/main/docs/api-reference.md)