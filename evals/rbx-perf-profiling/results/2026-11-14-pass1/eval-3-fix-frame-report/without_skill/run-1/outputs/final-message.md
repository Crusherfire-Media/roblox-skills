I rewrote `src/ReplicatedStorage/Shared/Dev/FrameReport.luau` to fix all five problems and several other LibMP mistakes. The report's fields and what they mean are unchanged, and `FpsOverlay.luau` is untouched. **None of this has been run.** I couldn't run a type checker or linter (the permission prompt was denied in this session), and it hasn't been tried in a playtest, so press the button a few times there to confirm.

The main change: the report now takes its own copy of the profiler data (`Control:CaptureToBufferSync()` → `Session.OpenFromBuffer`) and closes only that copy. It no longer pauses capture, changes the frame limit, or uses the overlay's session.

**Your five problems:**

| Symptom | Cause | Fix |
|---|---|---|
| Overlay errors every frame | `run()` reused the overlay's live session and then called `session:Dispose()` on it. | It uses its own snapshot and closes only that. |
| MicroProfiler frozen until rejoin | `EnableCapture(false)` was never turned back on. | Capture is no longer paused. |
| Overlay's "last second" covering ~4 s | `SetFrameLimit(256)` was never undone; 256 frames at 60 FPS is about 4 s. | The frame limit is left alone (this also stops it wiping the counter history). |
| Physics longer than the frame, previous frame too short | A scope that started in one frame and ended in the next was counted entirely in the frame where it ended. Physics scopes nested inside other Physics scopes were also counted twice. | Each scope's time is split across the frames it overlaps. Physics counts only the outermost Physics scope. |
| GPU column negative or huge | GPU ticks were converted with `TickToMsCpu`, and the newest frame, still in progress, was included. | It now uses `TickToMsGpu` and reports only finished frames. If a platform has no GPU timing, `GpuMs` is 0 rather than negative. |

**Other LibMP misuse I fixed:**
- **Scope names:** `GetTimerDesc` returns a temporary view, and it was read after `FetchGroupDesc` had already invalidated it. It now uses `FetchTimerDesc`, and names are cached.
- **Heap counter:** `GetCounterSamples` returns an array that must be disposed, and it never was. It also called `FetchLastSample`, which isn't in the API. It now uses `FetchCounterSamples` and handles `FindCounterId` returning 0 (not found).
- **Top scopes:** they get the same split across frames. A timer that calls itself is counted once, not once per nested level.
- **Slow lookups:** `FindGroupId("Physics")` used to run on every scope exit. It now runs once, and timer groups are cached.
- **Missing thread:** if no thread matches `"Main"`, it raises a clear error instead of quietly filtering on thread 0.
- **Cleanup:** the iterator and session are now disposed even if an error happens partway through, and the session is checked with `IsValid()` before use.

**Two limits:**
- **Fewer frames while the overlay runs:** the report covers up to 120 frames but can only see what the MicroProfiler holds. With the overlay running that's 60 frames. The old code returned 60 here too, because raising the limit doesn't bring back older frames. Getting the full 120 would mean raising the limit, waiting about 2 seconds, then restoring it, and the overlay's numbers would be off during that wait. I can add that if you want it.
- **Assumptions to watch for:** the docs don't fully pin down two things, so the code assumes them:
  - the scope that just ended is at level `ThreadStackDepth()`, which is what LibMP's own example does;
  - each frame starts where the previous one ended, which the cross-frame split depends on.

  If Physics or top-scope times still look off, check these first.

Sources:
- [Roblox/libmp repository](https://github.com/Roblox/libmp)
- [LibMP API reference](https://raw.githubusercontent.com/Roblox/libmp/main/docs/api-reference.md)
- [LibMP SKILL.md usage notes](https://raw.githubusercontent.com/Roblox/libmp/main/docs/SKILL.md)
- [DevForum: Introducing LibMP](https://devforum.roblox.com/t/studio-beta-introducing-libmp-the-microprofiler-api/4703136)