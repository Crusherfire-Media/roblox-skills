I've added `src/ReplicatedStorage/Shared/Dev/SpikeReport.luau`. It passes stylua and selene, but I haven't run it in Studio: LibMP isn't in the repo and there's no snapshot here. Every LibMP call comes from LibMP's own API reference and examples, so the first real `run(2)` is the actual test.

**What `run(slot)` returns:**
- **`medianMs`, `p90Ms`, `slowThresholdMs`:** frame time is each frame's CPU start-to-end time. Paused and incomplete frames are left out, and the count of left-out frames is returned as `skippedFrameCount`. The threshold is twice the median.
- **`slowFrames`:** every frame slower than the threshold, in order. Each entry has `frameMs` and `topScopes`, the five scopes with the most time of their own. Time inside nested scopes is not counted, and each scope's time is added up across all CPU threads. Every scope entry has `selfMs` and `normalAvgMs`, which is the same scope's average per normal frame, so each line of a hitch has its comparison next to it.
- **`normalTopScopes`:** the top five scopes by average time of their own over the frames that weren't slow. You asked for "the same top five" averaged over normal frames, and I read that two ways, so this is the second one: what a normal frame's top five looks like on its own.
- **`frameCount`, `normalFrameCount`, `skippedFrameCount`.**

It also prints a readable summary to the output window.

**Frame names:** each slow frame has `frameId`, `absoluteFrameId` and a `name` like `"frame 812 (absolute 1530)"`. LibMP's guidance is to give both IDs: the regular one to find the frame from LibMP, and the absolute one to find it in the MicroProfiler UI. Its docs don't spell out exactly what the UI shows, so check the absolute ID against the UI on the first snapshot.

**How time is counted:**
- A scope that runs across a frame boundary is split, and each frame gets the part that falls inside it.
- GPU threads are left out because they keep time differently from the CPU threads.
- Scopes cut off by a full profiler stack are dropped.
- If a scope started before the first frame in the snapshot, it's counted from that frame's start.

**What was blocked:** two shell commands needed approval and were denied, a git file listing and a stylua run that would rewrite the file. I applied stylua's formatting by hand and the check now passes.

Sources:
- [LibMP repository](https://github.com/Roblox/libmp)
- [LibMP API reference](https://github.com/Roblox/libmp/blob/main/docs/api-reference.md)
- [LibMP SKILL.md](https://raw.githubusercontent.com/Roblox/libmp/main/docs/SKILL.md)
- [LibMP advanced iteration example](https://raw.githubusercontent.com/Roblox/libmp/main/examples/luau/05-advanced-iteration.luau)
- [Introducing LibMP (DevForum)](https://devforum.roblox.com/t/studio-beta-introducing-libmp-the-microprofiler-api/4703136)