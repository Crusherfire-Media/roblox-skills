I added `src/ReplicatedStorage/Shared/Dev/SpikeReport.luau`. It passes `luau-lsp analyze`, `selene` and `stylua --check`, but I couldn't run it in Studio from here, so it hasn't been tried on real profiler data yet. Your first `run(2)` after a hitch will be its first real test.

**What `run(slot)` returns**
- `MedianFrameMs`, `Percentile90FrameMs` and `SlowThresholdMs` (twice the median). These use CPU frame time, plus a count and range of the frames analyzed.
- `SlowFrames`: every frame over the threshold. Each has two IDs:
  - `FrameId` finds the frame through LibMP.
  - `FrameAbsoluteId` is the frame number shown in the MicroProfiler UI.

  Each slow frame also has `FrameMs` and `TopScopes`: the five scopes with the most self time in that frame, added up across all CPU threads.
- Each top scope has `Name`, `Group`, `SelfMs`, and `NormalAverageSelfMs`. That last one is the same scope's average self time over all frames that weren't slow, so the hitch and a normal frame sit side by side.

**How self time is measured**
- Self time is a scope's time inside the frame minus the time of the scopes directly nested inside it.
- A scope that crosses a frame boundary is split between the frames it overlaps, rather than all counted in the frame where it ends.
- GPU threads are left out.

**Frames left out**
- The first frame in the snapshot, and any frame right after a pause in capture. Scope nesting isn't known when those frames start, so parents would be blamed for their children's time.
- Frames the profiler marks as paused or incomplete.

**Profiler state**
- It only reads the slot. It doesn't change the profiler's state or frame limit, and it doesn't clear the slot, so you can run it again. Call `LibMP.Control:ResetSlot(2)` yourself when you're done with the data.
- Two things in `HitchSnapshot` affect what the report can see; I didn't change either:
  - It never calls `SetFrameLimit`, so the snapshot keeps whatever limit is in effect. Setting 256 there would give a better median.
  - It turns the profiler on right when it starts. The first capture after that has a one-time stall of about 350 ms around frame 12, which could set off a false hitch early in a playtest.

**Things to know**
- On a full 256-frame snapshot it steps through every CPU thread's log, so it may take a few seconds in the command bar.
- My combined check command was blocked by a permission prompt, so I reran each check on its own; all of them passed.