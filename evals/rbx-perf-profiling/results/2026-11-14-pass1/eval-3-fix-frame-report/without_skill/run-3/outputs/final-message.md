I rewrote `src/ReplicatedStorage/Shared/Dev/FrameReport.luau`. FpsOverlay is unchanged. I haven't run any of this: the LibMP module isn't in the repo and there's no Studio here, so please test it in a playtest. My first shell command was also blocked because this session can't approve permissions, so I worked only with the file read, search and write tools.

**What caused each problem and what I changed**

1. **The overlay errors every frame after a report.** The report reused the overlay's session (`FpsOverlay.getSession()`) and then called `session:Dispose()` on it, which killed the overlay's session. The report now always opens its own session and disposes only that one. It no longer requires FpsOverlay at all.
2. **The MicroProfiler stays frozen.** The report called `EnableCapture(false)` and never turned it back on. Capture is now always turned back on, even if the report fails partway (the reading code runs inside `pcall`).
3. **The overlay's "last second" covers about four seconds.** The report set the frame limit to 256, which is about 4.3 seconds at 60 FPS, and never set it back. The report no longer changes the frame limit. Raising the limit after capture is paused never added older frames anyway, so this costs nothing: the report covers up to 120 of the frames the MicroProfiler is holding, which is 60 while the overlay is running.
4. **Physics time longer than the frame, and too little in the frame before.**
   - Each scope's full time went to the frame where it ended, so a scope that crossed a frame boundary moved time from the earlier frame into the later one. The time is now split across frames by where the scope actually ran.
   - A Physics scope nested inside another Physics scope was counted twice. Now only the outermost one counts.
   - The top-scopes list had the same two problems, plus double counting when a timer calls itself. It gets the same fixes.
5. **GPU column nonsense.**
   - GPU ticks were converted with `TickToMsCpu`; they now use `TickToMsGpu`.
   - Frames still in progress (`IsIncomplete`) are now skipped, the same way the overlay already skips them. Their end times aren't written yet, and GPU work lags behind the CPU, which is where the negative numbers came from.
   - Any GPU time that still comes out negative is set to 0.

**Other wrong LibMP use I fixed**
- `scopeName` called `GetTimerDesc` and read `timer:GroupId()` / `timer:TimerName()` as methods. It now uses `FetchTimerDesc` and reads fields, like the rest of the code does.
- `FindGroupId("Physics")` was being called for every log step. It now runs once, and each timer's group is cached.
- The iterator is now always disposed. There are also nil checks for the Main thread and the Luau heap counter.

**Check these in Studio.** Without the LibMP docs, I guessed three things from the naming the existing code uses:
- the global description has a `TickToMsGpu` field;
- the timer description has `TimerName` and `GroupId` fields;
- the stack element returned by `GetCurrentThreadStackElement` has a `TimerId()` method. The nesting check relies on this one.

If any of these names is wrong, the report will fail with a clear error. Capture will still come back on and the overlay will keep working.

**One behaviour change:** after a report, capture is always switched back on, even if someone had paused it by hand beforehand. That's because I didn't know of a LibMP call that reads the current capture state. If there is one, the report can restore the earlier state instead.