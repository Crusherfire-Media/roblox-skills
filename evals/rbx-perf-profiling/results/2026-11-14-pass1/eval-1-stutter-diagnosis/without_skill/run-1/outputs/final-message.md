I wrote the diagnosis in `docs/perf/stutter-diagnosis.md` and didn't change any code. It's based only on Priya's LibMP output. I didn't run any LibMP scripts myself.

**Frame ids:** in this capture, the MicroProfiler UI's absolute frame id is the LibMP id plus 585894. Every frame in the doc is listed both ways.

**The stutter is the autosave.** `BuildAutosave:Snapshot` runs about every 2.1 s and turns one frame into about 96 ms.
- **Frames:** 18236/604130, 18327/604221 and 18419/604313. Each is followed by a slower frame of about 28 ms (18237, 18328, 18420) while garbage collection catches up.
- **Where the time goes:** about 54 ms of each spike is Luau garbage collection triggered by the snapshot's own memory use. The Luau heap jumps by about 48 MB on exactly those frames.
- **It runs on a timer:** the part count stayed at 6,231 for the whole capture, so the plot didn't change, yet the snapshot still ran three times.

**The choppiness is `BlockHighlight:Update`.**
- **Frame rate:** frames are a steady 22 ms (about 45 FPS), and the main thread is busy for about 98% of each one. The GPU, render thread and worker threads all have room to spare.
- **The cost:** `BlockHighlight:Update` takes about 10 ms of that in every frame, including 2.3 ms of garbage collection from allocating every frame.
- **Frames:** the clean stretch between stutters #2 and #3, 18330–18410 (604224–604304).

**Looks alarming but isn't the problem:**
- **The 352 ms worst frame** (18223/604117) is the MicroProfiler starting up right after Sam turned it on, not the game.
- **The GPU timing** of 21.7 ms makes the game look GPU-bound, but the GPU is only busy 6.4 ms per frame. The three frames where the GPU timing comes out negative show it isn't reliable here.
- **The 31 ms per frame for worker threads** is four threads added together. Each one is busy only about 8 ms.
- **The 54 ms of garbage collection** is caused by the snapshot's memory use, not an engine problem.
- **The 236 MB heap peaks** aren't a leak: memory drops back to about 188 MB within about 30 frames.

**Not yet confirmed:** stutter #1 (18236) has no breakdown in the output. I'm attributing it to the autosave because of its length, its timing and its heap jump. The doc lists the exact `lute` commands to confirm it and fill the other gaps.

The doc also says what to check in the autosave and highlight scripts once they're in the repo, and how to take the next capture. Turn the profiler on a moment before the part you want, so its startup spike isn't included, and record about 30 s.