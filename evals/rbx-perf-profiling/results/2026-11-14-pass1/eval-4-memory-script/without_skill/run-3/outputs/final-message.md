I added `tools/profiling/memory.luau`, but I haven't run it. LibMP.luau isn't in the repo and I don't have a `.gprx` dump. I also couldn't check whether `lute` is installed, because this session can't approve commands. Because LibMP.luau wasn't here to read, I wrote it against LibMP's published API reference and examples on GitHub. Running `lute memory.luau <dump.gprx>` once on a real dump will tell you whether the counter calls behave the way the docs say.

**What it prints**

1. **Memory subsystems** (each child of the `memory` counter, such as `memory/Luau`): growth from first to last, first value, last value, peak value and the frame where it peaked. Sorted by growth, biggest first.
2. **Top N counters** (default 10): the lowest-level counters under `memory` that grew the most, each with its full path (for example `memory/Luau/heap`), in the same columns.

**Frame naming:** frames print as `id/abs`, the same format `overview.luau` uses. `id` is the frame number LibMP scripts use, and `abs` is the real rendered frame number. The LibMP docs say to give both so a frame can be found in scripts and in the UI, though they don't say which one the MicroProfiler UI displays.

**Assumptions worth knowing:**
- **Units:** values print in MB, assuming the counters are in bytes. That's what LibMP's own heap example assumes; the docs don't state a unit.
- **Subsystems with no value of their own:** the docs say a parent counter may be an empty container instead of a total. For those, the script adds up its child counters frame by frame and labels the row `(sum of leaves)`.
- **Top N list:** it only includes counters with no children. Including parents would list the same growth twice, once as the parent and again as the child.
- **Finding `memory`:** it looks for a counter named `memory` at the top level first, then anywhere in the tree. If none exists, it prints a message and exits.

Sources:
- [LibMP repository](https://github.com/Roblox/libmp), including [api-reference.md](https://github.com/Roblox/libmp/blob/main/docs/api-reference.md), [SKILL.md](https://github.com/Roblox/libmp/blob/main/docs/SKILL.md) and examples 03 and 07
- [DevForum: Introducing LibMP](https://devforum.roblox.com/t/studio-beta-introducing-libmp-the-microprofiler-api/4703136)