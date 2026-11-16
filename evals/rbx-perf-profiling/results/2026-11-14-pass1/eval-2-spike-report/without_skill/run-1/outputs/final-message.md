I've added `src/ReplicatedStorage/Shared/Dev/SpikeReport.luau`, but it hasn't been run or type-checked. This session couldn't approve shell commands, so a request to look for a Luau analyzer or linter was blocked. LibMP isn't in the repo either, so I wrote the module against LibMP's published API reference and examples. Calling `run(2)` once in Studio is the real test.

**What `run(slot)` returns:**
```lua
{
  slot, frameCount, normalFrameCount,
  medianMs, p90Ms, slowThresholdMs,   -- threshold = 2 × median
  slowFrames = {
    { name = "frameId 143 / MicroProfiler frame 58217 (71.40 ms)",
      frameId, absoluteFrameId, frameMs,
      topScopes = {  -- 5 entries
        { name, timerId, selfMs, normalAvgMs, threads = {"Main", ...} }, ...
      } }
  }
}
```

**Naming each slow frame:** each one has two IDs. `frameId` is LibMP's ID inside the snapshot, for `FetchFrameDesc` and iterator ranges. `absoluteFrameId` is the frame number the MicroProfiler UI shows. The `name` string includes both.

**How it works:**
- **Frame time:** the CPU frame time of each frame (end tick minus start tick, converted to ms). Median and 90th percentile interpolate between neighbouring values.
- **Own time:** scopes come out of LibMP's log iterator innermost first, so each scope subtracts the time of the scopes directly inside it. If a scope's start or end is cut off, it doesn't end up counted inside the wrong parent. A scope that crosses a frame boundary only counts its part inside each frame. Totals are summed per scope name across all CPU threads; GPU threads are skipped. `threads` lists the threads the scope ran on in that frame.
- **Comparison with normal frames:** `normalAvgMs` is that scope's own time summed over all frames that weren't slow, divided by how many there were. Frames where it didn't run count as 0.

**Things to know:**
- The snapshot's first frame is left out of everything. LibMP can't rebuild scopes that were already open when the snapshot starts, so that frame is only used to warm up the iterator. Paused or incomplete frames are also skipped. HitchSnapshot saves 10 frames after the hitch, so the hitch shouldn't land on the first frame.
- Because own time is summed across threads, a frame's top five can add up to more than its frame time when worker threads are busy.
- Any scope that only marks a thread waiting will show its idle time as its own time. If one turns up in the top five, it's not real work.
- The Studio command bar caches `require`. After editing the module, re-sync it or restart Studio before running it again.

I based the API on LibMP's [repository and README](https://github.com/Roblox/libmp), its [API reference](https://raw.githubusercontent.com/Roblox/libmp/main/docs/api-reference.md), its [profiling guide](https://raw.githubusercontent.com/Roblox/libmp/main/docs/SKILL.md), and the iteration examples ([05](https://raw.githubusercontent.com/Roblox/libmp/main/examples/luau/05-advanced-iteration.luau), [06](https://raw.githubusercontent.com/Roblox/libmp/main/examples/luau/06-advanced-frame-stats.luau)). The guide is also the source for `FrameAbsoluteId` matching the UI's frame number; check that against the UI the first time you use it. Other background: the [LibMP announcement](https://devforum.roblox.com/t/studio-beta-introducing-libmp-the-microprofiler-api/4703136) and Roblox's [MicroProfiler docs](https://create.roblox.com/docs/studio/microprofiler).