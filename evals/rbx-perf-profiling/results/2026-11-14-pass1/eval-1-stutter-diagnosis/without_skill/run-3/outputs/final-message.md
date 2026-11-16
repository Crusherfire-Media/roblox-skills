I wrote the diagnosis to `docs/perf/stutter-diagnosis.md`. I didn't change any code. Every frame is listed with both the LibMP id and the absolute id, plus its time into the dump, so you can find it in both tools.

**What causes the stutter:** an autosave step called `BuildAutosave:Snapshot` runs about every 2.1 seconds, at frames 18236/604130, 18327/604221 and 18419/604313. On those frames it takes about 75 ms, and 54 ms of that is garbage collection. The Luau heap jumps from about 188 MB to about 236 MB on each spike, then drops back over 20–30 frames. The frame right after each spike (18237, 18328, 18420) runs about 28 ms while the GC finishes cleaning up. The number of parts never changes during the dump, so it looks like the autosave rebuilds a copy of the whole plot on a timer even when nothing changed.

**What makes the rest choppy:** normal frames take about 22 ms (roughly 45 FPS), and the main thread is the limit. It's busy 21.6 ms of every 22 ms frame. `BlockHighlight:Update` alone takes about 10 ms of that every frame, including 2.3 ms of garbage collection. Everything else on the main thread adds up to about 11.5 ms, so fixing BlockHighlight alone should get Sam to 60 FPS. I looked at the steady window 18330–18410.

**Alarming but not the problem:**
- **The 352 ms frame (18223/604117):** 329 ms of it is the MicroProfiler itself, right after Sam turned it on.
- **GPU frame span of 21.7 ms:** it only tracks the CPU frame timing. The GPU is actually busy just 6.4 ms per frame.
- **Three frames with bad GPU timestamps:** harmless, and the script skipped them.
- **Workers at 31 ms per frame:** that's four threads added together; each is about 8 ms.
- **The large GC numbers:** there's no leak, because the heap always returns to the same level.
- **Physics running two steps per frame:** normal.
- **6,231 parts:** steady for the whole dump.

**Two caveats:**
- The pasted output doesn't include a breakdown of frame 18236. I counted it as an autosave spike because of its length, the slow frame after it and the matching heap jump. The doc gives the `tree` command to confirm it.
- What the two scripts actually do (rebuilding everything each time, scanning the plot every frame) is my guess from the profiler labels and timings. I can't check it until the scripts are in the repo.

**What to look at next:** the doc covers this in detail.
- Confirm frame 18236 with `tree`.
- Change the autosave so it skips when nothing changed, saves only what changed, or spreads the work over several frames.
- Change BlockHighlight to do work only when the hovered block changes.
- Add `debug.profilebegin` labels inside both functions so the next capture shows which part is slow.
- Recapture after the fixes, waiting a second after turning on the MicroProfiler so its startup spike stays out of the window.

I couldn't run a shell command to list the repo; it needed approval and nobody was available to grant it. I used the file tools instead, and the only perf material in the repo is the analysis file.