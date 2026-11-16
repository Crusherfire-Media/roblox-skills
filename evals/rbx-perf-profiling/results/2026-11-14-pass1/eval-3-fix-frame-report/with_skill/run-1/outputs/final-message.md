I've rewritten `src/ReplicatedStorage/Shared/Dev/FrameReport.luau`; `FpsOverlay.luau` is unchanged. **None of this has been run.** I haven't tested it in a playtest, and StyLua was blocked by the permission settings, so I wrapped the long lines by hand. Press "Frame report" once in a playtest to confirm the overlay keeps updating and Ctrl+F6 keeps moving.

**What caused each problem and what I changed**

| Problem | Cause | Fix |
|---|---|---|
| Overlay errors every frame | The report used the overlay's live session and then called `Dispose()` on it. | The report now copies the frames into its own snapshot (`CaptureToBufferSync`), opens a session from that copy, and disposes only that session. |
| MicroProfiler stays frozen | The report paused capture (`EnableCapture(false)`) and never turned it back on. | It no longer pauses capture at all. The snapshot holds the data still instead. |
| Overlay's "last second" became ~4 s | The report raised the frame limit to 256 and left it there. The overlay averages every frame the profiler holds, so 256 frames is about 4 s. | The limit goes back to `FpsOverlay.FrameLimit` (60) after the snapshot, even if the report errors. |
| Physics longer than the frame, and the frame before too short | A scope that crossed a frame boundary was counted entirely in the frame where it ended. Nested Physics scopes were also each added, so the same time counted more than once. | Each frame now gets only the part of a scope that falls inside it. Only the outermost Physics scope on the stack counts. One extra frame is read at the start so scopes already open are tracked correctly. |
| GPU column negative or too large | GPU ticks were converted with the CPU rate, and the frame's GPU start and end times are unreliable. | GPU time is now the sum of the top-level scopes on the GPU thread, converted with the GPU rate. |

**Other LibMP misuse I fixed**
- `scopeName` read a name from a temporary view after another call had already invalidated it, so names could be garbage. It now uses the `Fetch` versions.
- The Luau heap samples array was never disposed, so it leaked on every report. The report now reads the last sample with `FetchLastCounterSample` and checks that the counter exists.
- `FindGroupId("Physics")` is slow and ran once per scope. It now runs once per report, and the result per scope is cached.
- The newest frame is usually unfinished, so its frame time was wrong. The report now skips unfinished frames.
- It now errors clearly if there is no Main thread, and pressing the button again while a report is running gives an error instead of starting a second one.

**Changes to how the report behaves**
- **`run()` now waits about 2 seconds before returning.** While the overlay runs, the profiler only holds 60 frames, but the report covers 120. So the report raises the limit, waits for the frames, takes the snapshot and puts the limit back. During those 2 seconds the overlay's numbers cover a longer window, then return to normal. I kept the name `run()` because I couldn't find the debug panel code that calls it. If the panel can't wait, the other option is to report only the 60 frames already held.
- **Two small field changes:**
  - `GpuMs` is now `nil` on platforms with no GPU thread, instead of a made-up number.
  - Each row has a new `FrameAbsoluteId`, the frame number the MicroProfiler window shows. `FrameId` is now counted within the snapshot.
- **If the overlay isn't running**, the report turns the profiler on and leaves it on. There's no earlier setting to restore in that case. It also waits 24 more frames, because the profiler stalls once just after it starts.