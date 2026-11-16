I wrote the diagnosis to `docs/perf/stutter-diagnosis.md` and didn't change any code. Frames below are written as LibMP id / absolute id: use the first number with our LibMP scripts and the second in the MicroProfiler UI.

**The stutter: `BuildAutosave:Snapshot`.** It causes three spikes of about 96 ms, spaced about 2.1 s apart:
- **Spike frames:** 18236/604130, 18327/604221 and 18419/604313.
- **What's in them:** the Snapshot call takes about 75 ms, and 54 ms of that is Luau garbage collection (GC).
- **Why GC is so high:** each snapshot allocates about 48 MB of short-lived data. That's roughly 7.7 KB per block across the 6,231 parts. The heap jumps from about 188 MB to about 236 MB and drops back over the next 20–25 frames, so it's churn, not a leak.
- **Second, smaller hitch:** the frame after each spike runs about 28 ms instead of 22 ms. In 18328/604222, GC took 9.1 ms, so the collector is finishing the snapshot's leftover work.
- **Timing:** the ~2.1 s spacing fits a loop that waits 2 s after each snapshot finishes. That's a guess from the timing; check it once we have the script.

**The choppiness: the main thread can't keep up.** Normal frames take about 22 ms, which is roughly 45 FPS instead of 60:
- The main thread is busy 21.6 ms of each 22 ms frame. Every other thread, including the GPU at 6.4 ms of actual work, has plenty of spare time.
- `BlockHighlight:Update` takes about 10 ms of every frame (7.9 ms of its own work plus 2.3 ms of GC). That's nearly half the frame. Without it the main thread would be at about 11.5 ms, well under the 16.7 ms needed for 60 FPS.

**Alarming but not the problem:**
- **The longest frame, 18223/604117 (353 ms):** 329 ms of it is `MicroProfileFlip`, the one-time stall when the profiler is switched on. It's 12 frames in, right after Sam pressed Ctrl+F6, and players never see it.
- **GPU frame span of 21.7 ms:** it just tracks the CPU frame; actual GPU work is 6.4 ms. The three frames where the GPU end comes before its start are a known timestamp quirk.
- **Worker roots adding up to 31 ms:** that's the total across four threads. Each worker is busy about 8 of 22 ms.
- **Heap peaks, the constant part count and p99:** the heap peaks are only the autosave. The part count doesn't change, so no parts are leaking. p99 (96.40 ms) is just one of the three autosave spikes.

**One gap:** only 18419 and 18327 were broken down in the output. I matched 18236 to the same cause by its length, heap jump, follow-up frame and spacing. The doc's first next step is to run `tree.luau` on 18236–18237 to confirm it. The other next steps are:
- Read `BuildAutosave` and `BlockHighlight` when those scripts are available.
- Add `debug.profilebegin` labels inside both and recapture for a finer breakdown.
- Capture on a small plot to see whether both costs grow with block count.
- Recapture with the profiler already running before Sam starts building.
- Compare against a desktop.