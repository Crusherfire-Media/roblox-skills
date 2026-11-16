I wrote the diagnosis to `docs/perf/stutter-diagnosis.md` and didn't change any code. Frames are given as LibMP id / absolute id: the first works with our LibMP scripts, the second in the MicroProfiler UI.

**Stutter:** `BuildAutosave:Snapshot` runs in a single frame about every 2.1 s. Those frames take about 96 ms instead of the usual 22 ms.
- **Frames:** 18236/604130, 18327/604221 and 18419/604313. The frame after each one is about 28 ms (18237/604131, 18328/604222, 18420/604314).
- **Where the time goes:** about 21 ms is the snapshot's own work. The other 54 ms is garbage collection, because each snapshot allocates about 48 MB of short-lived data (the Luau heap goes from 188 to 236 MB). The ~28 ms frame after each spike is mostly garbage collection finishing up.
- **Not a leak:** the heap always drops back to about 188 MB, and the part count stays at 6231.
- **One gap:** 18236 is linked to the snapshot by its timing and heap jump only. The script output has no breakdown for that frame.

**Choppiness:** frames run at about 22 ms (about 45 FPS), and the main thread is busy for 21.6 ms of that. `BlockHighlight:Update` takes about 10 ms of it on every frame, including about 2.3 ms of garbage collection. The window I used is 18330..18410 (absolute 604224..604304). Without that cost, frames would get under the 16.7 ms needed for 60 FPS. At 45 FPS on a 60 Hz screen, frames are shown for uneven lengths of time, which looks choppy.

**Alarming but not the problem:**
- **The 352 ms frame (18223/604117):** that's the MicroProfiler's own one-time stall when it's first turned on (`MicroProfileFlip`), 12 frames after Sam enabled it. Players never see it.
- **GPU time roughly equal to CPU time:** the GPU timestamps in the frame data are unreliable. Three frames show the GPU finishing before it started. The GPU's real work is about 6.4 ms per frame.
- **Worker time of 31 ms per frame:** that's four parallel threads added together. Each is only about 8 ms busy.
- **Heap peaks at 236 MB:** these come from the autosave and drop back each time.

**Next steps** (detailed in the doc):
1. Get a breakdown for frame 18236 to confirm it's the snapshot.
2. When the scripts are in the repo, start with `BuildAutosave`: snapshot only changed blocks, reuse memory instead of allocating, or spread the work over several frames. Also check why it runs on the client.
3. Add profiler labels inside `BlockHighlight:Update` to see where its time goes. I suspect it loops over the whole plot every frame, but that's a guess until we see the script.
4. Capture the same building on a small plot to see whether both costs grow with block count.
5. For the next capture, let about a second pass after turning the profiler on before Sam starts building, so the startup stall stays out of the data.