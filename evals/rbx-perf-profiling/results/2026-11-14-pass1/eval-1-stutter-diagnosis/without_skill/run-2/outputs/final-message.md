I've written the diagnosis to `docs/perf/stutter-diagnosis.md` and didn't touch any code. It's based only on Priya's pasted output: the `.gprx` dump and the LibMP scripts aren't in this repo, so I couldn't re-run anything.

**The stutter is the autosave.** The ~95 ms hitches are frames 18236, 18327 and 18419 (absolute 604130, 604221, 604313). They come every ~2.1 s, at 0.89, 2.98 and 5.09 s into the dump.
- In 18419, `BuildAutosave:Snapshot` takes 75 ms: 21 ms of its own work and **54 ms of Luau garbage collection** caused by what it allocates.
- The Luau heap jumps ~48 MB at each hitch, then drops back over about 20 frames.
- The frame right after each hitch (18237, 18328, 18420) runs 28–29 ms while the garbage collector catches up. 18328 shows 9 ms of GC instead of the usual ~2 ms.
- Only 18419 was broken down in the output. I've linked 18236 to the autosave by its timing and identical heap jump, and listed the command to confirm it.
- The part count is 6231 for the whole capture, so the autosave seems to run on a timer even when nothing changed. That's an inference.

**The choppiness is `BlockHighlight:Update`.** Frames in the steady stretch (18330–18410) average 22 ms, about 45 FPS instead of 60.
- The main thread is busy 21.6 ms of that 22 ms, so it's the bottleneck.
- `BlockHighlight:Update` alone takes ~10 ms every frame, including 2.3 ms of garbage collection.
- Without it, the frame would be ~11.5 ms, well under the 16.7 ms needed for 60 FPS.

**Things that look bad but aren't the problem:**
- **Frame 18223 / absolute 604117 (352 ms):** this is the profiler's own overhead right after Sam switched it on. Game work in that frame is normal.
- **GPU frame span of 21.7 ms:** that's just the time between GPU frame markers. The GPU is actually busy only 6.4 ms per frame, so lowering graphics settings won't help.
- **Workers at 31.4 ms per frame:** that's four threads added together. Each is only ~8 ms busy and runs alongside the main thread.

To convert between the two frame numbers, absolute = LibMP id + 585894. The doc has a table of both IDs plus the time into the dump for every frame mentioned. It also lists next steps:
- what to check in the two scripts once they're in the repo
- exact LibMP commands to confirm the unverified points
- where to look in the MicroProfiler UI
- profiler labels to add before the next capture
- a small-plot capture to test whether the highlight cost grows with block count

My first attempt to read the analysis file through the shell was blocked by the permission check. I read it with the file viewer instead, so nothing was lost.