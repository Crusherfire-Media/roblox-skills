I wrote the diagnosis to `docs/perf/stutter-diagnosis.md`. I didn't change any code. Frames are listed as LibMP id / MicroProfiler UI absolute id.

- **The stutter is `BuildAutosave:Snapshot`.** It runs every ~2.1 s, in frames 18236 / 604130, 18327 / 604221 and 18419 / 604313. Each run takes ~75 ms. About 54 ms of that is the Luau garbage collector, because the snapshot creates ~48 MB of short-lived data each time (the heap jumps from ~188 to ~236 MB). The frame after each spike also runs long, ~29 ms, while the leftover cleanup finishes.
- **The choppiness is the main thread.** It's busy for nearly the whole 22 ms frame, which is about 45 FPS. `BlockHighlight:Update` takes ~10 ms of that on every frame, and it allocates every frame (a ~2.3 ms GC step inside it). The render thread, worker threads and GPU all have spare time, so fixing `BlockHighlight` should get the laptop close to 60 FPS. That's my estimate, not something the capture proves.
- **Things that look alarming but aren't the problem:**
  - **The 352.6 ms frame (18223 / 604117).** Almost all of it is the MicroProfiler's own one-time startup stall, because Sam turned the profiler on right before building.
  - **GPU time matching CPU time.** The GPU is actually busy only ~6.4 ms per frame; its timing just stretches while it waits for the CPU. The GPU timestamps in this data are unreliable anyway.
  - **Worker time adding up to 31 ms per frame.** That's a total across four threads that run alongside the main thread, about 8 ms each.
  - **The 236 MB heap peaks.** They drop back within ~15 frames and the part count never changes, so it isn't a leak.

**Caveat:** Priya's output has no scope breakdown for 18236 / 604130. I'm calling it the same snapshot spike because its timing and heap jump match the other two. Confirming it with `tree.luau` is the first next step in the doc.

The other next steps are:
- Run `series.luau` over the whole capture to check the snapshot runs only on the spike frames.
- Add `debug.profilebegin` markers inside the two slow functions once the scripts are in the repo, so a new capture shows which parts cost the time.
- Recapture on Sam's laptop after each fix, waiting about half a second after turning the profiler on before building so the startup stall isn't in the data.