I rewrote `FrameReport.run()` in `src/ReplicatedStorage/Shared/Dev/FrameReport.luau`. StyLua, Selene and luau-lsp all pass with no errors. I haven't run it in a playtest, so the fixes still need checking by pressing the button in Studio. `FpsOverlay.luau` is unchanged and the report's fields are the same.

## What caused each symptom

| Symptom | Cause | Fix |
|---|---|---|
| Overlay errors every frame after a report | The report borrowed FpsOverlay's live session through `FpsOverlay.getSession()` and then called `session:Dispose()` on it. | The report now opens its own session from a snapshot (`CaptureToBufferSync` + `OpenFromBuffer`) and disposes only that one. It no longer requires FpsOverlay. |
| On-screen MicroProfiler frozen until rejoin | `EnableCapture(false)` was called and never undone. | The report no longer pauses capture. The snapshot keeps the data still while it's read. |
| Overlay's "last second" covering about 4 s | `SetFrameLimit(256)` stays in effect for everyone, so the overlay was averaging 256 frames instead of 60. | The report no longer changes the frame limit. |
| Physics time longer than the frame, and too little in the frame before | Each scope's whole duration went to the frame where it ended, even if it started in the previous frame. Physics scopes nested inside other Physics scopes were also counted twice. | A scope that crosses a frame boundary is now split, and each frame gets only the part inside it. This includes scopes still running when a frame ends. Physics time is the combined span of Physics scopes, so nested ones count once. |
| GPU time negative or far too large | GPU ticks were converted with `TickToMsCpu`, and a frame's own GPU start and end times are unreliable. | GPU time now comes from the scopes on the GPU thread, combined and converted with `TickToMsGpu`. It's 0 on platforms with no GPU thread. |

## Other LibMP mistakes fixed
- **Scope names could be garbage.** `scopeName` read a `GetTimerDesc` view after another call had already made it invalid. It now uses `FetchTimerDesc`.
- **The Luau heap reading was often missing.** Changing the frame limit wipes counter history. The counter array from `GetCounterSamples` was also never disposed, so it leaked. The report now calls `FetchLastCounterSample` and checks that the counter was found.
- **Wrong time for the newest frame.** That frame can still be recording, so the report now skips frames marked incomplete.
- **Wrong times at the start of the range.** Reading starts one frame early so the first reported frame begins with the right scopes open.
- **Slow lookup inside the loop.** `FindGroupId("Physics")` ran once per scope. It now runs once per report.
- **Time double-counted in the top five.** A scope nested inside another instance of itself was counted twice. Its time is now combined like Physics time.

## Decision for you
Because the report no longer touches the frame limit, it can only see the 60 frames the overlay keeps (about one second), not 120. The old code had the same limit in practice: it paused capture right after raising the limit, so no extra frames ever arrived, and the change only broke the overlay. Getting 120 frames would mean raising the limit to 256 and waiting about two seconds before taking the snapshot. That would make the report yield, and the overlay would average over a longer window while it waits. Then the limit would go back to `FpsOverlay.FrameLimit`. I can add that if you want it.

If you're open to adding a field, the MicroProfiler's frame number (`FrameAbsoluteId`) would make rows easier to find in the on-screen MicroProfiler. I left it out because you asked me not to change the fields.