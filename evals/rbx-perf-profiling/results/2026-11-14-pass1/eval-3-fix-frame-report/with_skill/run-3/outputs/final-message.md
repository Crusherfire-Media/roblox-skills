I rewrote `src/ReplicatedStorage/Shared/Dev/FrameReport.luau`. I haven't run it in Studio, so it still needs a playtest to confirm. `FpsOverlay.luau` is unchanged, and the report has the same fields with the same meanings.

**Your five problems:**

| Symptom | Cause | Fix |
|---|---|---|
| Overlay errors every frame | The report closed the overlay's live session (`session:Dispose()`), so every later read in the overlay failed. | The report now copies the profiler data into a buffer, works on its own session from that copy, and closes only that. It never touches the overlay's session. |
| On-screen MicroProfiler (Ctrl+F6) freezes | `EnableCapture(false)` paused recording and nothing turned it back on. | The report no longer pauses recording at all. The copy is what keeps the data still while it's read. |
| Overlay's "last second" covered ~4 s | `SetFrameLimit(256)` was never undone. The limit applies to everything that reads the profiler, and the overlay averages every frame it holds. | The report puts the overlay's limit (`FpsOverlay.FrameLimit`) back right after taking the copy. |
| Physics longer than the frame; previous frame too low | Each scope's whole duration went to the frame where it ended, even when it started in the frame before. Physics scopes nested inside other Physics scopes were also counted twice. | Each scope's time is now split across the frames it spans. Only the outermost Physics scope is counted. |
| GPU column negative or huge | It used the frame's own GPU start and end times, which can be wrong, and converted them with the CPU scale. | GPU time is now the total time of the top-level scopes on the GPU thread, converted with the GPU scale. |

**Other LibMP misuse I fixed:**
- **Wrong scope names:** `scopeName` read a timer's name after another LibMP call had already overwritten it, so names could be garbage. It now uses the `Fetch` versions, which return copies.
- **Memory leak:** the heap counter's sample list was never freed. It now reads only the last sample.
- **Slow lookup in the loop:** `FindGroupId("Physics")` ran once per scope inside the loop. It now runs once.
- **First frame:** one extra frame is read before the first reported frame so scopes that were already open are known. That frame isn't reported.
- **Last frame:** the newest frame is skipped if it's still being recorded, since its frame time would be wrong.
- **Missing data:** a missing main thread now gives a clear error, and a missing heap counter gives no heap value instead of a crash.
- **Cleanup on errors:** if anything fails partway, the report still frees what it opened and puts the frame limit back.

**Behavior changes:**
- **`run()` now waits about 2 seconds** (122 frames) before returning. With the overlay running, the profiler only keeps 60 frames, and raising the limit doesn't bring back frames that are already gone. So the report has to wait for 120 new frames to be recorded. The original code had the same limit and only ever got about 60 frames. I kept the name `run` so the button still works, but it should be called somewhere that's allowed to wait, such as a button click handler.
- **The overlay averages over a longer window during that wait**, because the frame limit is raised until the copy is taken. It goes back to 60 frames once the report finishes.
- **Without the overlay running**, nothing else in the game sets a frame limit and LibMP can't report the current one. So the limit stays at 256 after a report, as it did before.
- **Pressing the button again while a report is running** now gives an error instead of starting a second report.
- **If the platform has no GPU thread**, `GpuMs` is 0, because the field type is a plain number.
- **`FrameId` comes from the copy.** To find a frame in the MicroProfiler window you'd also need its absolute frame ID. I didn't add that because you asked to keep the fields the same, but it's a one-line addition (`frame.FrameAbsoluteId`) if you want it.