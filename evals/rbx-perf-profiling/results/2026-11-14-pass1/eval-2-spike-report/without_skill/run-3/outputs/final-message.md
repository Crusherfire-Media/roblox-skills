I added `src/ReplicatedStorage/Shared/Dev/SpikeReport.luau`, but I haven't run it or type-checked it. LibMP isn't in the repo and I don't have Studio here, so test it on a real hitch snapshot first.

`run(slot)` opens the snapshot with `LibMP.Session.OpenFromSlot`, returns the report table and prints a short summary. The command bar doesn't show return values, so the printout is what you'll see.

**What's in the table:**
- **Frame times:** `medianMs`, `p90Ms`, and `slowThresholdMs` (twice the median). These leave out paused frames and incomplete ones, like the frame still running when the snapshot was saved.
- **Slow frames:** `slowFrames` lists every frame over the threshold. Each has a `name` like `"Frame 412 (absolute 1057)"`, plus the two numbers on their own:
  - `frameId` is LibMP's ID, for `FetchFrameDesc` or `RewindTo`.
  - `frameAbsoluteId` is the frame number shown in the MicroProfiler UI.

  The LibMP docs recommend giving both, because the absolute ID has gaps after a pause.
- **Top scopes:** each slow frame has `topScopes`, the five scopes with the most self time. Each one sums that scope across all CPU threads in that frame. GPU threads are skipped because their clock runs on a different scale.
- **Normal comparison:** each top scope also has `normalAvgMs`, its average self time over the frames that weren't slow (a frame where it didn't run counts as 0).

**How self time is worked out.** LibMP only reports total times, which include nested scopes. So the module walks the scope enter/exit log and takes each scope's time minus the time of the scopes directly inside it. A scope that crosses a frame boundary is split, so each frame only gets the part that ran inside it. That follows the per-frame pattern in LibMP's docs.

**Limitation:** a scope that started before the oldest frame in the snapshot has no known start or nesting. I count it from the frame start, which overstates its self time. Frames like that get `partialData = true` and are left out of the normal averages. This should only affect the first frame or two of a snapshot, not the hitch.

**Things to check on the first run:**
- I couldn't read LibMP's docs word for word: shell commands and downloads needed approval, which wasn't available in this session. The method names and their behaviour come from summaries of the GitHub docs.
- One detail I inferred rather than read: after a scope exits, the stack depth is taken to be that scope's 0-based level. The docs' example code implies it but doesn't state it.
- An easy sanity check: in a slow frame, the self times should add up to no more than the frame time multiplied by the number of busy CPU threads.

Sources:
- [[Studio Beta] Introducing LibMP: the MicroProfiler API](https://devforum.roblox.com/t/studio-beta-introducing-libmp-the-microprofiler-api/4703136)
- [Roblox/libmp on GitHub](https://github.com/Roblox/libmp)
- [LibMP API reference](https://github.com/Roblox/libmp/blob/main/docs/api-reference.md)
- [LibMP SKILL.md](https://github.com/Roblox/libmp/blob/main/docs/SKILL.md)