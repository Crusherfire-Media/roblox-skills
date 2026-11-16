I've added `src/ReplicatedStorage/Shared/Dev/SpikeReport.luau`. StyLua, selene and luau-lsp all pass on it, but it hasn't been run against real data: I can't run Studio from here. Your first `run(2)` after a hitch is the real test.

**What `run(slot)` returns**
- `MedianMs`, `Percentile90Ms`, `SlowThresholdMs` (twice the median) and `FrameCount`.
- `SlowFrames`: each slow frame, in order, with:
  - `Name`, e.g. `"Frame 812 (absolute 40213)"`.
  - `FrameId`, for LibMP.
  - `FrameAbsoluteId`, for the MicroProfiler UI.
  - `FrameMs`.
  - `TopScopes`: the five scopes with the most self time. Each has `Name`, `Group`, `SelfMs`, and `NormalAverageMs`, which is that same scope's average over the frames that weren't slow.
- `NormalFrameCount` and `NormalTopScopes`: the top five scopes averaged over normal frames. "The same top five" could mean either the same scopes or a separate top five for normal frames, so I included both.

**How it works**
- **Self time:** each scope's own time in a frame, minus the time of the scopes nested inside it. It is added up across all CPU threads, and GPU threads are skipped.
- **Scopes that cross frames:** a scope that starts in one frame and ends in another is split, so each frame only counts the part that ran inside it.
- **Frames left out:** the first frame in the snapshot is only used to warm up the scope stacks, so it isn't reported. Incomplete and paused frames are also skipped.
- **Cleanup:** it releases everything it opens, even if it errors partway. It doesn't clear the slot, so you can run it again. It doesn't change any profiler settings either.
- **Seeing the result:** the command bar doesn't print return values. Wrap the call to see it, e.g. `print(require(game.ReplicatedStorage.Shared.Dev.SpikeReport).run(2))`.

**Two issues in `HitchSnapshot` that affect the report**
1. **It never sets a frame limit** (`SetFrameLimit` isn't called anywhere in the repo). The snapshot keeps whatever limit is in effect at the time, which may hold fewer frames than the 256 maximum.
2. **Turning the profiler on causes a one-off stall** of about 350 ms around 12 frames later, the first time in a session. `start()` calls `EnableProfiler(true)` and then watches for hitches right away. It can catch that stall and save it as the hitch: in the report it shows up as one very slow frame early in the snapshot. Skipping the first ~24 frames after `start()` would avoid it.

I haven't changed `HitchSnapshot`. Say if you want either fix.